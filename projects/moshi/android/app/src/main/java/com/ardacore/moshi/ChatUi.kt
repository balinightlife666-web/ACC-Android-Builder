package com.ardacore.moshi

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
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
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.auth.MoshiUser
import com.ardacore.moshi.chat.ChatAttachment
import com.ardacore.moshi.chat.ChatController
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.ChatMessage
import com.ardacore.moshi.chat.ChatUser
import com.ardacore.moshi.chat.GroupMember
import com.ardacore.moshi.chat.local.ChatLocalStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private const val MAX_ATTACHMENT_BYTES = 20 * 1024 * 1024

private data class PickedAttachmentData(
    val kind: String,
    val fileName: String,
    val contentType: String,
    val sizeBytes: Long,
    val uri: String,
)

@Composable
fun ChatHubScreen(session: AuthSession, modifier: Modifier = Modifier) {
    val context = LocalContext.current.applicationContext
    val controller = remember(session.accessToken) { ChatController(session, ChatLocalStore(context)) }
    LaunchedEffect(controller) { controller.start() }
    DisposableEffect(controller) { onDispose { controller.stop() } }
    if (controller.activeConversation != null) {
        ConversationScreen(controller, session.user, modifier)
    } else {
        ConversationListScreen(controller, modifier)
    }
}

@Composable
private fun ConversationListScreen(controller: ChatController, modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    var query by remember { mutableStateOf("") }
    var creatingGroup by remember { mutableStateOf(false) }
    var groupTitle by remember { mutableStateOf("") }
    var groupMembersText by remember { mutableStateOf("") }
    Column(modifier = modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("MOSHI", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Chats", style = MaterialTheme.typography.titleLarge)
            OutlinedButton(onClick = { creatingGroup = !creatingGroup }, enabled = !controller.busy) {
                Text(if (creatingGroup) "Close" else "New group")
            }
        }
        if (creatingGroup) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Create group", fontWeight = FontWeight.SemiBold)
                    OutlinedTextField(
                        value = groupTitle,
                        onValueChange = { groupTitle = it },
                        label = { Text("Group name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    OutlinedTextField(
                        value = groupMembersText,
                        onValueChange = { groupMembersText = it },
                        label = { Text("Members: @user1, @user2") },
                        modifier = Modifier.fillMaxWidth(),
                        maxLines = 3,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(
                            onClick = {
                                val members = groupMembersText
                                    .split(',', '\n', ' ')
                                    .map { it.trim() }
                                    .filter { it.isNotBlank() }
                                scope.launch {
                                    controller.createGroup(groupTitle, members)
                                    if (controller.error == null) {
                                        groupTitle = ""
                                        groupMembersText = ""
                                        creatingGroup = false
                                    }
                                }
                            },
                            enabled = groupTitle.isNotBlank() && !controller.busy,
                        ) { Text("Create") }
                        TextButton(onClick = { creatingGroup = false; groupTitle = ""; groupMembersText = "" }) { Text("Cancel") }
                    }
                }
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                modifier = Modifier.weight(1f),
                label = { Text("Find @username") },
                singleLine = true,
            )
            Button(onClick = { scope.launch { controller.search(query) } }, enabled = query.isNotBlank() && !controller.busy) {
                Text("Find")
            }
        }
        controller.error?.let {
            Text(it, color = MaterialTheme.colorScheme.error)
            Row {
                TextButton(onClick = { scope.launch { controller.loadConversations() } }) { Text("Retry") }
                TextButton(onClick = controller::clearError) { Text("Dismiss") }
            }
        }
        if (controller.searchResults.isNotEmpty()) {
            Text("People", fontWeight = FontWeight.SemiBold)
            controller.searchResults.forEach { user ->
                UserResultCard(user) { scope.launch { controller.startDirect(user) } }
            }
            HorizontalDivider()
        }
        if (controller.conversations.isEmpty()) {
            Text("No conversations yet. Find someone by username or create a group.")
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(controller.conversations, key = { it.id }) { conversation ->
                    ConversationCard(conversation) { scope.launch { controller.openConversation(conversation) } }
                }
            }
        }
    }
}

