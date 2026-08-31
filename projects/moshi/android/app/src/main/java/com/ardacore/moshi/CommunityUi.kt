package com.ardacore.moshi

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material.icons.rounded.AttachFile
import androidx.compose.material.icons.rounded.Group
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.Mic
import androidx.compose.material.icons.rounded.Send
import androidx.compose.material.icons.rounded.StopCircle
import androidx.compose.material.icons.rounded.Tag
import androidx.compose.material3.Button
import androidx.compose.material3.Card
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
import com.ardacore.moshi.chat.ChatAttachment
import com.ardacore.moshi.chat.ChatController
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.ChatMessage
import com.ardacore.moshi.chat.GroupMember
import com.ardacore.moshi.chat.local.ChatLocalStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

private const val COMMUNITY_MAX_ATTACHMENT_BYTES = 20L * 1024L * 1024L

private data class CommunityPickedAttachment(
    val kind: String,
    val name: String,
    val contentType: String,
    val size: Long,
    val uri: String,
)

@Composable
fun CommunityHubScreen(
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

    val inCommunity = controller.activeConversation?.kind == "group"
    LaunchedEffect(inCommunity) { onImmersiveChanged(inCommunity) }

    if (inCommunity) {
        CommunityConversationScreen(controller, session, modifier)
    } else {
        CommunityListScreen(controller, modifier)
    }
}

@Composable
private fun CommunityListScreen(controller: ChatController, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    var creating by remember { mutableStateOf(false) }
    var title by remember { mutableStateOf("") }
    var members by remember { mutableStateOf("") }
    val groups = controller.conversations.filter { it.kind == "group" }

    Column(
        modifier = modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text("Communities", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
                Text("Shared spaces and channels", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            IconButton(onClick = { creating = !creating }) {
                Icon(Icons.Rounded.Add, contentDescription = "Create community")
            }
        }

        if (creating) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Create community", fontWeight = FontWeight.Bold)
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Community name") },
                        singleLine = true,
                    )
                    OutlinedTextField(
                        value = members,
                        onValueChange = { members = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Members: @user1, @user2") },
                        maxLines = 3,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(
                            onClick = {
                                val usernames = members
                                    .split(',', '\n', ' ')
                                    .map { it.trim() }
                                    .filter { it.isNotBlank() }
                                scope.launch {
                                    controller.createGroup(title, usernames)
                                    if (controller.error == null) {
                                        title = ""
                                        members = ""
                                        creating = false
                                    }
                                }
                            },
                            enabled = title.isNotBlank() && !controller.busy,
                        ) { Text("Create") }
                        TextButton(onClick = { creating = false; title = ""; members = "" }) { Text("Cancel") }
                    }
                }
            }
        }

        if (groups.isEmpty()) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("No communities yet", fontWeight = FontWeight.Bold)
                    Text("Create one or wait until you are added to a community.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(groups, key = { it.id }) { group ->
                    CommunityCard(group) { controller.openConversation(group) }
                }
            }
        }

        controller.error?.let {
            Card(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(it, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                    TextButton(onClick = { scope.launch { controller.loadConversations() } }) { Text("Retry") }
                    TextButton(onClick = controller::clearError) { Text("Dismiss") }
                }
            }
        }
    }
}

