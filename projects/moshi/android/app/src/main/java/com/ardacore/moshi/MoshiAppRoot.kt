package com.ardacore.moshi

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ChatBubble
import androidx.compose.material.icons.rounded.Groups
import androidx.compose.material.icons.rounded.Notifications
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Storefront
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthController
import kotlinx.coroutines.launch

@Composable
fun MoshiAppRoot() {
    val context = LocalContext.current
    val controller = remember { AuthController(context) }
    LaunchedEffect(Unit) { controller.restore() }
    when {
        controller.restoring -> LoadingScreen()
        controller.session == null -> AuthScreen(controller)
        else -> HomeScreen(controller)
    }
}

@Composable
private fun LoadingScreen() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Box(
                modifier = Modifier.size(72.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text("M", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary)
            }
            Text("MOSHI", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Black)
            CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
        }
    }
}

private enum class AuthMode { Login, Register }

@Composable
private fun AuthScreen(controller: AuthController) {
    val scope = rememberCoroutineScope()
    var mode by remember { mutableStateOf(AuthMode.Login) }
    var username by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 40.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier.size(68.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text("M", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary)
        }
        Spacer(Modifier.height(18.dp))
        Text("MOSHI", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Black)
        Text("Your people. Your spaces. Your business.", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(30.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (mode == AuthMode.Login) {
                Button(onClick = { mode = AuthMode.Login; controller.clearError() }) { Text("Login") }
                OutlinedButton(onClick = { mode = AuthMode.Register; controller.clearError() }) { Text("Create account") }
            } else {
                OutlinedButton(onClick = { mode = AuthMode.Login; controller.clearError() }) { Text("Login") }
                Button(onClick = { mode = AuthMode.Register; controller.clearError() }) { Text("Create account") }
            }
        }

        Spacer(Modifier.height(22.dp))
        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Username") },
            singleLine = true,
            enabled = !controller.busy,
        )
        if (mode == AuthMode.Register) {
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = displayName,
                onValueChange = { displayName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Display name") },
                singleLine = true,
                enabled = !controller.busy,
            )
        }
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Password") },
            singleLine = true,
            enabled = !controller.busy,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
        )
        controller.error?.let {
            Spacer(Modifier.height(12.dp))
            Text(it, color = MaterialTheme.colorScheme.error)
        }
        Spacer(Modifier.height(20.dp))
        Button(
            onClick = {
                scope.launch {
                    if (mode == AuthMode.Register) controller.register(username, displayName, password)
                    else controller.login(username, password)
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !controller.busy && username.isNotBlank() && password.isNotBlank() && (mode == AuthMode.Login || displayName.isNotBlank()),
        ) {
            if (controller.busy) CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
            else Text(if (mode == AuthMode.Register) "Create MOSHI account" else "Continue")
        }
    }
}

private data class MoshiTab(val label: String, val icon: ImageVector)

@Composable
private fun HomeScreen(controller: AuthController) {
    val session = controller.session ?: return
    val tabs = listOf(
        MoshiTab("Chats", Icons.Rounded.ChatBubble),
        MoshiTab("Communities", Icons.Rounded.Groups),
        MoshiTab("Business", Icons.Rounded.Storefront),
        MoshiTab("Activity", Icons.Rounded.Notifications),
        MoshiTab("Me", Icons.Rounded.Person),
    )
    var selected by remember { mutableIntStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEachIndexed { index, tab ->
                    NavigationBarItem(
                        selected = selected == index,
                        onClick = { selected = index },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                    )
                }
            }
        },
    ) { padding ->
        when (tabs[selected].label) {
            "Chats" -> ChatHubScreen(session, Modifier.padding(padding))
            "Communities" -> CommunityShellScreen(Modifier.padding(padding))
            "Business" -> BusinessCommerceHubScreen(controller, Modifier.padding(padding))
            "Activity" -> ActivityShellScreen(Modifier.padding(padding))
            else -> MeScreen(controller, Modifier.padding(padding))
        }
    }
}

@Composable
private fun CommunityShellScreen(modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxSize().padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text("Communities", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
        Text("Your shared spaces", color = MaterialTheme.colorScheme.onSurfaceVariant)
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Community structure", fontWeight = FontWeight.Bold)
                Text("Community → category → channel", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("Existing MOSHI groups are being moved here so channels do not duplicate Chats.", style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun ActivityShellScreen(modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxSize().padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text("Activity", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
        Text("Mentions, important updates and order activity", color = MaterialTheme.colorScheme.onSurfaceVariant)
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Quiet for now", fontWeight = FontWeight.Bold)
                Text("Realtime chat and business updates remain active in their original screens while the unified Activity feed is wired.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun MeScreen(controller: AuthController, modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    val user = controller.session?.user ?: return
    var editing by remember { mutableStateOf(false) }
    var displayName by remember(user.displayName) { mutableStateOf(user.displayName) }

    Column(modifier = modifier.fillMaxSize().padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text("Me", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
        Card(modifier = Modifier.fillMaxWidth()) {
            Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Box(
                    modifier = Modifier.size(58.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(user.displayName.take(1).uppercase(), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary)
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(user.displayName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text("@${user.username}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(if (user.businessMode) "Business Mode" else "Personal account", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                }
            }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (editing) {
                    OutlinedTextField(
                        value = displayName,
                        onValueChange = { displayName = it },
                        label = { Text("Display name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(
                            onClick = { scope.launch { controller.updateDisplayName(displayName); if (controller.error == null) editing = false } },
                            enabled = !controller.busy && displayName.isNotBlank(),
                        ) { Text("Save") }
                        TextButton(onClick = { editing = false; displayName = user.displayName }) { Text("Cancel") }
                    }
                } else {
                    OutlinedButton(onClick = { editing = true }) { Text("Edit profile") }
                }
                HorizontalDivider()
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Business Mode", fontWeight = FontWeight.SemiBold)
                        Text("Use catalog, orders and CRM in the same MOSHI account.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Switch(
                        checked = user.businessMode,
                        onCheckedChange = { enabled -> scope.launch { controller.setBusinessMode(enabled) } },
                        enabled = !controller.busy,
                    )
                }
            }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("Privacy & account", fontWeight = FontWeight.Bold)
                Text("Profile privacy, devices and notification controls will live here.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        OutlinedButton(onClick = { scope.launch { controller.logout() } }, enabled = !controller.busy, modifier = Modifier.fillMaxWidth()) {
            Text("Log out")
        }
    }
}
