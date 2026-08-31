package com.ardacore.moshi

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material.icons.rounded.AttachFile
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.Mic
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Send
import androidx.compose.material.icons.rounded.StopCircle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.chat.ChatController
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.ChatMessage
import com.ardacore.moshi.chat.ChatUser
import com.ardacore.moshi.chat.local.ChatListStateStore
import com.ardacore.moshi.chat.local.ChatLocalStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private const val MASTER_MAX_ATTACHMENT_BYTES = 20L * 1024L * 1024L

private data class MasterPickedAttachment(
    val kind: String,
    val name: String,
    val contentType: String,
    val size: Long,
    val uri: String,
)

@Composable
fun MoshiChatsScreen(
    session: AuthSession,
    modifier: Modifier = Modifier,
    onImmersiveChanged: (Boolean) -> Unit = {},
) {
    val context = LocalContext.current.applicationContext
    val controller = remember(session.accessToken) { ChatController(session, ChatLocalStore(context)) }
    LaunchedEffect(controller) { controller.start() }
    DisposableEffect(controller) {
        onDispose {
            onImmersiveChanged(false)
            controller.stop()
        }
    }

    val inDirectChat = controller.activeConversation?.kind == "direct"
    LaunchedEffect(inDirectChat) { onImmersiveChanged(inDirectChat) }

    if (inDirectChat) MasterDirectConversation(controller, session, modifier)
    else MasterDirectList(controller, modifier)
}

