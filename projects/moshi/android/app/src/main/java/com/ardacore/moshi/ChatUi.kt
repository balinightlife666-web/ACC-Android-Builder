package com.ardacore.moshi

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
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.auth.MoshiUser
import com.ardacore.moshi.chat.ChatController
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.ChatMessage
import com.ardacore.moshi.chat.ChatUser
import kotlinx.coroutines.launch

@Composable
fun ChatHubScreen(session: AuthSession, modifier: Modifier = Modifier) {
    val controller = remember(session.accessToken) { ChatController(session) }
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
    Column(modifier = modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("MOSHI", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        Text("Chats", style = MaterialTheme.typography.titleLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(value = query, onValueChange = { query = it }, modifier = Modifier.weight(1f), label = { Text("Find @username") }, singleLine = true)
            Button(onClick = { scope.launch { controller.search(query) } }, enabled = query.isNotBlank() && !controller.busy) { Text("Find") }
        }
        controller.error?.let {
            Text(it, color = MaterialTheme.colorScheme.error)
            TextButton(onClick = controller::clearError) { Text("Dismiss") }
        }
        if (controller.searchResults.isNotEmpty()) {
            Text("People", fontWeight = FontWeight.SemiBold)
            controller.searchResults.forEach { user -> UserResultCard(user) { scope.launch { controller.startDirect(user) } } }
            HorizontalDivider()
        }
        if (controller.conversations.isEmpty()) {
            Text("No conversations yet. Find someone by username to start a MOSHI chat.")
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
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(modifier = Modifier.fillMaxWidth().padding(14.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(conversation.peer?.displayName ?: "MOSHI chat", fontWeight = FontWeight.SemiBold)
                Text(
                    when {
                        latest == null -> "Start talking"
                        latest.isDeleted -> "Message deleted"
                        else -> latest.body
                    },
                    maxLines = 1,
                    style = MaterialTheme.typography.bodyMedium,
                )
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
    val conversation = controller.activeConversation ?: return
    var messageText by remember(conversation.id) { mutableStateOf("") }
    var selectedId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var replyToId by remember(conversation.id) { mutableStateOf<String?>(null) }
    var editingId by remember(conversation.id) { mutableStateOf<String?>(null) }
    val selected = controller.messages.firstOrNull { it.id == selectedId }
    val replyingTo = controller.messages.firstOrNull { it.id == replyToId }
    val editing = controller.messages.firstOrNull { it.id == editingId }

    Column(modifier = modifier.fillMaxSize().padding(12.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = controller::closeConversation) { Text("Back") }
            Column {
                Text(conversation.peer?.displayName ?: "Chat", fontWeight = FontWeight.Bold)
                conversation.peer?.let { Text("@${it.username}", style = MaterialTheme.typography.bodySmall) }
            }
        }
        HorizontalDivider(Modifier.padding(vertical = 8.dp))
        LazyColumn(modifier = Modifier.weight(1f).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(controller.messages, key = { it.id }) { item ->
                MessageBubble(
                    message = item,
                    mine = item.senderId == me.id,
                    selected = selectedId == item.id,
                    onSelect = { selectedId = if (selectedId == item.id) null else item.id },
                )
            }
        }

        if (selected != null) {
            MessageActionBar(
                message = selected,
                mine = selected.senderId == me.id,
                enabled = !controller.busy,
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
                Text("Replying to: ${if (it.isDeleted) "Message deleted" else it.body}", maxLines = 1, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodySmall)
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
        Row(modifier = Modifier.fillMaxWidth().padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            OutlinedTextField(value = messageText, onValueChange = { messageText = it }, modifier = Modifier.weight(1f), placeholder = { Text(if (editing != null) "Edit message" else "Message") }, maxLines = 4)
            Button(onClick = {
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
            }, enabled = messageText.isNotBlank() && !controller.busy) { Text(if (editing != null) "Save" else "Send") }
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
private fun MessageBubble(message: ChatMessage, mine: Boolean, selected: Boolean, onSelect: () -> Unit) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Card(onClick = onSelect, modifier = Modifier.fillMaxWidth(0.78f)) {
            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                if (selected) Text("Selected", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.SemiBold)
                message.replyTo?.let { reply ->
                    Text(
                        "↪ ${if (reply.isDeleted) "Message deleted" else reply.body}",
                        style = MaterialTheme.typography.bodySmall,
                        maxLines = 2,
                    )
                    HorizontalDivider()
                }
                if (message.isDeleted) {
                    Text("Message deleted", fontStyle = FontStyle.Italic)
                } else {
                    Text(message.body)
                }
                if (message.reactions.isNotEmpty()) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        message.reactions.forEach { reaction ->
                            Text("${reaction.emoji} ${reaction.count}", style = MaterialTheme.typography.labelMedium, fontWeight = if (reaction.reactedByMe) FontWeight.Bold else FontWeight.Normal)
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
