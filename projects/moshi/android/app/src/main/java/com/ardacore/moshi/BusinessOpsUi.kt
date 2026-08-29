package com.ardacore.moshi

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.business.BusinessOpsController
import kotlinx.coroutines.launch

@Composable
fun BusinessOpsPanel(session: AuthSession, modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    val controller = remember(session.accessToken) { BusinessOpsController(session) }
    var open by remember { mutableStateOf(false) }
    var shortcut by remember { mutableStateOf("") }
    var replyTitle by remember { mutableStateOf("") }
    var replyBody by remember { mutableStateOf("") }
    var labelName by remember { mutableStateOf("") }
    var customerUsername by remember { mutableStateOf("") }

    LaunchedEffect(controller) { controller.loadAll() }

    Card(modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp)) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Text("Orders & CRM", fontWeight = FontWeight.SemiBold)
                    Text("Order status · quick replies · customer labels")
                }
                TextButton(onClick = { open = !open }) { Text(if (open) "Close" else "Open") }
            }

            if (open) {
                Column(
                    modifier = Modifier.heightIn(max = 420.dp).verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text("Orders", fontWeight = FontWeight.SemiBold)
                    if (controller.orders.isEmpty()) Text("No orders yet")
                    controller.orders.forEach { order ->
                        Card(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                                val title = order.items.firstOrNull()?.title ?: "Order"
                                Text(title, fontWeight = FontWeight.SemiBold)
                                Text("${order.status.replace('_', ' ')} · ${order.totalAmount?.let { "${order.currency} $it" } ?: "Ask price"}")
                                if (order.note.isNotBlank()) Text(order.note)
                                controller.allowedStatusActions(order).forEach { target ->
                                    OutlinedButton(
                                        onClick = { scope.launch { controller.setOrderStatus(order, target) } },
                                        enabled = !controller.busy,
                                    ) { Text(target.replace('_', ' ')) }
                                }
                            }
                        }
                    }
                    TextButton(onClick = { scope.launch { controller.refreshOrders() } }) { Text("Refresh orders") }

                    HorizontalDivider()
                    Text("Quick Replies", fontWeight = FontWeight.SemiBold)
                    OutlinedTextField(shortcut, { shortcut = it }, label = { Text("Shortcut, e.g. price") }, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(replyTitle, { replyTitle = it }, label = { Text("Title") }, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(replyBody, { replyBody = it }, label = { Text("Reply text") }, modifier = Modifier.fillMaxWidth())
                    Button(
                        onClick = {
                            scope.launch {
                                if (controller.createQuickReply(shortcut, replyTitle, replyBody)) {
                                    shortcut = ""; replyTitle = ""; replyBody = ""
                                }
                            }
                        },
                        enabled = shortcut.isNotBlank() && replyTitle.isNotBlank() && replyBody.isNotBlank() && !controller.busy,
                    ) { Text("Save quick reply") }
                    controller.quickReplies.forEach { item ->
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column(Modifier.weight(1f)) {
                                Text("/${item.shortcut} · ${item.title}", fontWeight = FontWeight.SemiBold)
                                Text(item.body)
                            }
                            TextButton(onClick = { scope.launch { controller.deleteQuickReply(item) } }) { Text("Delete") }
                        }
                    }

                    HorizontalDivider()
                    Text("Customer Labels", fontWeight = FontWeight.SemiBold)
                    OutlinedTextField(labelName, { labelName = it }, label = { Text("New label") }, modifier = Modifier.fillMaxWidth())
                    Button(
                        onClick = { scope.launch { if (controller.createLabel(labelName)) labelName = "" } },
                        enabled = labelName.isNotBlank() && !controller.busy,
                    ) { Text("Create label") }
                    controller.labels.forEach { label ->
                        OutlinedButton(onClick = { scope.launch { controller.deleteLabel(label) } }) { Text("${label.name} ×") }
                    }
                    OutlinedTextField(customerUsername, { customerUsername = it }, label = { Text("Customer @username") }, modifier = Modifier.fillMaxWidth())
                    Button(
                        onClick = { scope.launch { controller.loadCustomer(customerUsername) } },
                        enabled = customerUsername.isNotBlank() && !controller.busy,
                    ) { Text("Load customer labels") }
                    controller.labels.forEach { label ->
                        val assigned = controller.selectedCustomerLabels.any { it.id == label.id }
                        if (assigned) {
                            Button(onClick = { scope.launch { controller.toggleCustomerLabel(customerUsername, label) } }) { Text(label.name) }
                        } else {
                            OutlinedButton(onClick = { scope.launch { controller.toggleCustomerLabel(customerUsername, label) } }) { Text(label.name) }
                        }
                    }
                    controller.error?.let {
                        Text(it)
                        TextButton(onClick = controller::clearError) { Text("Dismiss error") }
                    }
                }
            }
        }
    }
}
