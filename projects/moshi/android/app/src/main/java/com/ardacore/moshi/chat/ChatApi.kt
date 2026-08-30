package com.ardacore.moshi.chat

import com.ardacore.moshi.BuildConfig
import com.ardacore.moshi.auth.ApiException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.util.concurrent.TimeUnit

class ChatApi(
    private val baseUrl: String = BuildConfig.API_BASE_URL.trimEnd('/'),
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build(),
) {
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    suspend fun searchUsers(accessToken: String, query: String): List<ChatUser> = withContext(Dispatchers.IO) {
        val q = URLEncoder.encode(query, StandardCharsets.UTF_8.toString())
        parseUsers(request("GET", "/v1/users/search?q=$q", accessToken = accessToken))
    }

    suspend fun createDirect(accessToken: String, username: String): ChatConversation = withContext(Dispatchers.IO) {
        parseConversation(JSONObject(request("POST", "/v1/conversations/direct", accessToken, JSONObject().put("username", username))))
    }

    suspend fun createGroup(accessToken: String, title: String, usernames: List<String>): ChatConversation = withContext(Dispatchers.IO) {
        val members = JSONArray()
        usernames.forEach { members.put(it.trim().removePrefix("@")) }
        val payload = JSONObject()
            .put("title", title.trim())
            .put("usernames", members)
        parseConversation(JSONObject(request("POST", "/v1/groups", accessToken, payload)))
    }

    suspend fun groupMembers(accessToken: String, groupId: String): List<GroupMember> = withContext(Dispatchers.IO) {
        val array = JSONArray(request("GET", "/v1/groups/$groupId/members", accessToken = accessToken))
        List(array.length()) { index -> parseGroupMember(array.getJSONObject(index)) }
    }

    suspend fun addGroupMember(accessToken: String, groupId: String, username: String): GroupMember = withContext(Dispatchers.IO) {
        parseGroupMember(
            JSONObject(
                request(
                    "POST",
                    "/v1/groups/$groupId/members",
                    accessToken,
                    JSONObject().put("username", username.trim().removePrefix("@")),
                )
            )
        )
    }

    suspend fun updateGroupRole(accessToken: String, groupId: String, memberId: String, role: String): GroupMember = withContext(Dispatchers.IO) {
        parseGroupMember(
            JSONObject(
                request(
                    "PATCH",
                    "/v1/groups/$groupId/members/$memberId/role",
                    accessToken,
                    JSONObject().put("role", role),
                )
            )
        )
    }

    suspend fun removeGroupMember(accessToken: String, groupId: String, memberId: String) = withContext(Dispatchers.IO) {
        request("DELETE", "/v1/groups/$groupId/members/$memberId", accessToken)
        Unit
    }

    suspend fun conversations(accessToken: String): List<ChatConversation> = withContext(Dispatchers.IO) {
        parseConversations(request("GET", "/v1/conversations", accessToken = accessToken))
    }

    suspend fun messages(accessToken: String, conversationId: String): List<ChatMessage> = withContext(Dispatchers.IO) {
        parseMessages(request("GET", "/v1/conversations/$conversationId/messages", accessToken = accessToken))
    }

    suspend fun initUpload(
        accessToken: String,
        kind: String,
        fileName: String,
        contentType: String,
        sizeBytes: Long,
    ): UploadTicket = withContext(Dispatchers.IO) {
        val json = JSONObject(
            request(
                method = "POST",
                path = "/v1/uploads",
                accessToken = accessToken,
                body = JSONObject()
                    .put("kind", kind)
                    .put("file_name", fileName)
                    .put("content_type", contentType)
                    .put("size_bytes", sizeBytes),
            )
        )
        UploadTicket(
            id = json.getString("id"),
            kind = json.getString("kind"),
            fileName = json.getString("file_name"),
            contentType = json.getString("content_type"),
            sizeBytes = json.getLong("size_bytes"),
            status = json.getString("status"),
            uploadPath = json.getString("upload_path"),
        )
    }

    suspend fun uploadContent(
        accessToken: String,
        ticket: UploadTicket,
        body: RequestBody,
    ): ChatAttachment = withContext(Dispatchers.IO) {
        parseAttachment(
            JSONObject(
                rawRequest(
                    method = "PUT",
                    path = ticket.uploadPath,
                    accessToken = accessToken,
                    body = body,
                )
            )
        )
    }

    suspend fun downloadAttachment(accessToken: String, attachment: ChatAttachment): ByteArray =
        downloadBytes(accessToken, attachment.downloadPath, attachment.contentType)

    suspend fun downloadBytes(accessToken: String, path: String, accept: String = "*/*"): ByteArray = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url(absoluteUrl(path))
            .header("Accept", accept)
            .header("Authorization", "Bearer $accessToken")
            .get()
            .build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                val text = response.body?.string().orEmpty()
                val detail = runCatching { JSONObject(text).optString("detail") }.getOrNull()
                throw ApiException(detail?.takeIf { it.isNotBlank() } ?: "Download failed (${response.code})", response.code)
            }
            response.body?.bytes()?.takeIf { it.isNotEmpty() } ?: error("Download response is empty")
        }
    }

    suspend fun sendMessage(
        accessToken: String,
        conversationId: String,
        clientMessageId: String,
        body: String,
        replyToId: String? = null,
        attachmentIds: List<String> = emptyList(),
    ): ChatMessage = withContext(Dispatchers.IO) {
        val payload = JSONObject().put("client_message_id", clientMessageId).put("body", body)
        if (replyToId != null) payload.put("reply_to_id", replyToId)
        if (attachmentIds.isNotEmpty()) payload.put("attachment_ids", JSONArray(attachmentIds))
        parseMessage(JSONObject(request("POST", "/v1/conversations/$conversationId/messages", accessToken, payload)))
    }

    suspend fun shareCatalogCard(
        accessToken: String,
        conversationId: String,
        clientMessageId: String,
        catalogItemId: String,
        body: String = "",
    ): ChatMessage = withContext(Dispatchers.IO) {
        val payload = JSONObject()
            .put("client_message_id", clientMessageId)
            .put("catalog_item_id", catalogItemId)
            .put("body", body)
        parseMessage(JSONObject(request("POST", "/v1/conversations/$conversationId/catalog-cards", accessToken, payload)))
    }

    suspend fun createOrderDraft(
        accessToken: String,
        conversationId: String,
        catalogMessageId: String,
        clientMessageId: String,
        quantity: Int = 1,
        note: String = "",
    ): OrderDraftResult = withContext(Dispatchers.IO) {
        val payload = JSONObject()
            .put("client_message_id", clientMessageId)
            .put("quantity", quantity)
            .put("note", note)
        val json = JSONObject(
            request(
                "POST",
                "/v1/conversations/$conversationId/catalog-cards/$catalogMessageId/order",
                accessToken,
                payload,
            )
        )
        val order = json.getJSONObject("order")
        OrderDraftResult(
            orderId = order.getString("id"),
            status = order.optString("status", "draft"),
            message = parseMessage(json.getJSONObject("message")),
        )
    }

    suspend fun editMessage(accessToken: String, conversationId: String, messageId: String, body: String): ChatMessage = withContext(Dispatchers.IO) {
        parseMessage(JSONObject(request("PATCH", "/v1/conversations/$conversationId/messages/$messageId", accessToken, JSONObject().put("body", body))))
    }

    suspend fun deleteMessage(accessToken: String, conversationId: String, messageId: String): ChatMessage = withContext(Dispatchers.IO) {
        parseMessage(JSONObject(request("DELETE", "/v1/conversations/$conversationId/messages/$messageId", accessToken)))
    }

    suspend fun toggleReaction(accessToken: String, conversationId: String, messageId: String, emoji: String): ChatMessage = withContext(Dispatchers.IO) {
        parseMessage(JSONObject(request("POST", "/v1/conversations/$conversationId/messages/$messageId/reactions", accessToken, JSONObject().put("emoji", emoji))))
    }

    suspend fun markRead(accessToken: String, conversationId: String, messageId: String) = withContext(Dispatchers.IO) {
        request("POST", "/v1/conversations/$conversationId/read", accessToken, JSONObject().put("message_id", messageId))
        Unit
    }

    fun absoluteUrl(path: String): String = if (path.startsWith("http://") || path.startsWith("https://")) path else "$baseUrl$path"

    fun openRealtime(
        accessToken: String,
        onOpen: () -> Unit,
        onEvent: (JSONObject) -> Unit,
        onFailure: (Throwable) -> Unit,
        onClosed: () -> Unit,
    ): WebSocket {
        val wsBase = when {
            baseUrl.startsWith("https://") -> "wss://${baseUrl.removePrefix("https://")}"
            baseUrl.startsWith("http://") -> "ws://${baseUrl.removePrefix("http://")}"
            else -> baseUrl
        }
        val token = URLEncoder.encode(accessToken, StandardCharsets.UTF_8.toString())
        val request = Request.Builder().url("$wsBase/v1/ws?token=$token").build()
        return client.newWebSocket(
            request,
            object : WebSocketListener() {
                override fun onOpen(webSocket: WebSocket, response: Response) = onOpen()
                override fun onMessage(webSocket: WebSocket, text: String) {
                    runCatching { JSONObject(text) }.onSuccess(onEvent)
                }
                override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) = onFailure(t)
                override fun onClosed(webSocket: WebSocket, code: Int, reason: String) = onClosed()
            }
        )
    }

    private fun request(
        method: String,
        path: String,
        accessToken: String? = null,
        body: JSONObject? = null,
    ): String {
        val requestBody = body?.toString()?.toRequestBody(jsonMediaType)
        val builder = Request.Builder().url(absoluteUrl(path)).header("Accept", "application/json")
        if (accessToken != null) builder.header("Authorization", "Bearer $accessToken")
        when (method) {
            "GET" -> builder.get()
            "POST" -> builder.post(requestBody ?: ByteArray(0).toRequestBody(null))
            "PATCH" -> builder.patch(requestBody ?: ByteArray(0).toRequestBody(null))
            "DELETE" -> builder.delete()
            else -> error("Unsupported method $method")
        }
        return execute(builder.build())
    }

    private fun rawRequest(method: String, path: String, accessToken: String, body: RequestBody): String {
        val builder = Request.Builder()
            .url(absoluteUrl(path))
            .header("Accept", "application/json")
            .header("Authorization", "Bearer $accessToken")
        when (method) {
            "PUT" -> builder.put(body)
            else -> error("Unsupported raw method $method")
        }
        return execute(builder.build())
    }

    private fun execute(request: Request): String {
        client.newCall(request).execute().use { response ->
            val text = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                val detail = runCatching { JSONObject(text).optString("detail") }.getOrNull()
                throw ApiException(detail?.takeIf { it.isNotBlank() } ?: "MOSHI API error (${response.code})", response.code)
            }
            return text
        }
    }

    private fun parseUsers(text: String): List<ChatUser> {
        val array = JSONArray(text)
        return List(array.length()) { index -> parseUser(array.getJSONObject(index)) }
    }

    private fun parseConversations(text: String): List<ChatConversation> {
        val array = JSONArray(text)
        return List(array.length()) { index -> parseConversation(array.getJSONObject(index)) }
    }

    private fun parseMessages(text: String): List<ChatMessage> {
        val array = JSONArray(text)
        return List(array.length()) { index -> parseMessage(array.getJSONObject(index)) }
    }

    private fun parseConversation(json: JSONObject): ChatConversation {
        val groupJson = json.optJSONObject("group")
        return ChatConversation(
            id = json.getString("id"),
            kind = json.getString("kind"),
            peer = json.optJSONObject("peer")?.let(::parseUser),
            group = groupJson?.let {
                GroupPreview(
                    title = it.getString("title"),
                    description = it.optString("description"),
                    myRole = it.optString("my_role", "member"),
                    memberCount = it.optInt("member_count", 1),
                )
            },
            latestMessage = json.optJSONObject("latest_message")?.let(::parseMessage),
            unreadCount = json.optInt("unread_count", 0),
        )
    }

    private fun parseGroupMember(json: JSONObject): GroupMember = GroupMember(
        user = parseUser(json.getJSONObject("user")),
        role = json.optString("role", "member"),
        joinedAt = json.optString("joined_at"),
    )

    fun parseMessage(json: JSONObject): ChatMessage {
        val replyJson = json.optJSONObject("reply_to")
        val reactionsJson = json.optJSONArray("reactions") ?: JSONArray()
        val attachmentsJson = json.optJSONArray("attachments") ?: JSONArray()
        val catalogJson = json.optJSONObject("catalog_card")
        val orderJson = json.optJSONObject("order_card")
        return ChatMessage(
            id = json.getString("id"),
            conversationId = json.getString("conversation_id"),
            senderId = json.getString("sender_id"),
            clientMessageId = json.getString("client_message_id"),
            body = json.optString("body"),
            createdAt = json.getString("created_at"),
            editedAt = json.optString("edited_at").takeIf { it.isNotBlank() && it != "null" },
            deletedAt = json.optString("deleted_at").takeIf { it.isNotBlank() && it != "null" },
            isDeleted = json.optBoolean("is_deleted", false),
            state = json.optString("state", "sent"),
            replyTo = replyJson?.let {
                ReplyPreview(it.getString("id"), it.getString("sender_id"), it.optString("body"), it.optBoolean("is_deleted", false))
            },
            reactions = List(reactionsJson.length()) { index ->
                val item = reactionsJson.getJSONObject(index)
                ReactionSummary(item.getString("emoji"), item.getInt("count"), item.optBoolean("reacted_by_me", false))
            },
            attachments = List(attachmentsJson.length()) { index -> parseAttachment(attachmentsJson.getJSONObject(index)) },
            catalogCard = catalogJson?.let(::parseCatalogCard),
            orderCard = orderJson?.let(::parseOrderCard),
        )
    }

    private fun parseCatalogCard(json: JSONObject) = CatalogMessageCard(
        catalogItemId = json.optString("catalog_item_id").takeIf { it.isNotBlank() && it != "null" },
        sellerId = json.getString("seller_id"),
        businessName = json.getString("business_name"),
        kind = json.getString("kind"),
        title = json.getString("title"),
        description = json.optString("description"),
        priceAmount = if (json.isNull("price_amount")) null else json.getLong("price_amount"),
        currency = json.optString("currency", "IDR"),
        availability = json.optString("availability", "available"),
        stockQty = if (json.isNull("stock_qty")) null else json.getInt("stock_qty"),
        imagePath = json.optString("image_path").takeIf { it.isNotBlank() && it != "null" },
    )

    private fun parseOrderCard(json: JSONObject) = OrderMessageCard(
        orderId = json.getString("order_id"),
        buyerId = json.getString("buyer_id"),
        sellerId = json.getString("seller_id"),
        status = json.optString("status", "draft"),
        itemTitle = json.getString("item_title"),
        quantity = json.optInt("quantity", 1),
        totalAmount = if (json.isNull("total_amount")) null else json.getLong("total_amount"),
        currency = json.optString("currency", "IDR"),
    )

    private fun parseAttachment(json: JSONObject): ChatAttachment = ChatAttachment(
        id = json.getString("id"),
        kind = json.getString("kind"),
        fileName = json.getString("file_name"),
        contentType = json.getString("content_type"),
        sizeBytes = json.getLong("size_bytes"),
        status = json.getString("status"),
        downloadPath = json.optString("download_path"),
    )

    private fun parseUser(json: JSONObject): ChatUser = ChatUser(
        id = json.getString("id"),
        username = json.getString("username"),
        displayName = json.getString("display_name"),
        businessMode = json.optBoolean("business_mode", false),
    )
}
