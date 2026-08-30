package com.ardacore.moshi.chat.local

import android.content.Context
import com.ardacore.moshi.chat.ChatAttachment
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.ChatMessage
import com.ardacore.moshi.chat.ChatUser
import com.ardacore.moshi.chat.GroupPreview
import com.ardacore.moshi.chat.ReactionSummary
import com.ardacore.moshi.chat.ReplyPreview
import okhttp3.RequestBody
import org.json.JSONArray
import org.json.JSONObject

private const val MAX_ATTACHMENT_BYTES = 20 * 1024 * 1024

class ChatLocalStore(context: Context) {
    private val appContext = context.applicationContext
    private val dao = MoshiChatDatabase.get(appContext).chatDao()

    suspend fun conversations(): List<ChatConversation> = dao.conversations().mapNotNull { entity ->
        runCatching { parseConversation(JSONObject(entity.payloadJson)) }.getOrNull()
    }

    suspend fun cacheConversations(items: List<ChatConversation>) {
        dao.clearConversations()
        if (items.isNotEmpty()) {
            dao.upsertConversations(
                items.mapIndexed { index, item ->
                    CachedConversationEntity(
                        id = item.id,
                        payloadJson = conversationToJson(item).toString(),
                        sortOrder = index,
                    )
                }
            )
        }
    }

    suspend fun messages(conversationId: String): List<ChatMessage> = dao.messages(conversationId).mapNotNull { entity ->
        runCatching { parseMessage(JSONObject(entity.payloadJson)) }.getOrNull()
    }

    suspend fun cacheMessages(items: List<ChatMessage>) {
        if (items.isNotEmpty()) dao.upsertMessages(items.map(::messageEntity))
    }

    suspend fun cacheMessage(item: ChatMessage) {
        dao.deleteMessageByClientId(item.clientMessageId)
        dao.upsertMessage(messageEntity(item))
    }

    suspend fun enqueue(
        conversationId: String,
        clientMessageId: String,
        body: String,
        replyToId: String?,
        localMessage: ChatMessage,
    ) {
        dao.enqueue(
            OutboxMessageEntity(
                clientMessageId = clientMessageId,
                conversationId = conversationId,
                body = body,
                replyToId = replyToId,
                createdAtEpochMs = System.currentTimeMillis(),
            )
        )
        dao.upsertMessage(messageEntity(localMessage))
    }

    suspend fun enqueueAttachment(
        conversationId: String,
        clientMessageId: String,
        body: String,
        replyToId: String?,
        attachmentUri: String,
        attachmentKind: String,
        attachmentFileName: String,
        attachmentContentType: String,
        attachmentSizeBytes: Long,
        localMessage: ChatMessage,
    ) {
        dao.enqueue(
            OutboxMessageEntity(
                clientMessageId = clientMessageId,
                conversationId = conversationId,
                body = body,
                replyToId = replyToId,
                createdAtEpochMs = System.currentTimeMillis(),
                attachmentUri = attachmentUri,
                attachmentKind = attachmentKind,
                attachmentFileName = attachmentFileName,
                attachmentContentType = attachmentContentType,
                attachmentSizeBytes = attachmentSizeBytes,
            )
        )
        dao.upsertMessage(messageEntity(localMessage))
    }

    suspend fun pending(): List<OutboxMessageEntity> = dao.outbox()

    suspend fun acknowledge(clientMessageId: String, serverMessage: ChatMessage) {
        dao.deleteMessageByClientId(clientMessageId)
        dao.upsertMessage(messageEntity(serverMessage))
        dao.removeOutbox(clientMessageId)
    }

    suspend fun markAttempt(clientMessageId: String, error: String) {
        dao.markAttempt(clientMessageId, error.take(500))
    }

    suspend fun markAttachmentUploaded(clientMessageId: String, attachmentId: String) {
        dao.markAttachmentUploaded(clientMessageId, attachmentId)
    }

    fun pendingAttachmentBody(item: OutboxMessageEntity): RequestBody {
        val uriText = item.attachmentUri ?: error("Attachment URI is missing")
        val contentType = item.attachmentContentType ?: error("Attachment type is missing")
        val expectedSize = item.attachmentSizeBytes ?: error("Attachment size is missing")
        if (expectedSize <= 0 || expectedSize > MAX_ATTACHMENT_BYTES) error("Attachment size is invalid")
        return ContentUriRequestBody(appContext, uriText, contentType, expectedSize)
    }

