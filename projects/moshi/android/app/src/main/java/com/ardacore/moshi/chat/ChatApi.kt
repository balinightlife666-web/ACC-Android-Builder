package com.ardacore.moshi.chat

import com.ardacore.moshi.BuildConfig
import com.ardacore.moshi.auth.ApiException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
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
        .readTimeout(20, TimeUnit.SECONDS)
        .build(),
) {
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    suspend fun searchUsers(accessToken: String, query: String): List<ChatUser> = withContext(Dispatchers.IO) {
        val q = URLEncoder.encode(query, StandardCharsets.UTF_8.toString())
        parseUsers(request("GET", "/v1/users/search?q=$q", accessToken = accessToken))
    }

    suspend fun createDirect(accessToken: String, username: String): ChatConversation = withContext(Dispatchers.IO) {
        parseConversation(
            JSONObject(
                request(
                    method = "POST",
                    path = "/v1/conversations/direct",
                    accessToken = accessToken,
                    body = JSONObject().put("username", username),
                )
            )
        )
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
        bytes: ByteArray,
    ): ChatAttachment = withContext(Dispatchers.IO) {
        parseAttachment(
            JSONObject(
                rawRequest(
                    method = "PUT",
                    path = ticket.uploadPath,
                    accessToken = accessToken,
                    contentType = ticket.contentType,
                    bytes = bytes,
                )
            )
        )
    }

    suspend fun sendMessage(
        accessToken: String,
        conversationId: String,
        clientMessageId: String,
        body: String,
        replyToId: String? = null,
        attachmentIds: List<String> = emptyList(),
    ): ChatMessage = withContext(Dispatchers.IO) {
        val payload = JSONObject()
            .put("client_message_id", clientMessageId)
            .put("body", body)
        if (replyToId != null) payload.put("reply_to_id", replyToId)
        if (attachmentIds.isNotEmpty()) payload.put("attachment_ids", JSONArray(attachmentIds))
        parseMessage(
            JSONObject(
                request(
                    method = "POST",
                    path = "/v1/conversations/$conversationId/messages",
                    accessToken = accessToken,
                    body = payload,
                )
            )
        )
    }

    suspend fun editMessage(accessToken: String, conversationId: String, messageId: String, body: String): ChatMessage = withContext(Dispatchers.IO) {
        parseMessage(
            JSONObject(
                request(
                    method = "PATCH",
                    path = "/v1/conversations/$conversationId/messages/$messageId",
                    accessToken = accessToken,
                    body = JSONObject().put("body", body),
                )
            )
        )
    }

    suspend fun deleteMessage(accessToken: String, conversationId: String, messageId: String): ChatMessage = withContext(Dispatchers.IO) {
        parseMessage(
            JSONObject(
                request(
                    method = "DELETE",
                    path = "/v1/conversations/$conversationId/messages/$messageId",
                    accessToken = accessToken,
                )
            )
        )
    }

    suspend fun toggleReaction(accessToken: String, conversationId: String, messageId: String, emoji: String): ChatMessage = withContext(Dispatchers.IO) {
        parseMessage(
            JSONObject(
                request(
                    method = "POST",
                    path = "/v1/conversations/$conversationId/messages/$messageId/reactions",
                    accessToken = accessToken,
                    body = JSONObject().put("emoji", emoji),
                )
            )
        )
    }

    suspend fun markRead(accessToken: String, conversationId: String, messageId: String) = withContext(Dispatchers.IO) {
        request(
            method = "POST",
            path = "/v1/conversations/$conversationId/read",
            accessToken = accessToken,
            body = JSONObject().put("message_id", messageId),
        )
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
                override fun onOpen(webSocket: WebSocket, response: Response) {
                    onOpen()
                }

                override fun onMessage(webSocket: WebSocket, text: String) {
                    runCatching { JSONObject(text) }.onSuccess(onEvent)
                }

                override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                    onFailure(t)
                }

                override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                    onClosed()
                }
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
        val builder = Request.Builder()
            .url("$baseUrl$path")
            .header("Accept", "application/json")
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

    private fun rawRequest(
        method: String,
        path: String,
        accessToken: String,
        contentType: String,
        bytes: ByteArray,
    ): String {
        val body = bytes.toRequestBody(contentType.toMediaType())
        val builder = Request.Builder()
            .url("$baseUrl$path")
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

    private fun parseConversation(json: JSONObject): ChatConversation = ChatConversation(
        id = json.getString("id"),
        kind = json.getString("kind"),
        peer = json.optJSONObject("peer")?.let(::parseUser),
        latestMessage = json.optJSONObject("latest_message")?.let(::parseMessage),
        unreadCount = json.optInt("unread_count", 0),
    )

    fun parseMessage(json: JSONObject): ChatMessage {
        val replyJson = json.optJSONObject("reply_to")
        val reactionsJson = json.optJSONArray("reactions") ?: JSONArray()
        val attachmentsJson = json.optJSONArray("attachments") ?: JSONArray()
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
                ReplyPreview(
                    id = it.getString("id"),
                    senderId = it.getString("sender_id"),
                    body = it.optString("body"),
                    isDeleted = it.optBoolean("is_deleted", false),
                )
            },
            reactions = List(reactionsJson.length()) { index ->
                val item = reactionsJson.getJSONObject(index)
                ReactionSummary(
                    emoji = item.getString("emoji"),
                    count = item.getInt("count"),
                    reactedByMe = item.optBoolean("reacted_by_me", false),
                )
            },
            attachments = List(attachmentsJson.length()) { index -> parseAttachment(attachmentsJson.getJSONObject(index)) },
        )
    }

    private fun parseAttachment(json: JSONObject): ChatAttachment = ChatAttachment(
        id = json.getString("id"),
        kind = json.getString("kind"),
        fileName = json.getString("file_name"),
        contentType = json.getString("content_type"),
        sizeBytes = json.getLong("size_bytes"),
        status = json.getString("status"),
        downloadPath = json.getString("download_path"),
    )

    private fun parseUser(json: JSONObject): ChatUser = ChatUser(
        id = json.getString("id"),
        username = json.getString("username"),
        displayName = json.getString("display_name"),
        businessMode = json.optBoolean("business_mode", false),
    )
}
