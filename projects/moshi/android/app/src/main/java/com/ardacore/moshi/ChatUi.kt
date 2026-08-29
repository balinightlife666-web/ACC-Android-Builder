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
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(modifier = Modifier.fillMaxWidth().padding(14.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(conversation.peer?.displayName ?: "MOSHI chat", fontWeight = FontWeight.SemiBold)
                Text(conversation.latestMessage?.body ?: "Start talking", maxLines = 1, style = MaterialTheme.typography.bodyMedium)
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
            items(controller.messages, key = { it.id }) { item -> MessageBubble(item, item.senderId == me.id) }
        }
        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        Row(modifier = Modifier.fillMaxWidth().padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            OutlinedTextField(value = messageText, onValueChange = { messageText = it }, modifier = Modifier.weight(1f), placeholder = { Text("Message") }, maxLines = 4)
            Button(onClick = {
                val body = messageText
                messageText = ""
                scope.launch { controller.send(body) }
            }, enabled = messageText.isNotBlank() && !controller.busy) { Text("Send") }
        }
    }
}

@Composable
private fun MessageBubble(message: ChatMessage, mine: Boolean) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Card(modifier = Modifier.fillMaxWidth(0.78f)) {
            Column(Modifier.padding(10.dp)) {
                Text(message.body)
                if (mine) Text(message.state, style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}