@Composable
private fun UserResultCard(user: ChatUser, onClick: () -> Unit) {
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp)) {
            Text(user.displayName, fontWeight = FontWeight.SemiBold)
            Text("@${user.username}")
            if (user.businessMode) Text("Business", style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun ConversationCard(conversation: ChatConversation, onClick: () -> Unit) {
    val latest = conversation.latestMessage
    val firstAttachment = latest?.attachments?.firstOrNull()
    val latestText = when {
        latest == null && conversation.group != null -> "${conversation.group.memberCount} members"
        latest == null -> "Start talking"
        latest.isDeleted -> "Message deleted"
        latest.body.isNotBlank() -> latest.body
        firstAttachment?.contentType?.startsWith("audio/") == true -> "🎤 Voice note"
        firstAttachment != null -> "📎 ${firstAttachment.fileName}"
        else -> "Message"
    }
    val title = conversation.group?.title ?: conversation.peer?.displayName ?: "MOSHI chat"
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(latestText, maxLines = 1, style = MaterialTheme.typography.bodyMedium)
            }
            if (conversation.unreadCount > 0) {
                Spacer(Modifier.width(8.dp))
                Text("${conversation.unreadCount}", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun ConversationScreen(controller: ChatController, me: MoshiUser, modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val conversation = controller.activeConversation ?: return
    var messageText by remember(conversation.id) { mutableStateOf("") }
    var selectedId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var replyToId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var editingId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var attachmentBusy by remember(conversation.id) { mutableStateOf(false) }
    var attachmentError by remember(conversation.id) { mutableStateOf<String?>(null) }
    var showMembers by remember(conversation.id) { mutableStateOf(false) }
    val selected = controller.messages.firstOrNull { it.id == selectedId }
    val replyingTo = controller.messages.firstOrNull { it.id == replyToId }
    val editing = controller.messages.firstOrNull { it.id == editingId }
    val hasQueued = controller.messages.any { it.state == "queued" }

    fun sendPicked(uri: Uri, kind: String) {
        attachmentBusy = true
        attachmentError = null
        val body = messageText
        val replyId = replyToId
        scope.launch {
            try {
                runCatching {
                    context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                val picked = withContext(Dispatchers.IO) { readPickedAttachmentMetadata(context, uri, kind) }
                controller.sendAttachment(
                    body = body,
                    replyToId = replyId,
                    kind = picked.kind,
                    fileName = picked.fileName,
                    contentType = picked.contentType,
                    sizeBytes = picked.sizeBytes,
                    uri = picked.uri,
                )
                if (controller.error == null || controller.error?.contains("queued", ignoreCase = true) == true) {
                    messageText = ""
                    replyToId = null
                }
            } catch (t: Throwable) {
                attachmentError = t.message ?: "Could not queue attachment"
            } finally {
                attachmentBusy = false
            }
        }
    }

    fun sendVoiceNote(fileUri: Uri, fileName: String, sizeBytes: Long) {
        if (sizeBytes <= 0L || sizeBytes > MAX_ATTACHMENT_BYTES) {
            attachmentError = "Voice note size is invalid"
            return
        }
        attachmentBusy = true
        attachmentError = null
        val body = messageText
        val replyId = replyToId
        scope.launch {
            try {
                controller.sendAttachment(
                    body = body,
                    replyToId = replyId,
                    kind = "file",
                    fileName = fileName,
                    contentType = "audio/mp4",
                    sizeBytes = sizeBytes,
                    uri = fileUri.toString(),
                )
                if (controller.error == null || controller.error?.contains("queued", ignoreCase = true) == true) {
                    messageText = ""
                    replyToId = null
                }
            } catch (t: Throwable) {
                attachmentError = t.message ?: "Could not queue voice note"
            } finally {
                attachmentBusy = false
            }
        }
    }

    fun openAttachment(attachment: ChatAttachment) {
        if (attachment.downloadPath.isBlank() || attachment.status != "ready") return
        attachmentBusy = true
        attachmentError = null
        scope.launch {
            try {
                val bytes = controller.downloadAttachment(attachment) ?: return@launch
                withContext(Dispatchers.IO) {
                    openDownloadedAttachment(context.applicationContext, attachment, bytes)
                }
            } catch (t: Throwable) {
                attachmentError = t.message ?: "Could not open attachment"
            } finally {
                attachmentBusy = false
            }
        }
    }

    val photoPicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) sendPicked(uri, "image")
    }
    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) sendPicked(uri, "file")
    }

    Column(modifier = modifier.fillMaxSize().padding(12.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedButton(onClick = controller::closeConversation) { Text("Back") }
            Column(modifier = Modifier.weight(1f)) {
                Text(conversation.group?.title ?: conversation.peer?.displayName ?: "Chat", fontWeight = FontWeight.Bold)
                if (conversation.group != null) {
                    Text(
                        "${conversation.group.memberCount} members · ${conversation.group.myRole}",
                        style = MaterialTheme.typography.bodySmall,
                    )
                } else {
                    conversation.peer?.let { Text("@${it.username}", style = MaterialTheme.typography.bodySmall) }
                }
            }
            if (conversation.group != null) {
                OutlinedButton(onClick = { showMembers = !showMembers }) {
                    Text(if (showMembers) "Chat" else "Members")
                }
            }
        }
        HorizontalDivider(Modifier.padding(vertical = 8.dp))

        if (conversation.group != null && showMembers) {
            GroupMembersPanel(controller = controller, me = me)
            HorizontalDivider(Modifier.padding(vertical = 8.dp))
        }

        LazyColumn(modifier = Modifier.weight(1f).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(controller.messages, key = { it.id }) { item ->
                val mine = item.senderId == me.id
                val senderLabel = if (conversation.group != null && !mine) {
                    controller.groupMembers.firstOrNull { it.user.id == item.senderId }?.user?.displayName
                } else null
                MessageBubble(
                    message = item,
                    mine = mine,
                    senderLabel = senderLabel,
                    selected = selectedId == item.id,
                    onSelect = { selectedId = if (selectedId == item.id) null else item.id },
                    onOpenAttachment = ::openAttachment,
                )
            }
        }

        if (selected != null) {
            MessageActionBar(
                message = selected,
                mine = selected.senderId == me.id,
                enabled = !controller.busy && !attachmentBusy && !selected.id.startsWith("local:"),
                onReply = {
                    replyToId = selected.id
                    editingId = null
                    selectedId = null
                    messageText = ""
                },
                onReact = { emoji -> scope.launch { controller.toggleReaction(selected, emoji) } },
                onEdit = {
                    editingId = selected.id
                    replyToId = null
                    selectedId = null
                    messageText = selected.body
                },
                onDelete = {
                    selectedId = null
                    scope.launch { controller.delete(selected) }
                },
                onCancel = { selectedId = null },
            )
        }

        replyingTo?.let {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Replying to: ${if (it.isDeleted) "Message deleted" else it.body}",
                    maxLines = 1,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.bodySmall,
                )
                TextButton(onClick = { replyToId = null }) { Text("Cancel") }
            }
        }
        editing?.let {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("Editing message", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold)
                TextButton(onClick = { editingId = null; messageText = "" }) { Text("Cancel") }
            }
        }

        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        attachmentError?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        if (hasQueued) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("Queued messages/files/voice notes are saved on this device.", style = MaterialTheme.typography.bodySmall)
                TextButton(onClick = { scope.launch { controller.retryPending() } }, enabled = !controller.busy && !attachmentBusy) {
                    Text("Retry now")
                }
            }
        }
        if (attachmentBusy) Text("Working with attachment…", style = MaterialTheme.typography.bodySmall)

        if (editing == null) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                VoiceNoteButton(
                    enabled = !controller.busy && !attachmentBusy,
                    onReady = { file -> sendVoiceNote(Uri.fromFile(file), file.name, file.length()) },
                    onError = { message -> attachmentError = message },
                )
                OutlinedButton(
                    onClick = { photoPicker.launch(arrayOf("image/jpeg", "image/png", "image/webp", "image/gif")) },
                    enabled = !controller.busy && !attachmentBusy,
                ) { Text("Photo") }
                OutlinedButton(
                    onClick = {
                        filePicker.launch(
                            arrayOf(
                                "application/pdf",
                                "text/plain",
                                "application/zip",
                                "application/msword",
                                "application/vnd.ms-excel",
                                "application/vnd.ms-powerpoint",
                                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                            )
                        )
                    },
                    enabled = !controller.busy && !attachmentBusy,
                ) { Text("File") }
            }
            Text("Voice max 5 min · attachments max 20 MB", style = MaterialTheme.typography.labelSmall)
        }

        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedTextField(
                value = messageText,
                onValueChange = { messageText = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text(if (editing != null) "Edit message" else "Message") },
                maxLines = 4,
            )
            Button(
                onClick = {
                    val body = messageText
                    messageText = ""
                    if (editing != null) {
                        editingId = null
                        scope.launch { controller.edit(editing, body) }
                    } else {
                        val replyId = replyToId
                        replyToId = null
                        scope.launch { controller.send(body, replyId) }
                    }
                },
                enabled = messageText.isNotBlank() && !controller.busy && !attachmentBusy,
            ) { Text(if (editing != null) "Save" else "Send") }
        }
    }
}

