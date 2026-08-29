package com.ardacore.moshi.chat

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.chat.local.ChatLocalStore
import com.ardacore.moshi.chat.local.OutboxMessageEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okhttp3.WebSocket
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

class ChatController(
    private val session: AuthSession,
    private val local: ChatLocalStore,
    private val api: ChatApi = ChatApi(),
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var socket: WebSocket? = null
    private var reconnectJob: Job? = null
    private var stopped = false

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
        stopped = false
        conversations = local.conversations()
        runCatching { syncConversations() }
            .onFailure { failure ->
                if (conversations.isEmpty()) error = failure.message ?: "MOSHI is offline"
            }
        retryOutboxInternal()
        connectRealtime()
    }

    suspend fun loadConversations() = runBusy {
        syncConversations()
        retryOutboxInternal()
    }

    suspend fun search(query: String) = runBusy {
        searchResults = if (query.isBlank()) emptyList() else api.searchUsers(session.accessToken, query.trim())
    }

    suspend fun startDirect(user: ChatUser) {
        val conversation = runBusyResult { api.createDirect(session.accessToken, user.username) } ?: return
        activeConversation = conversation
        searchResults = emptyList()
        local.cacheConversations(listOf(conversation) + conversations.filterNot { it.id == conversation.id })
        runBusy {
            loadConversationMessages(conversation)
            retryOutboxInternal()
            syncConversations()
        }
    }

    suspend fun openConversation(conversation: ChatConversation) {
        activeConversation = conversation
        messages = local.messages(conversation.id)
        runBusy {
            loadConversationMessages(conversation)
            retryOutboxInternal()
            syncConversations()
        }
    }

    fun closeConversation() {
        activeConversation = null
        messages = emptyList()
        scope.launch {
            runCatching { syncConversations() }
        }
    }

    suspend fun send(body: String, replyToId: String? = null) {
        val conversation = activeConversation ?: return
        val cleanBody = body.trim()
        if (cleanBody.isBlank()) return

        val clientMessageId = UUID.randomUUID().toString()
        val replyPreview = replyToId?.let { id ->
            messages.firstOrNull { it.id == id }?.let { source ->
                ReplyPreview(
                    id = source.id,
                    senderId = source.senderId,
                    body = source.body,
                    isDeleted = source.isDeleted,
                )
            }
        }
        val optimistic = ChatMessage(
            id = "local:$clientMessageId",
            conversationId = conversation.id,
            senderId = session.user.id,
            clientMessageId = clientMessageId,
            body = cleanBody,
            createdAt = Instant.now().toString(),
            editedAt = null,
            deletedAt = null,
            isDeleted = false,
            state = "queued",
            replyTo = replyPreview,
            reactions = emptyList(),
            attachments = emptyList(),
        )
        local.enqueue(
            conversationId = conversation.id,
            clientMessageId = clientMessageId,
            body = cleanBody,
            replyToId = replyToId,
            localMessage = optimistic,
        )
        upsertMessage(optimistic)

        val pending = local.pending().firstOrNull { it.clientMessageId == clientMessageId }
        if (pending != null) {
            val sent = attemptPending(pending)
            if (!sent) error = "Message queued. MOSHI will retry when connected."
        }
        runCatching { syncConversations() }
    }

    suspend fun sendAttachment(
        body: String,
        replyToId: String?,
        kind: String,
        fileName: String,
        contentType: String,
        bytes: ByteArray,
    ) = runBusy {
        val conversation = activeConversation ?: return@runBusy
        val ticket = api.initUpload(
            accessToken = session.accessToken,
            kind = kind,
            fileName = fileName,
            contentType = contentType,
            sizeBytes = bytes.size.toLong(),
        )
        val attachment = api.uploadContent(session.accessToken, ticket, bytes)
        val sent = api.sendMessage(
            accessToken = session.accessToken,
            conversationId = conversation.id,
            clientMessageId = UUID.randomUUID().toString(),
            body = body.trim(),
            replyToId = replyToId,
            attachmentIds = listOf(attachment.id),
        )
        local.cacheMessage(sent)
        upsertMessage(sent)
        syncConversations()
    }

    suspend fun retryPending() = runBusy {
        retryOutboxInternal()
        activeConversation?.let { conversation ->
            messages = local.messages(conversation.id)
        }
        syncConversations()
    }

    suspend fun edit(message: ChatMessage, body: String) = runBusy {
        if (message.id.startsWith("local:")) return@runBusy
        val updated = api.editMessage(session.accessToken, message.conversationId, message.id, body.trim())
        local.cacheMessage(updated)
        upsertMessage(updated)
        syncConversations()
    }

    suspend fun delete(message: ChatMessage) = runBusy {
        if (message.id.startsWith("local:")) return@runBusy
        val updated = api.deleteMessage(session.accessToken, message.conversationId, message.id)
        local.cacheMessage(updated)
        upsertMessage(updated)
        syncConversations()
    }

    suspend fun toggleReaction(message: ChatMessage, emoji: String) = runBusy {
        if (message.id.startsWith("local:")) return@runBusy
        val updated = api.toggleReaction(session.accessToken, message.conversationId, message.id, emoji)
        local.cacheMessage(updated)
        upsertMessage(updated)
    }

    fun stop() {
        stopped = true
        reconnectJob?.cancel()
        reconnectJob = null
        socket?.close(1000, "MOSHI screen closed")
        socket = null
    }

    fun clearError() {
        error = null
    }

    private suspend fun loadConversationMessages(conversation: ChatConversation) {
        val remote = api.messages(session.accessToken, conversation.id)
        local.cacheMessages(remote)
        messages = local.messages(conversation.id)
        markLastRead()
    }

    private suspend fun syncConversations() {
        val remote = api.conversations(session.accessToken)
        conversations = remote
        local.cacheConversations(remote)
    }

    private suspend fun retryOutboxInternal() {
        val pending = local.pending()
        for (item in pending) attemptPending(item)
    }

    private suspend fun attemptPending(item: OutboxMessageEntity): Boolean {
        return try {
            val sent = api.sendMessage(
                accessToken = session.accessToken,
                conversationId = item.conversationId,
                clientMessageId = item.clientMessageId,
                body = item.body,
                replyToId = item.replyToId,
            )
            local.acknowledge(item.clientMessageId, sent)
            if (activeConversation?.id == item.conversationId) upsertMessage(sent)
            true
        } catch (t: Throwable) {
            local.markAttempt(item.clientMessageId, t.message ?: "send failed")
            false
        }
    }

    private suspend fun markLastRead() {
        val conversation = activeConversation ?: return
        val latestIncoming = messages.lastOrNull { it.senderId != session.user.id && !it.id.startsWith("local:") } ?: return
        api.markRead(session.accessToken, conversation.id, latestIncoming.id)
    }

    private fun connectRealtime() {
        if (stopped || socket != null) return
        socket = api.openRealtime(
            accessToken = session.accessToken,
            onOpen = {
                scope.launch {
                    reconnectJob?.cancel()
                    reconnectJob = null
                    error = null
                    retryOutboxInternal()
                    runCatching { syncConversations() }
                    activeConversation?.let { conversation ->
                        messages = local.messages(conversation.id)
                    }
                }
            },
            onEvent = { event -> scope.launch { handleEvent(event) } },
            onFailure = { failure ->
                scope.launch {
                    socket = null
                    if (!stopped) {
                        error = failure.message ?: "Realtime disconnected"
                        scheduleReconnect()
                    }
                }
            },
            onClosed = {
                scope.launch {
                    socket = null
                    if (!stopped) scheduleReconnect()
                }
            },
        )
    }

    private fun scheduleReconnect() {
        if (stopped || reconnectJob?.isActive == true) return
        reconnectJob = scope.launch {
            delay(5_000)
            connectRealtime()
        }
    }

    private suspend fun handleEvent(event: JSONObject) {
        when (event.optString("type")) {
            "message.created", "message.updated" -> {
                val messageJson = event.optJSONObject("message") ?: return
                val message = api.parseMessage(messageJson)
                local.cacheMessage(message)
                if (activeConversation?.id == message.conversationId) {
                    upsertMessage(message)
                    if (event.optString("type") == "message.created" && message.senderId != session.user.id) {
                        runCatching { api.markRead(session.accessToken, message.conversationId, message.id) }
                    }
                }
                runCatching { syncConversations() }
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
                val updated = messages.map { item ->
                    if (item.id in readIds && item.senderId == session.user.id) item.copy(state = "read") else item
                }
                messages = updated
                updated.filter { it.id in readIds }.forEach { local.cacheMessage(it) }
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

    private suspend fun <T> runBusyResult(block: suspend () -> T): T? {
        if (busy) return null
        busy = true
        error = null
        return try {
            block()
        } catch (t: Throwable) {
            error = t.message ?: "MOSHI chat request failed"
            null
        } finally {
            busy = false
        }
    }
}