@Composable
private fun CommunityCard(conversation: ChatConversation, onClick: () -> Unit) {
    val group = conversation.group ?: return
    val latest = conversation.latestMessage
    val preview = when {
        latest == null -> "# general"
        latest.isDeleted -> "Message deleted"
        latest.body.isNotBlank() -> latest.body
        latest.attachments.firstOrNull()?.contentType?.startsWith("audio/") == true -> "Voice note"
        latest.attachments.isNotEmpty() -> "Attachment · ${latest.attachments.first().fileName}"
        else -> "# general"
    }

    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box(
                modifier = Modifier.size(48.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text(group.title.take(1).uppercase(), fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary)
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(group.title, fontWeight = FontWeight.Bold)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(Icons.Rounded.Tag, contentDescription = null, modifier = Modifier.size(14.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(preview, maxLines = 1, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text("${group.memberCount} members · ${group.myRole}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (conversation.unreadCount > 0) {
                Box(
                    modifier = Modifier.size(26.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("${conversation.unreadCount}", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary)
                }
            }
        }
    }
}

@Composable
private fun CommunityConversationScreen(controller: ChatController, session: AuthSession, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val conversation = controller.activeConversation ?: return
    val group = conversation.group ?: return
    val listState = rememberLazyListState()
    var message by remember(conversation.id) { mutableStateOf("") }
    var membersVisible by remember(conversation.id) { mutableStateOf(false) }
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
        if (!membersVisible && controller.messages.isNotEmpty()) {
            androidx.compose.runtime.withFrameNanos { }
            listState.scrollToItem(controller.messages.lastIndex)
        }
    }

    fun queuePicked(uri: Uri, kind: String) {
        attachmentBusy = true
        localError = null
        val body = message
        val replyTo = replyId
        scope.launch {
            try {
                runCatching { context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
                val picked = withContext(Dispatchers.IO) { communityReadAttachment(context, uri, kind) }
                controller.sendAttachment(body, replyTo, picked.kind, picked.name, picked.contentType, picked.size, picked.uri)
                if (controller.error == null || controller.error?.contains("queued", ignoreCase = true) == true) {
                    message = ""
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
        if (!file.isFile || file.length() <= 0L || file.length() > COMMUNITY_MAX_ATTACHMENT_BYTES) {
            localError = "Voice note is invalid"
            return
        }
        attachmentBusy = true
        localError = null
        val body = message
        val replyTo = replyId
        scope.launch {
            try {
                controller.sendAttachment(body, replyTo, "file", file.name, "audio/mp4", file.length(), Uri.fromFile(file).toString())
                if (controller.error == null || controller.error?.contains("queued", ignoreCase = true) == true) {
                    message = ""
                    replyId = null
                }
            } catch (t: Throwable) {
                localError = t.message ?: "Could not queue voice note"
            } finally {
                attachmentBusy = false
            }
        }
    }

    fun openAttachment(attachment: ChatAttachment) {
        if (attachment.status != "ready" || attachment.downloadPath.isBlank()) return
        attachmentBusy = true
        localError = null
        scope.launch {
            try {
                val bytes = controller.downloadAttachment(attachment) ?: return@launch
                withContext(Dispatchers.IO) { openDownloadedAttachment(context.applicationContext, attachment, bytes) }
            } catch (t: Throwable) {
                localError = t.message ?: "Could not open attachment"
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
            Box(
                modifier = Modifier.size(40.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text(group.title.take(1).uppercase(), fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary)
            }
            Column(modifier = Modifier.weight(1f).padding(start = 8.dp)) {
                Text(group.title, fontWeight = FontWeight.Bold)
                Text("# general · ${group.memberCount} members", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            IconButton(onClick = { membersVisible = !membersVisible }) {
                Icon(Icons.Rounded.Group, contentDescription = if (membersVisible) "Back to channel" else "Members")
            }
        }

        if (membersVisible) {
            CommunityMembersPanel(controller, session.user.id, Modifier.weight(1f))
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f).fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                items(controller.messages, key = { it.id }) { item ->
                    CommunityMessageBubble(
                        message = item,
                        mine = item.senderId == session.user.id,
                        senderLabel = controller.groupMembers.firstOrNull { it.user.id == item.senderId }?.user?.displayName,
                        selected = selectedId == item.id,
                        onSelect = { selectedId = if (selectedId == item.id) null else item.id },
                        onOpenAttachment = ::openAttachment,
                    )
                }
            }

            if (selected != null) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    TextButton(onClick = { replyId = selected.id; editingId = null; selectedId = null; message = "" }) { Text("Reply") }
                    TextButton(onClick = { scope.launch { controller.toggleReaction(selected, "👍") } }) { Text("👍") }
                    TextButton(onClick = { scope.launch { controller.toggleReaction(selected, "❤️") } }) { Text("❤️") }
                    TextButton(onClick = { scope.launch { controller.toggleReaction(selected, "😂") } }) { Text("😂") }
                    if (selected.senderId == session.user.id && !selected.isDeleted && !selected.id.startsWith("local:")) {
                        TextButton(onClick = { editingId = selected.id; replyId = null; message = selected.body; selectedId = null }) { Text("Edit") }
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
                    TextButton(onClick = { editingId = null; message = "" }) { Text("Cancel") }
                }
            }

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

                CommunityVoiceButton(
                    enabled = !controller.busy && !attachmentBusy && editing == null,
                    onReady = ::queueVoice,
                    onError = { localError = it },
                )

                OutlinedTextField(
                    value = message,
                    onValueChange = { message = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text(if (editing != null) "Edit message" else "Message #general") },
                    maxLines = 4,
                )

                IconButton(
                    onClick = {
                        val value = message
                        message = ""
                        if (editing != null) {
                            editingId = null
                            scope.launch { controller.edit(editing, value) }
                        } else {
                            val replyTo = replyId
                            replyId = null
                            scope.launch { controller.send(value, replyTo) }
                        }
                    },
                    enabled = message.isNotBlank() && !controller.busy && !attachmentBusy,
                ) { Icon(Icons.Rounded.Send, contentDescription = if (editing != null) "Save" else "Send") }
            }
        }

        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }
        localError?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }
    }
}

@Composable
private fun CommunityMembersPanel(controller: ChatController, myUserId: String, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    val group = controller.activeConversation?.group ?: return
    var username by remember(controller.activeConversation?.id) { mutableStateOf("") }
    val canAdd = group.myRole == "admin" || group.myRole == "moderator"

    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column {
                Text("Members", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Text("Your role: ${group.myRole}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        if (canAdd) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it },
                    modifier = Modifier.weight(1f),
                    label = { Text("Add @username") },
                    singleLine = true,
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

        LazyColumn(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            items(controller.groupMembers, key = { it.user.id }) { member ->
                CommunityMemberCard(
                    controller = controller,
                    member = member,
                    myUserId = myUserId,
                    actorRole = group.myRole,
                )
            }
        }
    }
}

@Composable
private fun CommunityMemberCard(
    controller: ChatController,
    member: GroupMember,
    myUserId: String,
    actorRole: String,
) {
    val scope = rememberCoroutineScope()
    val isMe = member.user.id == myUserId
    val canRemoveOther = when (actorRole) {
        "admin" -> member.role != "admin"
        "moderator" -> member.role == "member"
        else -> false
    }

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(
                    modifier = Modifier.size(38.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(member.user.displayName.take(1).uppercase(), fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(member.user.displayName, fontWeight = FontWeight.SemiBold)
                    Text("@${member.user.username} · ${member.role}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (isMe) {
                    TextButton(onClick = { scope.launch { controller.removeGroupMember(member) } }, enabled = !controller.busy) { Text("Leave") }
                } else if (canRemoveOther) {
                    TextButton(onClick = { scope.launch { controller.removeGroupMember(member) } }, enabled = !controller.busy) { Text("Remove") }
                }
            }

            if (actorRole == "admin" && !isMe) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    TextButton(
                        onClick = { scope.launch { controller.setGroupRole(member, "member") } },
                        enabled = !controller.busy && member.role != "member",
                    ) { Text("Member") }
                    TextButton(
                        onClick = { scope.launch { controller.setGroupRole(member, "moderator") } },
                        enabled = !controller.busy && member.role != "moderator",
                    ) { Text("Moderator") }
                    TextButton(
                        onClick = { scope.launch { controller.setGroupRole(member, "admin") } },
                        enabled = !controller.busy && member.role != "admin",
                    ) { Text("Admin") }
                }
            }
        }
    }
}

@Composable
private fun CommunityMessageBubble(
    message: ChatMessage,
    mine: Boolean,
    senderLabel: String?,
    selected: Boolean,
    onSelect: () -> Unit,
    onOpenAttachment: (ChatAttachment) -> Unit,
) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Card(onClick = onSelect, modifier = Modifier.fillMaxWidth(0.86f)) {
            Column(
                Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                if (!mine && senderLabel != null) {
                    Text(senderLabel, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                }
                if (selected) Text("Selected", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                message.replyTo?.let {
                    Text(
                        "↪ ${if (it.isDeleted) "Message deleted" else it.body}",
                        maxLines = 2,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                if (message.isDeleted) {
                    Text("Message deleted", fontStyle = FontStyle.Italic, color = MaterialTheme.colorScheme.onSurfaceVariant)
                } else {
                    if (message.catalogCard != null) {
                        Text("Catalog · ${message.catalogCard.title}", fontWeight = FontWeight.Bold)
                        message.catalogCard.description.takeIf { it.isNotBlank() }?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
                    }
                    if (message.body.isNotBlank()) Text(message.body)
                    message.attachments.forEach { attachment ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 7.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                val isVoice = attachment.contentType.startsWith("audio/")
                                Text(if (isVoice) "Voice note" else attachment.fileName, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodySmall)
                                if (attachment.status == "ready" && attachment.downloadPath.isNotBlank()) {
                                    TextButton(onClick = { onOpenAttachment(attachment) }) { Text(if (isVoice) "Play" else "Open") }
                                } else {
                                    Text(attachment.status, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                    if (message.reactions.isNotEmpty()) {
                        Text(message.reactions.joinToString("  ") { "${it.emoji} ${it.count}" }, style = MaterialTheme.typography.labelSmall)
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (message.editedAt != null && !message.isDeleted) Text("edited", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (mine) Text(message.state, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun CommunityVoiceButton(
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

private fun communityReadAttachment(context: Context, uri: Uri, kind: String): CommunityPickedAttachment {
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
    if (size > COMMUNITY_MAX_ATTACHMENT_BYTES) error("Attachment exceeds 20 MB")
    val contentType = resolver.getType(uri) ?: if (kind == "image") "image/jpeg" else "application/octet-stream"
    return CommunityPickedAttachment(kind, displayName.take(160), contentType, size, uri.toString())
}
