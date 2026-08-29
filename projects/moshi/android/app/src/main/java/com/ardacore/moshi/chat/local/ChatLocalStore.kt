package com.ardacore.moshi.chat.local

import android.content.Context
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.ChatMessage
import com.ardacore.moshi.chat.ChatUser
import com.ardacore.moshi.chat.ReactionSummary
import com.ardacore.moshi.chat.ReplyPreview
import org.json.JSONArray
import org.json.JSONObject

class ChatLocalStore(context: Context) {
    private val dao = MoshiChatDatabase.get(context).chatDao()

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
        if (items.isNotEmpty()) {
            dao.upsertMessages(items.map(::messageEntity))
        }
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

    suspend fun pending(): List<OutboxMessageEntity> = dao.outbox()

    suspend fun acknowledge(clientMessageId: String, serverMessage: ChatMessage) {
        dao.deleteMessageByClientId(clientMessageId)
        dao.upsertMessage(messageEntity(serverMessage))
        dao.removeOutbox(clientMessageId)
    }

    suspend fun markAttempt(clientMessageId: String, error: String) {
        dao.markAttempt(clientMessageId, error.take(500))
    }

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
        .put("latest_message", item.latestMessage?.let(::messageToJson) ?: JSONObject.NULL)
        .put("unread_count", item.unreadCount)

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

    private fun parseConversation(json: JSONObject): ChatConversation = ChatConversation(
        id = json.getString("id"),
        kind = json.getString("kind"),
        peer = json.optJSONObject("peer")?.let(::parseUser),
        latestMessage = json.optJSONObject("latest_message")?.let(::parseMessage),
        unreadCount = json.optInt("unread_count", 0),
    )

    private fun parseUser(json: JSONObject): ChatUser = ChatUser(
        id = json.getString("id"),
        username = json.getString("username"),
        displayName = json.getString("display_name"),
        businessMode = json.optBoolean("business_mode", false),
    )

    private fun parseMessage(json: JSONObject): ChatMessage {
        val replyJson = json.optJSONObject("reply_to")
        val reactionsJson = json.optJSONArray("reactions") ?: JSONArray()
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
        )
    }
}