@Composable
private fun MasterDirectList(controller: ChatController, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current.applicationContext
    val listStateStore = remember { ChatListStateStore(context) }
    var query by remember { mutableStateOf("") }
    var searchOpen by remember { mutableStateOf(false) }
    var viewMode by remember { mutableStateOf("all") }
    var archivedIds by remember { mutableStateOf(listStateStore.archived()) }
    var hiddenIds by remember { mutableStateOf(listStateStore.hidden()) }
    var pinnedIds by remember { mutableStateOf(listStateStore.pinned()) }
    var folderAssignments by remember { mutableStateOf(listStateStore.folderAssignments()) }
    var actionTarget by remember { mutableStateOf<ChatConversation?>(null) }
    var folderInput by remember { mutableStateOf("") }

    fun reloadListState() {
        archivedIds = listStateStore.archived()
        hiddenIds = listStateStore.hidden()
        pinnedIds = listStateStore.pinned()
        folderAssignments = listStateStore.folderAssignments()
    }

    fun closeActions() {
        actionTarget = null
        folderInput = ""
    }

    val allDirect = controller.conversations.filter { it.kind == "direct" }
    val archivedCount = allDirect.count { it.id in archivedIds && it.id !in hiddenIds }
    val hiddenCount = allDirect.count { it.id in hiddenIds }
    val folderNames = folderAssignments.values.distinct().sortedBy { it.lowercase() }
    val baseDirect = when {
        viewMode == "archived" -> allDirect.filter { it.id in archivedIds && it.id !in hiddenIds }
        viewMode == "hidden" -> allDirect.filter { it.id in hiddenIds }
        viewMode.startsWith("folder:") -> {
            val folder = viewMode.removePrefix("folder:")
            allDirect.filter {
                folderAssignments[it.id] == folder && it.id !in archivedIds && it.id !in hiddenIds
            }
        }
        else -> allDirect.filter { it.id !in archivedIds && it.id !in hiddenIds }
    }
    val direct = baseDirect.filter { it.id in pinnedIds } + baseDirect.filterNot { it.id in pinnedIds }

    Column(
        modifier = modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column {
                Text("MOSHI", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Black)
                Text(
                    when {
                        viewMode == "archived" -> "Archived"
                        viewMode == "hidden" -> "Hidden chats"
                        viewMode.startsWith("folder:") -> viewMode.removePrefix("folder:")
                        else -> "Chats"
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                )
                if (controller.realtimeStatus != "online") {
                    Text(
                        if (controller.realtimeStatus == "connecting") "Connecting…" else "Offline · reconnecting automatically",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (viewMode != "all") {
                    TextButton(onClick = { viewMode = "all" }) { Text("All chats") }
                }
                IconButton(onClick = { searchOpen = !searchOpen; if (!searchOpen) controller.clearError() }) {
                    Icon(Icons.Rounded.Search, contentDescription = "Find people")
                }
            }
        }

        if (viewMode == "all" && folderNames.isNotEmpty()) {
            Row(
                modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                folderNames.forEach { folder ->
                    OutlinedButton(onClick = { viewMode = "folder:$folder" }) {
                        Text(folder, maxLines = 1, style = MaterialTheme.typography.labelMedium)
                    }
                }
            }
        }

        if (viewMode == "all" && archivedCount > 0) {
            TextButton(onClick = { viewMode = "archived" }) {
                Text("Archived ($archivedCount)")
            }
        }

        if (searchOpen) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("Find @username") },
                    singleLine = true,
                )
                Button(
                    onClick = {
                        val value = query.trim()
                        if (value.equals("#hidden", ignoreCase = true)) {
                            viewMode = "hidden"
                            query = ""
                            searchOpen = false
                            controller.clearError()
                        } else {
                            scope.launch { controller.search(value) }
                        }
                    },
                    enabled = query.isNotBlank() && !controller.busy,
                ) { Text("Find") }
            }
            if (controller.searchResults.isNotEmpty()) {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    items(controller.searchResults, key = { it.id }) { user ->
                        MasterUserResult(user) {
                            controller.startDirect(user)
                            query = ""
                            searchOpen = false
                        }
                    }
                }
            }
        }

        controller.error?.let {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    it,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                TextButton(onClick = controller::clearError) { Text("Dismiss") }
            }
        }

        if (viewMode == "hidden" && hiddenCount == 0) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("No hidden chats", fontWeight = FontWeight.Bold)
                    Text("Long-press a chat and choose Hide to move it here.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else if (direct.isEmpty()) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        when {
                            viewMode == "archived" -> "No archived chats"
                            viewMode.startsWith("folder:") -> "This folder is empty"
                            else -> "No chats yet"
                        },
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        when {
                            viewMode == "archived" -> "Archived chats will appear here."
                            viewMode.startsWith("folder:") -> "Long-press a chat to move it into this folder."
                            else -> "Search a username to start a private conversation."
                        },
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                items(direct, key = { it.id }) { conversation ->
                    MasterConversationRow(
                        conversation = conversation,
                        pinned = conversation.id in pinnedIds,
                        folderName = folderAssignments[conversation.id],
                        onClick = { controller.openConversation(conversation) },
                        onLongClick = {
                            actionTarget = conversation
                            folderInput = folderAssignments[conversation.id].orEmpty()
                        },
                    )
                }
            }
        }
    }

    actionTarget?.let { target ->
        val targetName = target.peer?.displayName ?: "Chat"
        val isArchived = target.id in archivedIds
        val isHidden = target.id in hiddenIds
        val isPinned = target.id in pinnedIds
        AlertDialog(
            onDismissRequest = ::closeActions,
            title = { Text(targetName) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    TextButton(
                        onClick = {
                            listStateStore.setPinned(target.id, !isPinned)
                            reloadListState()
                            closeActions()
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text(if (isPinned) "Unpin chat" else "Pin chat") }
                    TextButton(
                        onClick = {
                            listStateStore.setArchived(target.id, !isArchived)
                            reloadListState()
                            closeActions()
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text(if (isArchived) "Unarchive" else "Archive") }
                    TextButton(
                        onClick = {
                            listStateStore.setHidden(target.id, !isHidden)
                            reloadListState()
                            closeActions()
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text(if (isHidden) "Unhide chat" else "Hide chat") }
                    OutlinedTextField(
                        value = folderInput,
                        onValueChange = { folderInput = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Folder") },
                        placeholder = { Text("Personal, Work, Business…") },
                        singleLine = true,
                    )
                    if (folderNames.isNotEmpty()) {
                        Row(
                            modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                        ) {
                            folderNames.forEach { folder ->
                                TextButton(onClick = { folderInput = folder }) { Text(folder, maxLines = 1) }
                            }
                        }
                    }
                    Button(
                        onClick = {
                            listStateStore.moveToFolder(target.id, folderInput.ifBlank { null })
                            reloadListState()
                            closeActions()
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text(if (folderInput.isBlank()) "Remove from folder" else "Move to folder") }
                }
            },
            confirmButton = { TextButton(onClick = ::closeActions) { Text("Done") } },
        )
    }
}

@Composable
private fun MasterUserResult(user: ChatUser, onClick: () -> Unit) {
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            MasterInitialAvatar(user.displayName)
            Column(modifier = Modifier.weight(1f)) {
                Text(user.displayName, fontWeight = FontWeight.SemiBold)
                Text("@${user.username}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (user.businessMode) Text("Business", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MasterConversationRow(
    conversation: ChatConversation,
    pinned: Boolean,
    folderName: String?,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
) {
    val peer = conversation.peer ?: return
    val latest = conversation.latestMessage
    val preview = when {
        latest == null -> "Start talking"
        latest.isDeleted -> "Message deleted"
        latest.orderCard != null -> "Order · ${latest.orderCard.itemTitle}"
        latest.catalogCard != null -> "Catalog · ${latest.catalogCard.title}"
        latest.body.isNotBlank() -> latest.body
        latest.attachments.firstOrNull()?.contentType?.startsWith("audio/") == true -> "Voice note"
        latest.attachments.isNotEmpty() -> "Attachment · ${latest.attachments.first().fileName}"
        else -> "Message"
    }

    Card(
        modifier = Modifier.fillMaxWidth().combinedClickable(onClick = onClick, onLongClick = onLongClick),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 11.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            MasterInitialAvatar(peer.displayName)
            Column(modifier = Modifier.weight(1f)) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(peer.displayName, fontWeight = FontWeight.SemiBold)
                    latest?.createdAt?.let {
                        Text(masterChatListTime(it), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                val prefix = buildString {
                    if (pinned) append("Pinned · ")
                    if (!folderName.isNullOrBlank()) append("$folderName · ")
                }
                Text(prefix + preview, maxLines = 1, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (conversation.unreadCount > 0) {
                Box(
                    modifier = Modifier.size(26.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        "${conversation.unreadCount}",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Black,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }
            }
        }
    }
}

@Composable
private fun MasterDirectConversation(controller: ChatController, session: AuthSession, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val conversation = controller.activeConversation ?: return
    val peer = conversation.peer
    val listState = rememberLazyListState()
    var text by remember(conversation.id) { mutableStateOf("") }
    var selectedId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var replyId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var editingId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var attachmentBusy by remember(conversation.id) { mutableStateOf(false) }
    var localError by remember(conversation.id) { mutableStateOf<String?>(null) }
    val selected = controller.messages.firstOrNull { it.id == selectedId }
    val replying = controller.messages.firstOrNull { it.id == replyId }
    val editing = controller.messages.firstOrNull { it.id == editingId }
    val hasQueued = controller.messages.any { it.state == "queued" }

    LaunchedEffect(
        conversation.id,
        controller.messages.size,
        controller.messages.lastOrNull()?.id,
        controller.messages.lastOrNull()?.state,
    ) {
        if (controller.messages.isNotEmpty()) {
            androidx.compose.runtime.withFrameNanos { }
            listState.scrollToItem(controller.messages.lastIndex)
        }
    }

    fun queuePicked(uri: Uri, kind: String) {
        attachmentBusy = true
        localError = null
        val body = text
        val replyTo = replyId
        scope.launch {
            try {
                runCatching { context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
                val picked = withContext(Dispatchers.IO) { masterReadAttachment(context, uri, kind) }
                controller.sendAttachment(body, replyTo, picked.kind, picked.name, picked.contentType, picked.size, picked.uri)
                if (controller.error == null || controller.error?.contains("offline", ignoreCase = true) == true) {
                    text = ""
                    replyId = null
                }
            } catch (t: Throwable) {
                localError = t.message ?: "Could not attach file"
            } finally {
                attachmentBusy = false
            }
        }
    }

    fun queueVoice(file: File) {
        if (!file.isFile || file.length() <= 0L || file.length() > MASTER_MAX_ATTACHMENT_BYTES) {
            localError = "Voice note is invalid"
            return
        }
        attachmentBusy = true
        localError = null
        val body = text
        val replyTo = replyId
        scope.launch {
            try {
                controller.sendAttachment(body, replyTo, "file", file.name, "audio/mp4", file.length(), Uri.fromFile(file).toString())
                if (controller.error == null || controller.error?.contains("offline", ignoreCase = true) == true) {
                    text = ""
                    replyId = null
                }
            } catch (t: Throwable) {
                localError = t.message ?: "Could not queue voice note"
            } finally {
                attachmentBusy = false
            }
        }
    }

    val photoPicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) queuePicked(uri, "image")
    }
    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) queuePicked(uri, "file")
    }

    Column(
        modifier = modifier.fillMaxSize().padding(horizontal = 10.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = controller::closeConversation) {
                Icon(Icons.Rounded.ArrowBack, contentDescription = "Back")
            }
            if (peer != null) MasterInitialAvatar(peer.displayName, 40)
            Column(modifier = Modifier.weight(1f).padding(start = 8.dp)) {
                Text(peer?.displayName ?: "Chat", fontWeight = FontWeight.Bold)
                peer?.let {
                    Text("@${it.username}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (controller.realtimeStatus != "online") {
                    Text(
                        if (controller.realtimeStatus == "connecting") "Connecting…" else "Offline",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }

        LazyColumn(
            state = listState,
            modifier = Modifier.weight(1f).fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            items(controller.messages, key = { it.id }) { item ->
                MasterMessageBubble(
                    accessToken = session.accessToken,
                    message = item,
                    mine = item.senderId == session.user.id,
                    selected = selectedId == item.id,
                    onSelect = { selectedId = if (selectedId == item.id) null else item.id },
                    onAsk = {
                        replyId = item.id
                        selectedId = null
                        editingId = null
                        text = "Hi, I have a question about ${item.catalogCard?.title ?: "this item"}."
                    },
                    onOrder = { scope.launch { controller.orderCatalogCard(item) } },
                )
            }
        }

        if (selected != null) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                TextButton(onClick = { replyId = selected.id; editingId = null; selectedId = null; text = "" }) { Text("Reply") }
                TextButton(onClick = { scope.launch { controller.toggleReaction(selected, "👍") } }) { Text("👍") }
                TextButton(onClick = { scope.launch { controller.toggleReaction(selected, "❤️") } }) { Text("❤️") }
                TextButton(onClick = { scope.launch { controller.toggleReaction(selected, "😂") } }) { Text("😂") }
                if (selected.senderId == session.user.id && !selected.isDeleted && !selected.id.startsWith("local:")) {
                    TextButton(onClick = { editingId = selected.id; replyId = null; text = selected.body; selectedId = null }) { Text("Edit") }
                    TextButton(onClick = { selectedId = null; scope.launch { controller.delete(selected) } }) { Text("Delete") }
                }
            }
        }

        replying?.let {
            Card(modifier = Modifier.fillMaxWidth()) {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        "Reply: ${if (it.isDeleted) "Message deleted" else it.body}",
                        maxLines = 1,
                        modifier = Modifier.weight(1f),
                        style = MaterialTheme.typography.bodySmall,
                    )
                    TextButton(onClick = { replyId = null }) { Text("Cancel") }
                }
            }
        }

        editing?.let {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Editing message", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                TextButton(onClick = { editingId = null; text = "" }) { Text("Cancel") }
            }
        }

        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall) }
        localError?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }

        if (hasQueued) {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Saved offline. MOSHI will retry when connected.",
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                TextButton(onClick = { scope.launch { controller.retryPending() } }, enabled = !controller.busy && !attachmentBusy) {
                    Text("Retry")
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            IconButton(
                onClick = { photoPicker.launch(arrayOf("image/jpeg", "image/png", "image/webp", "image/gif")) },
                enabled = !controller.busy && !attachmentBusy && editing == null,
            ) { Icon(Icons.Rounded.Image, contentDescription = "Photo") }

            IconButton(
                onClick = {
                    filePicker.launch(
                        arrayOf(
                            "application/pdf",
                            "text/plain",
                            "application/zip",
                            "application/msword",
                            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                        )
                    )
                },
                enabled = !controller.busy && !attachmentBusy && editing == null,
            ) { Icon(Icons.Rounded.AttachFile, contentDescription = "File") }

            MasterVoiceIconButton(
                enabled = !controller.busy && !attachmentBusy && editing == null,
                onReady = ::queueVoice,
                onError = { localError = it },
            )

            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text(if (editing != null) "Edit message" else "Message") },
                maxLines = 4,
            )

            IconButton(
                onClick = {
                    val value = text
                    text = ""
                    if (editing != null) {
                        editingId = null
                        scope.launch { controller.edit(editing, value) }
                    } else {
                        val replyTo = replyId
                        replyId = null
                        scope.launch { controller.send(value, replyTo) }
                    }
                },
                enabled = text.isNotBlank() && !controller.busy && !attachmentBusy,
            ) { Icon(Icons.Rounded.Send, contentDescription = if (editing != null) "Save" else "Send") }
        }
    }
}

