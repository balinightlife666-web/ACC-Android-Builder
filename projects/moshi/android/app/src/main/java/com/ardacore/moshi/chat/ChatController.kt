package com.ardacore.moshi.chat

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.ardacore.moshi.auth.AuthSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import okhttp3.WebSocket
import org.json.JSONObject
import java.util.UUID

class ChatController(
    private val session: AuthSession,
    private val api: ChatApi = ChatApi(),
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var socket: WebSocket? = null

    var conversations: List<ChatConversation> by mutableStateOf(emptyList())
        private set
    var searchResults: List<ChatUser> by mutableStateOf(emptyList())
        private set
    var activeConversation: ChatConversation? by mutableStateOf(null)
        private set
    var messages: List<ChatMessage> by mutableStateOf(emptyList())
        private set
    var busy: Boolean by mutableStateOf(false)
        private set
    var error: String? by mutableStateOf(null)
        private set

    suspend fun start() {
        loadConversations()
        if (socket == null) {
            socket = api.openRealtime(
                accessToken = session.accessToken,
                onEvent = { event -> scope.launch { handleEvent(event) } },
                onFailure = { failure -> scope.launch { error = failure.message ?: "Realtime disconnected" } },
            )
        }
    }

    suspend fun loadConversations() = runBusy {
        conversations = api.conversations(session.accessToken)
    }

    suspend fun search(query: String) = runBusy {
        searchResults = if (query.isBlank()) emptyList() else api.searchUsers(session.accessToken, query.trim())
    }

    suspend fun startDirect(user: ChatUser) = runBusy {
        val conversation = api.createDirect(session.accessToken, user.username)
        activeConversation = conversation
        searchResults = emptyList()
        messages = api.messages(session.accessToken, conversation.id)
        markLastRead()
        conversations = api.conversations(session.accessToken)
    }

    suspend fun openConversation(conversation: ChatConversation) = runBusy {
        activeConversation = conversation
        messages = api.messages(session.accessToken, conversation.id)
        markLastRead()
        conversations = api.conversations(session.accessToken)
    }

    fun closeConversation() {
        activeConversation = null
        messages = emptyList()
        scope.launch { loadConversations() }
    }

    suspend fun send(body: String, replyToId: String? = null) = runBusy {
        val conversation = activeConversation ?: return@runBusy
        val sent = api.sendMessage(
            accessToken = session.accessToken,
            conversationId = conversation.id,
            clientMessageId = UUID.randomUUID().toString(),
            body = body.trim(),
            replyToId = replyToId,
        )
        upsertMessage(sent)
        conversations = api.conversations(session.accessToken)
    }

    suspend fun edit(message: ChatMessage, body: String) = runBusy {
        val updated = api.editMessage(session.accessToken, message.conversationId, message.id, body.trim())
        upsertMessage(updated)
        conversations = api.conversations(session.accessToken)
    }

    suspend fun delete(message: ChatMessage) = runBusy {
        val updated = api.deleteMessage(session.accessToken, message.conversationId, message.id)
        upsertMessage(updated)
        conversations = api.conversations(session.accessToken)
    }

    suspend fun toggleReaction(message: ChatMessage, emoji: String) = runBusy {
        val updated = api.toggleReaction(session.accessToken, message.conversationId, message.id, emoji)
        upsertMessage(updated)
    }

    fun stop() {
        socket?.close(1000, "MOSHI screen closed")
        socket = null
    }

    fun clearError() {
        error = null
    }

    private suspend fun markLastRead() {
        val conversation = activeConversation ?: return
        val latestIncoming = messages.lastOrNull { it.senderId != session.user.id } ?: return
        api.markRead(session.accessToken, conversation.id, latestIncoming.id)
    }

    private suspend fun handleEvent(event: JSONObject) {
        when (event.optString("type")) {
            "message.created", "message.updated" -> {
                val messageJson = event.optJSONObject("message") ?: return
                val message = api.parseMessage(messageJson)
                if (activeConversation?.id == message.conversationId) {
                    upsertMessage(message)
                    if (event.optString("type") == "message.created" && message.senderId != session.user.id) {
                        api.markRead(session.accessToken, message.conversationId, message.id)
                    }
                }
                conversations = api.conversations(session.accessToken)
            }
            "message.read" -> {
                val idsJson = event.optJSONArray("message_ids")
                val readIds = if (idsJson != null) {
                    buildSet {
                        for (index in 0 until idsJson.length()) add(idsJson.getString(index))
                    }
                } else {
                    setOf(event.optString("message_id"))
                }
                messages = messages.map { item ->
                    if (item.id in readIds && item.senderId == session.user.id) item.copy(state = "read") else item
                }
            }
        }
    }

    private fun upsertMessage(message: ChatMessage) {
        val without = messages.filterNot { it.id == message.id || it.clientMessageId == message.clientMessageId }
        messages = (without + message).sortedBy { it.createdAt }
    }

    private suspend fun runBusy(block: suspend () -> Unit) {
        if (busy) return
        busy = true
        error = null
        try {
            block()
        } catch (t: Throwable) {
            error = t.message ?: "MOSHI chat request failed"
        } finally {
            busy = false
        }
    }
}