@Composable
private fun GroupMembersPanel(controller: ChatController, me: MoshiUser) {
    val scope = rememberCoroutineScope()
    val group = controller.activeConversation?.group ?: return
    var username by remember(controller.activeConversation?.id) { mutableStateOf("") }
    val canAdd = group.myRole == "admin" || group.myRole == "moderator"

    Column(modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("Group members", fontWeight = FontWeight.SemiBold)
        if (canAdd) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it },
                    label = { Text("Add @username") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                )
                Button(
                    onClick = {
                        val value = username
                        scope.launch {
                            controller.addGroupMember(value)
                            if (controller.error == null) username = ""
                        }
                    },
                    enabled = username.isNotBlank() && !controller.busy,
                ) { Text("Add") }
            }
        }
        controller.groupMembers.forEach { member ->
            GroupMemberRow(
                member = member,
                me = me,
                actorRole = group.myRole,
                busy = controller.busy,
                onRole = { role -> scope.launch { controller.setGroupRole(member, role) } },
                onRemove = { scope.launch { controller.removeGroupMember(member) } },
            )
        }
    }
}

@Composable
private fun GroupMemberRow(
    member: GroupMember,
    me: MoshiUser,
    actorRole: String,
    busy: Boolean,
    onRole: (String) -> Unit,
    onRemove: () -> Unit,
) {
    val isMe = member.user.id == me.id
    val canRemoveOther = when (actorRole) {
        "admin" -> member.role != "admin"
        "moderator" -> member.role == "member"
        else -> false
    }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(member.user.displayName, fontWeight = FontWeight.SemiBold)
                    Text("@${member.user.username} · ${member.role}", style = MaterialTheme.typography.bodySmall)
                }
                if (isMe) {
                    TextButton(onClick = onRemove, enabled = !busy) { Text("Leave") }
                } else if (canRemoveOther) {
                    TextButton(onClick = onRemove, enabled = !busy) { Text("Remove") }
                }
            }
            if (actorRole == "admin") {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    TextButton(onClick = { onRole("member") }, enabled = !busy && member.role != "member") { Text("Member") }
                    TextButton(onClick = { onRole("moderator") }, enabled = !busy && member.role != "moderator") { Text("Moderator") }
                    TextButton(onClick = { onRole("admin") }, enabled = !busy && member.role != "admin") { Text("Admin") }
                }
            }
        }
    }
}