@Composable
private fun MasterMessageBubble(
    accessToken: String,
    message: ChatMessage,
    mine: Boolean,
    selected: Boolean,
    onSelect: () -> Unit,
    onAsk: () -> Unit,
    onOrder: () -> Unit,
) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Card(
            onClick = onSelect,
            modifier = Modifier.fillMaxWidth(0.84f),
            colors = CardDefaults.cardColors(
                containerColor = if (mine) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
            ),
        ) {
            Column(
                Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                if (selected) Text("Selected", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                message.replyTo?.let {
                    Text(
                        "↪ ${if (it.isDeleted) "Message deleted" else it.body}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2,
                    )
                }

                if (message.isDeleted) {
                    Text("Message deleted", fontStyle = FontStyle.Italic, color = MaterialTheme.colorScheme.onSurfaceVariant)
                } else {
                    message.catalogCard?.let { card ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(card.businessName, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                                Text(card.title, fontWeight = FontWeight.Bold)
                                if (card.description.isNotBlank()) Text(card.description, style = MaterialTheme.typography.bodySmall)
                                val price = card.priceAmount?.let { "${card.currency} $it" } ?: "Ask price"
                                Text("$price · ${card.availability}", style = MaterialTheme.typography.bodySmall)
                                if (!mine) {
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        OutlinedButton(onClick = onAsk) { Text("Ask") }
                                        if (card.availability == "available") Button(onClick = onOrder) { Text("Order") }
                                    }
                                }
                            }
                        }
                    }

                    message.orderCard?.let { order ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                Text("ORDER", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                                Text(order.itemTitle, fontWeight = FontWeight.Bold)
                                Text("Qty ${order.quantity} · ${order.status.replace('_', ' ')}", style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }

                    if (message.body.isNotBlank()) Text(message.body)

                    message.attachments.forEach { attachment ->
                        MoshiMessageAttachment(accessToken = accessToken, attachment = attachment)
                    }

                    if (message.reactions.isNotEmpty()) {
                        Text(message.reactions.joinToString("  ") { "${it.emoji} ${it.count}" }, style = MaterialTheme.typography.labelSmall)
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    if (message.editedAt != null && !message.isDeleted) {
                        Text("edited", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Text(masterMessageTime(message.createdAt), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (mine) Text(message.state, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun MasterInitialAvatar(label: String, size: Int = 44) {
    Box(
        modifier = Modifier.size(size.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(label.take(1).uppercase(), fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary)
    }
}

@Composable
private fun MasterVoiceIconButton(
    enabled: Boolean,
    onReady: (File) -> Unit,
    onError: (String) -> Unit,
) {
    val context = LocalContext.current
    val recorder = remember { VoiceNoteRecorder(context.applicationContext) }
    var recording by remember { mutableStateOf(false) }

    fun start() {
        try {
            recorder.start()
            recording = true
        } catch (t: Throwable) {
            recorder.cancel()
            recording = false
            onError(t.message ?: "Could not start voice recording")
        }
    }

    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) start() else onError("Microphone permission is required for voice notes")
    }

    DisposableEffect(recorder) { onDispose { recorder.cancel() } }

    IconButton(
        onClick = {
            if (recording) {
                try {
                    val file = recorder.stop()
                    recording = false
                    onReady(file)
                } catch (t: Throwable) {
                    recorder.cancel()
                    recording = false
                    onError(t.message ?: "Could not save voice note")
                }
            } else {
                val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                if (granted) start() else permission.launch(Manifest.permission.RECORD_AUDIO)
            }
        },
        enabled = enabled || recording,
    ) {
        Icon(
            if (recording) Icons.Rounded.StopCircle else Icons.Rounded.Mic,
            contentDescription = if (recording) "Stop recording" else "Voice note",
            tint = if (recording) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface,
        )
    }
}

private fun masterReadAttachment(context: Context, uri: Uri, kind: String): MasterPickedAttachment {
    val resolver = context.contentResolver
    var displayName = "attachment"
    var size = -1L
    resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (nameIndex >= 0) displayName = cursor.getString(nameIndex) ?: displayName
            if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
        }
    }
    if (size < 0L) resolver.openAssetFileDescriptor(uri, "r")?.use { descriptor -> size = descriptor.length }
    if (size <= 0L) error("Attachment size could not be read")
    if (size > MASTER_MAX_ATTACHMENT_BYTES) error("Attachment exceeds 20 MB")
    val contentType = resolver.getType(uri) ?: if (kind == "image") "image/jpeg" else "application/octet-stream"
    return MasterPickedAttachment(kind, displayName.take(160), contentType, size, uri.toString())
}

private fun masterMessageTime(value: String): String = runCatching {
    DateTimeFormatter.ofPattern("HH:mm")
        .withZone(ZoneId.systemDefault())
        .format(Instant.parse(value))
}.getOrDefault("")

private fun masterChatListTime(value: String): String = runCatching {
    val instant = Instant.parse(value)
    val zone = ZoneId.systemDefault()
    val date = instant.atZone(zone).toLocalDate()
    val today = java.time.LocalDate.now(zone)
    if (date == today) DateTimeFormatter.ofPattern("HH:mm").withZone(zone).format(instant)
    else DateTimeFormatter.ofPattern("dd/MM").withZone(zone).format(instant)
}.getOrDefault("")
