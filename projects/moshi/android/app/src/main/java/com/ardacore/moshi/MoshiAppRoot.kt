package com.ardacore.moshi

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
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
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("MOSHI", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(16.dp))
            CircularProgressIndicator()
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
    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 48.dp), verticalArrangement = Arrangement.Center) {
        Text("MOSHI", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold)
        Text("Talk. Share. Connect.", style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(32.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (mode == AuthMode.Login) {
                Button(onClick = { mode = AuthMode.Login; controller.clearError() }) { Text("Login") }
                OutlinedButton(onClick = { mode = AuthMode.Register; controller.clearError() }) { Text("Create account") }
            } else {
                OutlinedButton(onClick = { mode = AuthMode.Login; controller.clearError() }) { Text("Login") }
                Button(onClick = { mode = AuthMode.Register; controller.clearError() }) { Text("Create account") }
            }
        }
        Spacer(Modifier.height(24.dp))
        OutlinedTextField(value = username, onValueChange = { username = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Username") }, singleLine = true, enabled = !controller.busy)
        if (mode == AuthMode.Register) {
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(value = displayName, onValueChange = { displayName = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Display name") }, singleLine = true, enabled = !controller.busy)
        }
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(value = password, onValueChange = { password = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Password") }, singleLine = true, enabled = !controller.busy, visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password))
        controller.error?.let {
            Spacer(Modifier.height(12.dp))
            Text(it, color = MaterialTheme.colorScheme.error)
        }
        Spacer(Modifier.height(20.dp))
        Button(
            onClick = { scope.launch { if (mode == AuthMode.Register) controller.register(username, displayName, password) else controller.login(username, password) } },
            modifier = Modifier.fillMaxWidth(),
            enabled = !controller.busy && username.isNotBlank() && password.isNotBlank() && (mode == AuthMode.Login || displayName.isNotBlank()),
        ) {
            if (controller.busy) CircularProgressIndicator(modifier = Modifier.height(20.dp), strokeWidth = 2.dp)
            else Text(if (mode == AuthMode.Register) "Create MOSHI account" else "Continue")
        }
        Spacer(Modifier.height(16.dp))
        Text("Debug API: ${BuildConfig.API_BASE_URL}", style = MaterialTheme.typography.bodySmall)
    }
}

private data class MoshiTab(val label: String)

@Composable
private fun HomeScreen(controller: AuthController) {
    val session = controller.session ?: return
    val tabs = listOf(MoshiTab("Chats"), MoshiTab("Communities"), MoshiTab("Business"), MoshiTab("Activity"), MoshiTab("Me"))
    var selected by remember { mutableIntStateOf(0) }
    Scaffold(bottomBar = {
        NavigationBar {
            tabs.forEachIndexed { index, tab ->
                NavigationBarItem(selected = selected == index, onClick = { selected = index }, icon = { Text(tab.label.take(1)) }, label = { Text(tab.label) })
            }
        }
    }) { padding ->
        when (tabs[selected].label) {
            "Chats" -> ChatHubScreen(session, Modifier.padding(padding))
            "Communities" -> PlaceholderScreen("Communities", Modifier.padding(padding))
            "Business" -> BusinessHubScreen(controller, Modifier.padding(padding))
            "Activity" -> PlaceholderScreen("Activity", Modifier.padding(padding))
            else -> MeScreen(controller, Modifier.padding(padding))
        }
    }
}

@Composable
private fun MeScreen(controller: AuthController, modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    val user = controller.session?.user ?: return
    var editing by remember { mutableStateOf(false) }
    var displayName by remember(user.displayName) { mutableStateOf(user.displayName) }
    Column(modifier = modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Me", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Text(user.displayName, style = MaterialTheme.typography.titleLarge)
        Text("@${user.username}")
        Text(if (user.businessMode) "Business Mode enabled" else "Personal account")
        HorizontalDivider()
        if (editing) {
            OutlinedTextField(value = displayName, onValueChange = { displayName = it }, label = { Text("Display name") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = { scope.launch { controller.updateDisplayName(displayName); if (controller.error == null) editing = false } }, enabled = !controller.busy && displayName.isNotBlank()) { Text("Save") }
                TextButton(onClick = { editing = false; displayName = user.displayName }) { Text("Cancel") }
            }
        } else {
            OutlinedButton(onClick = { editing = true }) { Text("Edit profile") }
        }
        controller.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        Spacer(Modifier.height(8.dp))
        OutlinedButton(onClick = { scope.launch { controller.logout() } }, enabled = !controller.busy) { Text("Log out") }
    }
}

@Composable
private fun PlaceholderScreen(title: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxSize().padding(20.dp)) {
        Text(title, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text("MOSHI roadmap module")
    }
}
