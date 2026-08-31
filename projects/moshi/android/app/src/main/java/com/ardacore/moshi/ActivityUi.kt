package com.ardacore.moshi

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.ChatController
import com.ardacore.moshi.chat.local.ChatLocalStore

@Composable
fun ActivityHubScreen(session: AuthSession, modifier: Modifier = Modifier) {
    val context = LocalContext.current.applicationContext
    val controller = remember(session.accessToken) { ChatController(session, ChatLocalStore(context)) }
    LaunchedEffect(controller) { controller.start() }
    DisposableEffect(controller) { onDispose { controller.stop() } }

    val unread = controller.conversations.filter { it.unreadCount > 0 }
    val recent = controller.conversations
        .filter { it.latestMessage != null }
        .sortedByDescending { it.latestMessage?.createdAt ?: "" }
        .take(12)

    Column(modifier = modifier.fillMaxSize().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Activity", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
        Text("Important updates across MOSHI", color = MaterialTheme.colorScheme.onSurfaceVariant)

        if (unread.isNotEmpty()) {
            Text("NEEDS ATTENTION", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.weight(1f)) {
                items(unread, key = { "unread:${it.id}" }) { item -> ActivityCard(item, urgent = true) }
                if (recent.isNotEmpty()) {
                    item { Text("RECENT", modifier = Modifier.padding(top = 10.dp), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                    items(recent.filterNot { recentItem -> unread.any { it.id == recentItem.id } }, key = { "recent:${it.id}" }) { item -> ActivityCard(item, urgent = false) }
                }
            }
        } else if (recent.isNotEmpty()) {
            Text("RECENT", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.weight(1f)) {
                items(recent, key = { it.id }) { item -> ActivityCard(item, urgent = false) }
            }
        } else {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("All caught up", fontWeight = FontWeight.Bold)
                    Text("Mentions, unread conversations and business/order message updates will surface here as they arrive.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }

        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
    }
}

@Composable
private fun ActivityCard(conversation: ChatConversation, urgent: Boolean) {
    val latest = conversation.latestMessage
    val title = conversation.group?.title ?: conversation.peer?.displayName ?: "MOSHI"
    val text = when {
        latest?.orderCard != null -> "Order · ${latest.orderCard.itemTitle} · ${latest.orderCard.status.replace('_', ' ')}"
        latest?.catalogCard != null -> "Catalog · ${latest.catalogCard.title}"
        latest?.body?.isNotBlank() == true -> latest.body
        latest?.attachments?.isNotEmpty() == true -> "Attachment · ${latest.attachments.first().fileName}"
        else -> "New activity"
    }

    Card(modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(text, maxLines = 2, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (urgent) {
                Text("${conversation.unreadCount}", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Black)
            }
        }
    }
}
