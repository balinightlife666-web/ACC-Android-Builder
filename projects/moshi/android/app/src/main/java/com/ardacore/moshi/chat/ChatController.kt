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
    private var reconnectAttempt = 0
    private var stopped = false

    var conversations: List<ChatConversation> by mutableStateOf(emptyList())
        private set
    var searchResults: List<ChatUser> by mutableStateOf(emptyList())
        private set
    var activeConversation: ChatConversation? by mutableStateOf(null)
        private set
    var groupMembers: List<GroupMember> by mutableStateOf(emptyList())
        private set
    var messages: List<ChatMessage> by mutableStateOf(emptyList())
        private set
    var busy: Boolean by mutableStateOf(false)
        private set
    var error: String? by mutableStateOf(null)
        private set
    var realtimeStatus: String by mutableStateOf("connecting")
        private set

    suspend fun start() {
        stopped = false
        realtimeStatus = "connecting"
        conversations = local.conversations()
        runCatching { syncConversations() }
            .onFailure { if (conversations.isEmpty()) error = "MOSHI is offline. We'll reconnect automatically." }
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

    fun startDirect(user: ChatUser) {
        scope.launch { startDirectInternal(user) }
    }

    private suspend fun startDirectInternal(user: ChatUser) {
        val conversation = runBusyResult { api.createDirect(session.accessToken, user.username) } ?: return
        activeConversation = conversation
        groupMembers = emptyList()
        searchResults = emptyList()
        local.cacheConversations(listOf(conversation) + conversations.filterNot { it.id == conversation.id })
        runBusy {
            loadConversationMessages(conversation)
            retryOutboxInternal()
            syncConversations()
        }
    }

    suspend fun createGroup(title: String, usernames: List<String>) {
        val cleanTitle = title.trim()
        if (cleanTitle.isBlank()) return
        val normalized = usernames.map { it.trim().removePrefix("@") }.filter { it.isNotBlank() }.distinct()
        val conversation = runBusyResult { api.createGroup(session.accessToken, cleanTitle, normalized) } ?: return
        activeConversation = conversation
        searchResults = emptyList()
        local.cacheConversations(listOf(conversation) + conversations.filterNot { it.id == conversation.id })
        runBusy {
            loadGroupMembersInternal(conversation)
            loadConversationMessages(conversation)
            syncConversations()
        }
    }

    fun openConversation(conversation: ChatConversation) {
        scope.launch { openConversationInternal(conversation) }
    }

    private suspend fun openConversationInternal(conversation: ChatConversation) {
        activeConversation = conversation
        messages = local.messages(conversation.id)
        groupMembers = emptyList()
        runBusy {
            if (conversation.kind == "group") loadGroupMembersInternal(conversation)
            loadConversationMessages(conversation)
            retryOutboxInternal()
            syncConversations()
        }
    }

    fun closeConversation() {
        activeConversation = null
        groupMembers = emptyList()
        messages = emptyList()
        scope.launch { runCatching { syncConversations() } }
    }

    suspend fun refreshGroupMembers() = runBusy {
        val conversation = activeConversation ?: return@runBusy
        if (conversation.kind == "group") loadGroupMembersInternal(conversation)
    }

    suspend fun addGroupMember(username: String) = runBusy {
        val conversation = activeConversation ?: return@runBusy
        if (conversation.kind != "group") return@runBusy
        api.addGroupMember(session.accessToken, conversation.id, username)
        loadGroupMembersInternal(conversation)
        syncConversations()
        activeConversation = conversations.firstOrNull { it.id == conversation.id } ?: conversation
    }

    suspend fun setGroupRole(member: GroupMember, role: String) = runBusy {
        val conversation = activeConversation ?: return@runBusy
        if (conversation.kind != "group") return@runBusy
        api.updateGroupRole(session.accessToken, conversation.id, member.user.id, role)
        loadGroupMembersInternal(conversation)
        syncConversations()
        activeConversation = conversations.firstOrNull { it.id == conversation.id } ?: conversation
    }

    suspend fun removeGroupMember(member: GroupMember) = runBusy {
        val conversation = activeConversation ?: return@runBusy
        if (conversation.kind != "group") return@runBusy
        api.removeGroupMember(session.accessToken, conversation.id, member.user.id)
        if (member.user.id == session.user.id) {
            activeConversation = null
            groupMembers = emptyList()
            messages = emptyList()
            syncConversations()
        } else {
            loadGroupMembersInternal(conversation)
            syncConversations()
            activeConversation = conversations.firstOrNull { it.id == conversation.id } ?: conversation
        }
    }

    suspend fun send(body: String, replyToId: String? = null) {
        val conversation = activeConversation ?: return
        val cleanBody = body.trim()
        if (cleanBody.isBlank()) return
        val clientMessageId = UUID.randomUUID().toString()
        val optimistic = optimisticMessage(conversation.id, clientMessageId, cleanBody, replyToId, emptyList())
        local.enqueue(
            conversationId = conversation.id,
            clientMessageId = clientMessageId,
            body = cleanBody,
            replyToId = replyToId,
            localMessage = optimistic,
        )
        upsertMessage(optimistic)
        val pending = local.pending().firstOrNull { it.clientMessageId == clientMessageId }
        if (pending != null && !attemptPending(pending)) error = "Message saved offline. MOSHI will send it when connected."
        runCatching { syncConversations() }
    }

    suspend fun sendAttachment(
        body: String,
        replyToId: String?,
        kind: String,
        fileName: String,
        contentType: String,
        sizeBytes: Long,
        uri: String,
    ) = runBusy {
        val conversation = activeConversation ?: return@runBusy
        val clientMessageId = UUID.randomUUID().toString()
        val localAttachment = ChatAttachment(
            id = "local-attachment:$clientMessageId",
            kind = kind,
            fileName = fileName,
            contentType = contentType,
            sizeBytes = sizeBytes,
            status = "queued",
            downloadPath = "",
        )
        val optimistic = optimisticMessage(
            conversationId = conversation.id,
            clientMessageId = clientMessageId,
            body = body.trim(),
            replyToId = replyToId,
            attachments = listOf(localAttachment),
        )
        local.enqueueAttachment(
            conversationId = conversation.id,
            clientMessageId = clientMessageId,
            body = body.trim(),
            replyToId = replyToId,
            attachmentUri = uri,
            attachmentKind = kind,
            attachmentFileName = fileName,
            attachmentContentType = contentType,
            attachmentSizeBytes = sizeBytes,
            localMessage = optimistic,
        )
        upsertMessage(optimistic)
        val pending = local.pending().firstOrNull { it.clientMessageId == clientMessageId }
        if (pending != null && !attemptPending(pending)) {
            error = "Attachment saved offline. MOSHI will send it when connected."
        }
        runCatching { syncConversations() }
    }

    suspend fun orderCatalogCard(message: ChatMessage, quantity: Int = 1): OrderDraftResult? = runBusyResult {
        val conversation = activeConversation ?: error("Conversation is not open")
        if (conversation.kind != "direct") error("Orders must be created in a direct chat")
        if (message.catalogCard == null) error("Catalog card is unavailable")
        val result = api.createOrderDraft(
            accessToken = session.accessToken,
            conversationId = conversation.id,
            catalogMessageId = message.id,
            clientMessageId = UUID.randomUUID().toString(),
            quantity = quantity,
        )
        local.cacheMessage(result.message)
        upsertMessage(result.message)
        syncConversations()
        result
    }

    suspend fun downloadAttachment(attachment: ChatAttachment): ByteArray? = runBusyResult {
        api.downloadAttachment(session.accessToken, attachment)
    }

    suspend fun downloadCommerceImage(path: String): ByteArray? = runBusyResult {
        api.downloadBytes(session.accessToken, path, "image/*")
    }

    suspend fun retryPending() = runBusy {
        retryOutboxInternal()
        activeConversation?.let { conversation -> messages = local.messages(conversation.id) }
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
        realtimeStatus = "offline"
        reconnectJob?.cancel()
        reconnectJob = null
        socket?.close(1000, "MOSHI screen closed")
        socket = null
    }

    fun clearError() {
        error = null
    }

    private fun optimisticMessage(
        conversationId: String,
        clientMessageId: String,
        body: String,
        replyToId: String?,
        attachments: List<ChatAttachment>,
    ): ChatMessage {
        val replyPreview = replyToId?.let { id ->
            messages.firstOrNull { it.id == id }?.let { source ->
                ReplyPreview(source.id, source.senderId, source.body, source.isDeleted)
            }
        }
        return ChatMessage(
            id = "local:$clientMessageId",
            conversationId = conversationId,
            senderId = session.user.id,
            clientMessageId = clientMessageId,
            body = body,
            createdAt = Instant.now().toString(),
            editedAt = null,
            deletedAt = null,
            isDeleted = false,
            state = "queued",
            replyTo = replyPreview,
            reactions = emptyList(),
            attachments = attachments,
            catalogCard = null,
            orderCard = null,
        )
    }

    private suspend fun loadConversationMessages(conversation: ChatConversation) {
        val remote = api.messages(session.accessToken, conversation.id)
        local.cacheMessages(remote)
        messages = local.messages(conversation.id)
        markLastRead()
    }

    private suspend fun loadGroupMembersInternal(conversation: ChatConversation) {
        groupMembers = api.groupMembers(session.accessToken, conversation.id)
    }

    private suspend fun syncConversations() {
        val remote = api.conversations(session.accessToken)
        conversations = remote
        local.cacheConversations(remote)
    }

    private suspend fun retryOutboxInternal() {
        for (item in local.pending()) attemptPending(item)
    }

    private suspend fun attemptPending(item: OutboxMessageEntity): Boolean {
        return try {
            var attachmentId = item.uploadedAttachmentId
            if (item.attachmentUri != null && attachmentId == null) {
                val kind = item.attachmentKind ?: error("Queued attachment kind is missing")
                val fileName = item.attachmentFileName ?: error("Queued attachment name is missing")
                val contentType = item.attachmentContentType ?: error("Queued attachment type is missing")
                val sizeBytes = item.attachmentSizeBytes ?: error("Queued attachment size is missing")
                val bytes = local.readPendingAttachment(item)
                val ticket = api.initUpload(
                    accessToken = session.accessToken,
                    kind = kind,
                    fileName = fileName,
                    contentType = contentType,
                    sizeBytes = sizeBytes,
                )
                val uploaded = api.uploadContent(session.accessToken, ticket, bytes)
                attachmentId = uploaded.id
                local.markAttachmentUploaded(item.clientMessageId, uploaded.id)
            }
            val sent = api.sendMessage(
                accessToken = session.accessToken,
                conversationId = item.conversationId,
                clientMessageId = item.clientMessageId,
                body = item.body,
                replyToId = item.replyToId,
                attachmentIds = listOfNotNull(attachmentId),
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
        realtimeStatus = "connecting"
        socket = api.openRealtime(
            accessToken = session.accessToken,
            onOpen = {
                scope.launch {
                    reconnectJob?.cancel()
                    reconnectJob = null
                    reconnectAttempt = 0
                    realtimeStatus = "online"
                    error = null
                    retryOutboxInternal()
                    runCatching { syncConversations() }
                    activeConversation?.let { conversation ->
                        messages = local.messages(conversation.id)
                        if (conversation.kind == "group") runCatching { loadGroupMembersInternal(conversation) }
                    }
                }
            },
            onEvent = { event -> scope.launch { handleEvent(event) } },
            onFailure = {
                scope.launch {
                    socket = null
                    if (!stopped) {
                        realtimeStatus = "offline"
                        scheduleReconnect()
                    }
                }
            },
            onClosed = {
                scope.launch {
                    socket = null
                    if (!stopped) {
                        realtimeStatus = "offline"
                        scheduleReconnect()
                    }
                }
            },
        )
    }

    private fun scheduleReconnect() {
        if (stopped || reconnectJob?.isActive == true) return
        val delayMs = when (reconnectAttempt.coerceAtMost(3)) {
            0 -> 2_000L
            1 -> 5_000L
            2 -> 10_000L
            else -> 30_000L
        }
        reconnectAttempt += 1
        reconnectJob = scope.launch {
            delay(delayMs)
            reconnectJob = null
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
                    buildSet { for (index in 0 until idsJson.length()) add(idsJson.getString(index)) }
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
            error = userFacingError(t)
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
            error = userFacingError(t)
            null
        } finally {
            busy = false
        }
    }

    private fun userFacingError(t: Throwable): String {
        val raw = t.message.orEmpty()
        return when {
            raw.contains("401") || raw.contains("403") || raw.contains("forbidden", ignoreCase = true) ->
                "This action isn't available right now."
            raw.contains("timeout", ignoreCase = true) ||
                raw.contains("failed to connect", ignoreCase = true) ||
                raw.contains("connection", ignoreCase = true) ||
                raw.contains("network", ignoreCase = true) ->
                "Connection problem. MOSHI will keep trying."
            raw.contains("HTTP", ignoreCase = true) ->
                "MOSHI couldn't complete that request."
            raw.isBlank() -> "MOSHI couldn't complete that request."
            else -> raw.take(180)
        }
    }
}