    fun readPendingAttachment(item: OutboxMessageEntity): RequestBody = pendingAttachmentBody(item)

    private fun messageEntity(item: ChatMessage) = CachedMessageEntity(
        id = item.id,
        conversationId = item.conversationId,
        clientMessageId = item.clientMessageId,
        createdAt = item.createdAt,
        payloadJson = messageToJson(item).toString(),
    )

    private fun conversationToJson(item: ChatConversation): JSONObject = JSONObject()
        .put("id", item.id)
        .put("kind", item.kind)
        .put("peer", item.peer?.let(::userToJson) ?: JSONObject.NULL)
        .put("group", item.group?.let(::groupToJson) ?: JSONObject.NULL)
        .put("latest_message", item.latestMessage?.let(::messageToJson) ?: JSONObject.NULL)
        .put("unread_count", item.unreadCount)

    private fun groupToJson(item: GroupPreview): JSONObject = JSONObject()
        .put("title", item.title)
        .put("description", item.description)
        .put("my_role", item.myRole)
        .put("member_count", item.memberCount)

    private fun messageToJson(item: ChatMessage): JSONObject {
        val reactions = JSONArray()
        item.reactions.forEach { reaction ->
            reactions.put(
                JSONObject()
                    .put("emoji", reaction.emoji)
                    .put("count", reaction.count)
                    .put("reacted_by_me", reaction.reactedByMe)
            )
        }
        val attachments = JSONArray()
        item.attachments.forEach { attachment ->
            attachments.put(
                JSONObject()
                    .put("id", attachment.id)
                    .put("kind", attachment.kind)
                    .put("file_name", attachment.fileName)
                    .put("content_type", attachment.contentType)
                    .put("size_bytes", attachment.sizeBytes)
                    .put("status", attachment.status)
                    .put("download_path", attachment.downloadPath)
            )
        }
        return JSONObject()
            .put("id", item.id)
            .put("conversation_id", item.conversationId)
            .put("sender_id", item.senderId)
            .put("client_message_id", item.clientMessageId)
            .put("body", item.body)
            .put("created_at", item.createdAt)
            .put("edited_at", item.editedAt ?: JSONObject.NULL)
            .put("deleted_at", item.deletedAt ?: JSONObject.NULL)
            .put("is_deleted", item.isDeleted)
            .put("state", item.state)
            .put("reply_to", item.replyTo?.let(::replyToJson) ?: JSONObject.NULL)
            .put("reactions", reactions)
            .put("attachments", attachments)
    }

    private fun userToJson(item: ChatUser): JSONObject = JSONObject()
        .put("id", item.id)
        .put("username", item.username)
        .put("display_name", item.displayName)
        .put("business_mode", item.businessMode)

    private fun replyToJson(item: ReplyPreview): JSONObject = JSONObject()
        .put("id", item.id)
        .put("sender_id", item.senderId)
        .put("body", item.body)
        .put("is_deleted", item.isDeleted)

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

    private fun parseUser(json: JSONObject): ChatUser = ChatUser(
        id = json.getString("id"),
        username = json.getString("username"),
        displayName = json.getString("display_name"),
        businessMode = json.optBoolean("business_mode", false),
    )

    private fun parseMessage(json: JSONObject): ChatMessage {
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
                val reaction = reactionsJson.getJSONObject(index)
                ReactionSummary(
                    emoji = reaction.getString("emoji"),
                    count = reaction.getInt("count"),
                    reactedByMe = reaction.optBoolean("reacted_by_me", false),
                )
            },
            attachments = List(attachmentsJson.length()) { index ->
                val attachment = attachmentsJson.getJSONObject(index)
                ChatAttachment(
                    id = attachment.getString("id"),
                    kind = attachment.getString("kind"),
                    fileName = attachment.getString("file_name"),
                    contentType = attachment.getString("content_type"),
                    sizeBytes = attachment.getLong("size_bytes"),
                    status = attachment.getString("status"),
                    downloadPath = attachment.optString("download_path"),
                )
            },
        )
    }
}
