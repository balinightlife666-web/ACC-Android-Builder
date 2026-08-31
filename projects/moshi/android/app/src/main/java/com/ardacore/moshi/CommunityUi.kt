package com.ardacore.moshi

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.ArrowBack
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.chat.ChatController
import com.ardacore.moshi.chat.ChatConversation
import com.ardacore.moshi.chat.GroupMember
import com.ardacore.moshi.chat.local.ChatLocalStore
import kotlinx.coroutines.launch

@Composable
fun CommunityHubScreen(session: AuthSession, modifier: Modifier = Modifier) {
    val context = LocalContext.current.applicationContext
    val controller = remember(session.accessToken) { ChatController(session, ChatLocalStore(context)) }
    LaunchedEffect(controller) { controller.start() }
    DisposableEffect(controller) { onDispose { controller.stop() } }

    val active = controller.activeConversation
    if (active?.kind == "group") {
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

    Column(modifier = modifier.fillMaxSize().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column {
                Text("Communities", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
                Text("Community spaces and channels", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            IconButton(onClick = { creating = !creating }) {
                Icon(Icons.Rounded.Add, contentDescription = "Create community")
            }
        }

        if (creating) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Create community", fontWeight = FontWeight.Bold)
                    OutlinedTextField(value = title, onValueChange = { title = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Community name") }, singleLine = true)
                    OutlinedTextField(value = members, onValueChange = { members = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Members: @user1, @user2") }, maxLines = 3)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(
                            onClick = {
                                val usernames = members.split(',', '\n', ' ').map { it.trim() }.filter { it.isNotBlank() }
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
                        TextButton(onClick = { creating = false }) { Text("Cancel") }
                    }
                }
            }
        }

        Text("YOUR COMMUNITIES", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)

        if (groups.isEmpty()) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("No communities yet", fontWeight = FontWeight.Bold)
                    Text("Create one or wait until you are added to a community.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(groups, key = { it.id }) { group ->
                    CommunityCard(group) { controller.openConversation(group) }
                }
            }
        }

        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
    }
}

@Composable
private fun CommunityCard(conversation: ChatConversation, onClick: () -> Unit) {
    val group = conversation.group ?: return
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
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
                    Text("general", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text("${group.memberCount} members · ${group.myRole}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (conversation.unreadCount > 0) {
                Text("${conversation.unreadCount}", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun CommunityConversationScreen(controller: ChatController, session: AuthSession, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    val conversation = controller.activeConversation ?: return
    var message by remember(conversation.id) { mutableStateOf("") }
    var membersVisible by remember(conversation.id) { mutableStateOf(false) }

    Column(modifier = modifier.fillMaxSize().padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = controller::closeConversation) { Icon(Icons.Rounded.ArrowBack, contentDescription = "Back") }
            Column(modifier = Modifier.weight(1f)) {
                Text(conversation.group?.title ?: "Community", fontWeight = FontWeight.Bold)
                Text("# general", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            OutlinedButton(onClick = { membersVisible = !membersVisible }) {
                Text(if (membersVisible) "Chat" else "Members")
            }
        }

        if (membersVisible) {
            LazyColumn(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(controller.groupMembers, key = { it.user.id }) { member ->
                    CommunityMemberCard(controller, member, session.user.id)
                }
            }
        } else {
            LazyColumn(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                items(controller.messages, key = { it.id }) { item ->
                    val mine = item.senderId == session.user.id
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
                        Card(modifier = Modifier.fillMaxWidth(0.84f)) {
                            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                if (item.isDeleted) {
                                    Text("Message deleted", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                } else {
                                    if (item.body.isNotBlank()) Text(item.body)
                                    item.attachments.firstOrNull()?.let { attachment ->
                                        Text("Attachment · ${attachment.fileName}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
                                    }
                                }
                                Text(item.state, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            }
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = message, onValueChange = { message = it }, modifier = Modifier.weight(1f), placeholder = { Text("Message #general") }, maxLines = 4)
                Button(
                    onClick = {
                        val value = message
                        message = ""
                        scope.launch { controller.send(value) }
                    },
                    enabled = message.isNotBlank() && !controller.busy,
                ) { Text("Send") }
            }
        }

        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
    }
}

@Composable
private fun CommunityMemberCard(controller: ChatController, member: GroupMember, myUserId: String) {
    val scope = rememberCoroutineScope()
    val group = controller.activeConversation?.group ?: return
    val me = member.user.id == myUserId
    val canRemove = !me && when (group.myRole) {
        "admin" -> member.role != "admin"
        "moderator" -> member.role == "member"
        else -> false
    }

    Card(modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(modifier = Modifier.size(38.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape), contentAlignment = Alignment.Center) {
                Text(member.user.displayName.take(1).uppercase(), fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(member.user.displayName, fontWeight = FontWeight.SemiBold)
                Text("@${member.user.username} · ${member.role}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (me) {
                TextButton(onClick = { scope.launch { controller.removeGroupMember(member) } }, enabled = !controller.busy) { Text("Leave") }
            } else if (canRemove) {
                TextButton(onClick = { scope.launch { controller.removeGroupMember(member) } }, enabled = !controller.busy) { Text("Remove") }
            }
        }
    }
}
