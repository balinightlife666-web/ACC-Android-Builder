package com.ardacore.moshi

import androidx.activity.compose.BackHandler
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
import androidx.compose.runtime.key
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
import com.ardacore.moshi.push.PushTokenRegistrar
import kotlinx.coroutines.launch

@Composable
fun MoshiMasterRoot() {
    val context = LocalContext.current
    val auth = remember { AuthController(context) }
    LaunchedEffect(Unit) { auth.restore() }
    when {
        auth.restoring -> MasterLoading()
        auth.session == null -> MasterAuth(auth)
        else -> MasterHome(auth)
    }
}

@Composable
private fun MasterLoading() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            MoshiAvatar("M", 72)
            Text("MOSHI", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Black)
            CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
        }
    }
}

private enum class MasterAuthMode { Login, Register }

@Composable
private fun MasterAuth(auth: AuthController) {
    val scope = rememberCoroutineScope()
    var mode by remember { mutableStateOf(MasterAuthMode.Login) }
    var username by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(
        Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 40.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        MoshiAvatar("M", 68)
        Spacer(Modifier.height(18.dp))
        Text("MOSHI", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Black)
        Text(
            "Your people. Your spaces. Your business.",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(28.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (mode == MasterAuthMode.Login) {
                Button(onClick = { mode = MasterAuthMode.Login; auth.clearError() }) { Text("Login") }
                OutlinedButton(onClick = { mode = MasterAuthMode.Register; auth.clearError() }) { Text("Create account") }
            } else {
                OutlinedButton(onClick = { mode = MasterAuthMode.Login; auth.clearError() }) { Text("Login") }
                Button(onClick = { mode = MasterAuthMode.Register; auth.clearError() }) { Text("Create account") }
            }
        }

        Spacer(Modifier.height(20.dp))
        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Username") },
            singleLine = true,
            enabled = !auth.busy,
        )
        if (mode == MasterAuthMode.Register) {
            Spacer(Modifier.height(10.dp))
            OutlinedTextField(
                value = displayName,
                onValueChange = { displayName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Display name") },
                singleLine = true,
                enabled = !auth.busy,
            )
        }
        Spacer(Modifier.height(10.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Password") },
            singleLine = true,
            enabled = !auth.busy,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
        )

        auth.error?.let {
            Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(top = 10.dp))
        }

        Spacer(Modifier.height(18.dp))
        Button(
            onClick = {
                scope.launch {
                    if (mode == MasterAuthMode.Register) auth.register(username, displayName, password)
                    else auth.login(username, password)
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !auth.busy && username.isNotBlank() && password.isNotBlank() &&
                (mode == MasterAuthMode.Login || displayName.isNotBlank()),
        ) {
            if (auth.busy) CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
            else Text(if (mode == MasterAuthMode.Register) "Create MOSHI account" else "Continue")
        }
    }
}

private data class MasterTab(val label: String, val icon: ImageVector)

@Composable
private fun MasterHome(auth: AuthController) {
    val session = auth.session ?: return
    val tabs = listOf(
        MasterTab("Chats", Icons.Rounded.ChatBubble),
        MasterTab("Communities", Icons.Rounded.Groups),
        MasterTab("Business", Icons.Rounded.Storefront),
        MasterTab("Activity", Icons.Rounded.Notifications),
        MasterTab("Me", Icons.Rounded.Person),
    )
    var selected by remember { mutableIntStateOf(0) }
    var immersive by remember { mutableStateOf(false) }
    var screenGeneration by remember { mutableIntStateOf(0) }

    LaunchedEffect(selected) { immersive = false }

    BackHandler(enabled = immersive) {
        immersive = false
        screenGeneration += 1
    }

    Scaffold(
        bottomBar = {
            if (!immersive) {
                NavigationBar {
                    tabs.forEachIndexed { index, tab ->
                        NavigationBarItem(
                            selected = selected == index,
                            onClick = { selected = index },
                            icon = { Icon(tab.icon, contentDescription = tab.label) },
                            label = null,
                            alwaysShowLabel = false,
                        )
                    }
                }
            }
        },
    ) { padding ->
        val modifier = Modifier.padding(padding)
        key(selected, screenGeneration) {
            when (selected) {
                0 -> MoshiChatsScreen(session, modifier, onImmersiveChanged = { immersive = it })
                1 -> CommunityHubScreen(session, modifier, onImmersiveChanged = { immersive = it })
                2 -> BusinessCommerceHubScreen(auth, modifier)
                3 -> ActivityHubScreen(session, modifier)
                else -> MasterMe(auth, modifier)
            }
        }
    }
}

@Composable
private fun MasterMe(auth: AuthController, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val user = auth.session?.user ?: return
    val pushConfigured = remember { PushTokenRegistrar.isFirebaseConfigured(context.applicationContext) }
    var editing by remember { mutableStateOf(false) }
    var displayName by remember(user.displayName) { mutableStateOf(user.displayName) }

    Column(
        modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text("Me", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)

        Card(modifier = Modifier.fillMaxWidth()) {
            Row(
                Modifier.fillMaxWidth().padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                MoshiAvatar(user.displayName.take(1).uppercase(), 58)
                Column(modifier = Modifier.weight(1f)) {
                    Text(user.displayName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text("@${user.username}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(
                        if (user.businessMode) "Business Mode" else "Personal account",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }
            }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Profile", fontWeight = FontWeight.Bold)
                if (editing) {
                    OutlinedTextField(
                        value = displayName,
                        onValueChange = { displayName = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Display name") },
                        singleLine = true,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(
                            onClick = {
                                scope.launch {
                                    auth.updateDisplayName(displayName)
                                    if (auth.error == null) editing = false
                                }
                            },
                            enabled = !auth.busy && displayName.isNotBlank(),
                        ) { Text("Save") }
                        TextButton(onClick = { editing = false; displayName = user.displayName }) { Text("Cancel") }
                    }
                } else {
                    OutlinedButton(onClick = { editing = true }) { Text("Edit display name") }
                }

                HorizontalDivider()

                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Business Mode", fontWeight = FontWeight.SemiBold)
                        Text(
                            "Catalog, orders and CRM use this same account.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Switch(
                        checked = user.businessMode,
                        onCheckedChange = { enabled -> scope.launch { auth.setBusinessMode(enabled) } },
                        enabled = !auth.busy,
                    )
                }
            }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Account", fontWeight = FontWeight.Bold)
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Username", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text("@${user.username}", fontWeight = FontWeight.SemiBold)
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Push notifications", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(
                        if (pushConfigured) "On" else "Off",
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }

        auth.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }

        OutlinedButton(
            onClick = { scope.launch { auth.logout() } },
            enabled = !auth.busy,
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Log out") }
    }
}

@Composable
private fun MoshiAvatar(label: String, sizeDp: Int) {
    Box(
        modifier = Modifier.size(sizeDp.dp).background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Black,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}