@Composable
private fun MessageActionBar(
    message: ChatMessage,
    mine: Boolean,
    enabled: Boolean,
    onReply: () -> Unit,
    onReact: (String) -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onCancel: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        HorizontalDivider()
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly, verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onReply, enabled = enabled) { Text("Reply") }
            TextButton(onClick = { onReact("👍") }, enabled = enabled && !message.isDeleted) { Text("👍") }
            TextButton(onClick = { onReact("❤️") }, enabled = enabled && !message.isDeleted) { Text("❤️") }
            TextButton(onClick = { onReact("😂") }, enabled = enabled && !message.isDeleted) { Text("😂") }
            TextButton(onClick = onCancel) { Text("Close") }
        }
        if (mine && !message.isDeleted) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(onClick = onEdit, enabled = enabled) { Text("Edit") }
                TextButton(onClick = onDelete, enabled = enabled) { Text("Delete") }
            }
        }
    }
}

@Composable
private fun MessageBubble(
    message: ChatMessage,
    mine: Boolean,
    senderLabel: String?,
    selected: Boolean,
    onSelect: () -> Unit,
    onOpenAttachment: (ChatAttachment) -> Unit,
) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Card(onClick = onSelect, modifier = Modifier.fillMaxWidth(0.78f)) {
            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                if (senderLabel != null) Text(senderLabel, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
                if (selected) Text("Selected", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.SemiBold)
                message.replyTo?.let { reply ->
                    Text("↪ ${if (reply.isDeleted) "Message deleted" else reply.body}", style = MaterialTheme.typography.bodySmall, maxLines = 2)
                    HorizontalDivider()
                }
                if (message.isDeleted) {
                    Text("Message deleted", fontStyle = FontStyle.Italic)
                } else {
                    if (message.body.isNotBlank()) Text(message.body)
                    message.attachments.forEach { attachment ->
                        val isVoice = attachment.contentType.startsWith("audio/")
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(8.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(
                                    when {
                                        isVoice -> "🎤 Voice note"
                                        attachment.kind == "image" -> "Photo"
                                        else -> "File"
                                    },
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.SemiBold,
                                )
                                if (!isVoice) Text(attachment.fileName, fontWeight = FontWeight.Medium)
                                Text(formatBytes(attachment.sizeBytes), style = MaterialTheme.typography.labelSmall)
                                if (attachment.status == "ready" && attachment.downloadPath.isNotBlank()) {
                                    TextButton(onClick = { onOpenAttachment(attachment) }) { Text(if (isVoice) "Play" else "Open") }
                                } else {
                                    Text(attachment.status.replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.labelSmall)
                                }
                            }
                        }
                    }
                }
                if (message.reactions.isNotEmpty()) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        message.reactions.forEach { reaction ->
                            Text(
                                "${reaction.emoji} ${reaction.count}",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = if (reaction.reactedByMe) FontWeight.Bold else FontWeight.Normal,
                            )
                        }
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (message.editedAt != null && !message.isDeleted) Text("edited", style = MaterialTheme.typography.labelSmall)
                    if (mine) Text(message.state, style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}

private fun readPickedAttachmentMetadata(context: Context, uri: Uri, kind: String): PickedAttachmentData {
    val resolver = context.contentResolver
    var fileName = if (kind == "image") "photo" else "file"
    var declaredSize: Long? = null
    resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (nameIndex >= 0 && !cursor.isNull(nameIndex)) fileName = cursor.getString(nameIndex)
            if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) declaredSize = cursor.getLong(sizeIndex)
        }
    }
    val contentType = resolver.getType(uri)?.lowercase() ?: error("Unknown attachment type")
    val actualSize = declaredSize?.takeIf { it > 0 } ?: resolver.openInputStream(uri)?.use { input ->
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            total += count
            if (total > MAX_ATTACHMENT_BYTES) error("Attachment is larger than 20 MB")
        }
        total
    } ?: error("Could not inspect attachment")
    if (actualSize <= 0) error("Attachment is empty")
    if (actualSize > MAX_ATTACHMENT_BYTES) error("Attachment is larger than 20 MB")
    return PickedAttachmentData(
        kind = kind,
        fileName = fileName,
        contentType = contentType,
        sizeBytes = actualSize,
        uri = uri.toString(),
    )
}

private fun formatBytes(size: Long): String = when {
    size >= 1024L * 1024L -> String.format("%.1f MB", size / (1024.0 * 1024.0))
    size >= 1024L -> String.format("%.1f KB", size / 1024.0)
    else -> "$size B"
}
