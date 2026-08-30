package com.ardacore.moshi

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthController
import com.ardacore.moshi.business.BusinessController
import kotlinx.coroutines.launch

@Composable
fun BusinessCommerceHubScreen(authController: AuthController, modifier: Modifier = Modifier) {
    val session = authController.session ?: return
    val context = LocalContext.current.applicationContext
    val scope = rememberCoroutineScope()
    val shareController = remember(session.accessToken, session.user.businessMode) {
        BusinessController(session, context)
    }
    var username by remember { mutableStateOf("") }
    var selectedIndex by remember { mutableIntStateOf(0) }
    var panelOpen by remember { mutableStateOf(false) }

    LaunchedEffect(shareController) {
        if (session.user.businessMode) shareController.load()
    }

    Column(modifier = modifier.fillMaxSize()) {
        if (session.user.businessMode) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("Catalog → Chat", fontWeight = FontWeight.SemiBold)
                TextButton(onClick = {
                    panelOpen = !panelOpen
                    if (panelOpen) scope.launch { shareController.load() }
                }) { Text(if (panelOpen) "Close" else "Quick Share") }
            }
            if (panelOpen) {
                Card(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp)) {
                    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Share a product/service card", fontWeight = FontWeight.SemiBold)
                        OutlinedTextField(
                            value = username,
                            onValueChange = { username = it },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Customer @username") },
                            singleLine = true,
                        )
                        val items = shareController.catalog
                        if (items.isEmpty()) {
                            Text("No catalog items yet. Add one below, then tap Refresh.")
                            OutlinedButton(onClick = { scope.launch { shareController.load() } }) { Text("Refresh") }
                        } else {
                            if (selectedIndex !in items.indices) selectedIndex = 0
                            val selected = items[selectedIndex]
                            Text(selected.title)
                            Text(selected.priceAmount?.let { "IDR $it" } ?: "Ask price")
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                if (items.size > 1) {
                                    OutlinedButton(onClick = { selectedIndex = (selectedIndex - 1 + items.size) % items.size }) { Text("Prev") }
                                    OutlinedButton(onClick = { selectedIndex = (selectedIndex + 1) % items.size }) { Text("Next") }
                                }
                                Button(
                                    onClick = {
                                        scope.launch {
                                            if (shareController.shareCatalogItem(selected, username)) username = ""
                                        }
                                    },
                                    enabled = username.isNotBlank() && !shareController.busy,
                                ) { Text("Share") }
                            }
                            TextButton(onClick = { scope.launch { shareController.load() } }) { Text("Refresh catalog") }
                        }
                        shareController.lastShareMessage?.let {
                            Text(it)
                            TextButton(onClick = shareController::clearShareMessage) { Text("Dismiss") }
                        }
                        shareController.error?.let {
                            Text(it)
                            TextButton(onClick = shareController::clearError) { Text("Dismiss error") }
                        }
                    }
                }
            }
        }
        BusinessHubScreen(authController, Modifier.weight(1f))
    }
}
