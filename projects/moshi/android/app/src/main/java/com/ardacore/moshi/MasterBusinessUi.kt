package com.ardacore.moshi

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthController
import com.ardacore.moshi.business.BusinessController
import com.ardacore.moshi.business.BusinessOpsController
import com.ardacore.moshi.business.CatalogImageInput
import com.ardacore.moshi.business.CatalogItem
import com.ardacore.moshi.business.BusinessOrder
import com.ardacore.moshi.business.CustomerLabel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private const val MASTER_BUSINESS_IMAGE_MAX = 20L * 1024L * 1024L

private enum class BusinessSection(val label: String) {
    Profile("Profile"),
    Catalog("Catalog"),
    Orders("Orders"),
    CRM("CRM"),
}

@Composable
fun MasterBusinessScreen(auth: AuthController, modifier: Modifier = Modifier) {
    val session = auth.session ?: return
    val context = LocalContext.current.applicationContext
    val scope = rememberCoroutineScope()
    val business = remember(session.accessToken, session.user.businessMode) { BusinessController(session, context) }
    val ops = remember(session.accessToken) { BusinessOpsController(session) }
    var section by remember { mutableStateOf(BusinessSection.Profile) }

    LaunchedEffect(business) {
        if (session.user.businessMode) business.load()
    }
    LaunchedEffect(ops, session.user.businessMode) {
        if (session.user.businessMode) ops.loadAll()
    }

    Column(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Business", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
                    Text("Sell and manage customers inside MOSHI", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Switch(
                    checked = session.user.businessMode,
                    onCheckedChange = { enabled -> scope.launch { auth.setBusinessMode(enabled) } },
                    enabled = !auth.busy,
                )
            }

            if (session.user.businessMode) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    BusinessSection.entries.forEach { item ->
                        if (section == item) {
                            Button(onClick = { section = item }, modifier = Modifier.weight(1f)) { Text(item.label) }
                        } else {
                            OutlinedButton(onClick = { section = item }, modifier = Modifier.weight(1f)) { Text(item.label) }
                        }
                    }
                }
            }
        }

        if (!session.user.businessMode) {
            Card(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Business Mode is off", fontWeight = FontWeight.Bold)
                    Text(
                        "Turn it on to create a business profile, catalog, orders, quick replies and private customer labels. Your personal MOSHI account stays the same.",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Button(onClick = { scope.launch { auth.setBusinessMode(true) } }, enabled = !auth.busy) {
                        Text("Enable Business Mode")
                    }
                }
            }
        } else {
            when (section) {
                BusinessSection.Profile -> MasterBusinessProfile(business, Modifier.weight(1f))
                BusinessSection.Catalog -> MasterCatalog(business, Modifier.weight(1f))
                BusinessSection.Orders -> MasterOrders(ops, Modifier.weight(1f))
                BusinessSection.CRM -> MasterCrm(ops, Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun MasterBusinessProfile(controller: BusinessController, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    var name by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var hours by remember { mutableStateOf("") }
    var hydrated by remember(controller) { mutableStateOf(false) }
    var editing by remember { mutableStateOf(controller.profile == null) }

    LaunchedEffect(controller.profile) {
        val profile = controller.profile
        if (profile != null && !hydrated) {
            name = profile.businessName
            category = profile.category
            description = profile.description
            address = profile.address
            hours = profile.hours
            hydrated = true
            editing = false
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        item {
            if (controller.profile != null && !editing) {
                val profile = controller.profile!!
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(profile.businessName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        if (profile.category.isNotBlank()) Text(profile.category, color = MaterialTheme.colorScheme.primary)
                        if (profile.description.isNotBlank()) Text(profile.description)
                        if (profile.address.isNotBlank()) Text(profile.address, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        if (profile.hours.isNotBlank()) Text(profile.hours, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        OutlinedButton(onClick = { editing = true }) { Text("Edit profile") }
                    }
                }
            } else {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(if (controller.profile == null) "Create business profile" else "Edit business profile", fontWeight = FontWeight.Bold)
                        OutlinedTextField(name, { name = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Business name") }, singleLine = true)
                        OutlinedTextField(category, { category = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Category") }, singleLine = true)
                        OutlinedTextField(description, { description = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Description") }, minLines = 2, maxLines = 4)
                        OutlinedTextField(address, { address = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Address") }, maxLines = 3)
                        OutlinedTextField(hours, { hours = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Opening hours") }, maxLines = 2)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = {
                                    scope.launch {
                                        if (controller.saveProfile(name, category, description, address, hours)) editing = false
                                    }
                                },
                                enabled = name.isNotBlank() && !controller.busy,
                            ) { Text("Save") }
                            if (controller.profile != null) {
                                TextButton(onClick = { editing = false }) { Text("Cancel") }
                            }
                        }
                    }
                }
            }
        }

        controller.error?.let { error ->
            item { MasterBusinessError(error, controller::clearError) }
        }
    }
}

@Composable
private fun MasterCatalog(controller: BusinessController, modifier: Modifier) {
    val context = LocalContext.current.applicationContext
    val scope = rememberCoroutineScope()
    var editorOpen by remember { mutableStateOf(false) }
    var editing by remember { mutableStateOf<CatalogItem?>(null) }
    var kind by remember { mutableStateOf("product") }
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var price by remember { mutableStateOf("") }
    var stock by remember { mutableStateOf("") }
    var availability by remember { mutableStateOf("available") }
    var selectedImage by remember { mutableStateOf<CatalogImageInput?>(null) }
    var localError by remember { mutableStateOf<String?>(null) }
    var shareUsername by remember { mutableStateOf("") }

    fun resetEditor() {
        editorOpen = false
        editing = null
        kind = "product"
        title = ""
        description = ""
        price = ""
        stock = ""
        availability = "available"
        selectedImage = null
        localError = null
    }

    fun beginEdit(item: CatalogItem) {
        editing = item
        editorOpen = true
        kind = item.kind
        title = item.title
        description = item.description
        price = item.priceAmount?.toString().orEmpty()
        stock = item.stockQty?.toString().orEmpty()
        availability = item.availability
        selectedImage = null
        localError = null
    }

    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            scope.launch {
                localError = null
                runCatching {
                    runCatching { context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
                    withContext(Dispatchers.IO) { inspectMasterCatalogImage(context, uri) }
                }.onSuccess { selectedImage = it }
                    .onFailure { localError = it.message ?: "Could not use catalog photo" }
            }
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column {
                    Text("Catalog", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text("Products and services", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Button(onClick = { if (editorOpen) resetEditor() else editorOpen = true }, enabled = controller.profile != null && !controller.busy) {
                    Text(if (editorOpen) "Close" else "Add item")
                }
            }
        }

        if (controller.profile == null) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Text("Create your business profile first.", modifier = Modifier.padding(16.dp))
                }
            }
        }

        if (editorOpen && controller.profile != null) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(if (editing == null) "New catalog item" else "Edit catalog item", fontWeight = FontWeight.Bold)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            if (kind == "product") Button(onClick = { kind = "product" }) { Text("Product") }
                            else OutlinedButton(onClick = { kind = "product" }) { Text("Product") }
                            if (kind == "service") Button(onClick = { kind = "service" }) { Text("Service") }
                            else OutlinedButton(onClick = { kind = "service" }) { Text("Service") }
                        }
                        OutlinedTextField(title, { title = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Title") }, singleLine = true)
                        OutlinedTextField(description, { description = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Description") }, minLines = 2, maxLines = 4)
                        OutlinedTextField(
                            value = price,
                            onValueChange = { value -> price = value.filter(Char::isDigit) },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Price (IDR, optional)") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true,
                        )
                        if (kind == "product") {
                            OutlinedTextField(
                                value = stock,
                                onValueChange = { value -> stock = value.filter(Char::isDigit) },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("Stock (optional)") },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                singleLine = true,
                            )
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            if (availability == "available") Button(onClick = { availability = "available" }) { Text("Available") }
                            else OutlinedButton(onClick = { availability = "available" }) { Text("Available") }
                            if (availability == "unavailable") Button(onClick = { availability = "unavailable" }) { Text("Unavailable") }
                            else OutlinedButton(onClick = { availability = "unavailable" }) { Text("Unavailable") }
                        }
                        OutlinedButton(
                            onClick = { imagePicker.launch(arrayOf("image/jpeg", "image/png", "image/webp")) },
                            enabled = !controller.busy,
                        ) { Text(if (selectedImage == null) "Choose photo" else "Photo selected") }
                        Button(
                            onClick = {
                                scope.launch {
                                    val saved = controller.saveCatalogItem(
                                        editing = editing,
                                        kind = kind,
                                        title = title,
                                        description = description,
                                        priceAmount = price.toLongOrNull(),
                                        availability = availability,
                                        stockQty = stock.toIntOrNull(),
                                        image = selectedImage,
                                    )
                                    if (saved) resetEditor()
                                }
                            },
                            enabled = title.isNotBlank() && !controller.busy,
                        ) { Text("Save item") }
                        localError?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                    }
                }
            }
        }

        if (controller.catalog.isEmpty() && controller.profile != null && !editorOpen) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Your catalog is empty", fontWeight = FontWeight.Bold)
                        Text("Add a product or service to start sharing it in chat.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }

        if (controller.catalog.isNotEmpty()) {
            item {
                OutlinedTextField(
                    value = shareUsername,
                    onValueChange = { shareUsername = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Share to customer @username") },
                    singleLine = true,
                )
            }
            items(controller.catalog, key = { it.id }) { item ->
                MasterCatalogCard(
                    controller = controller,
                    item = item,
                    shareUsername = shareUsername,
                    onEdit = { beginEdit(item) },
                    onDelete = { scope.launch { controller.deleteCatalogItem(item) } },
                    onShare = { scope.launch { controller.shareCatalogItem(item, shareUsername) } },
                )
            }
        }

        controller.lastShareMessage?.let { message ->
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(message, modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.primary)
                        TextButton(onClick = controller::clearShareMessage) { Text("Dismiss") }
                    }
                }
            }
        }

        controller.error?.let { error ->
            item { MasterBusinessError(error, controller::clearError) }
        }
    }
}

@Composable
private fun MasterCatalogCard(
    controller: BusinessController,
    item: CatalogItem,
    shareUsername: String,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onShare: () -> Unit,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(7.dp)) {
            MasterCatalogImage(controller, item)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(item.title, fontWeight = FontWeight.Bold)
                    Text(item.kind.replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                }
                Text(item.availability.replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.labelMedium)
            }
            if (item.description.isNotBlank()) Text(item.description, style = MaterialTheme.typography.bodySmall)
            Text(item.priceAmount?.let { "${item.currency} $it" } ?: "Ask price", fontWeight = FontWeight.SemiBold)
            if (item.kind == "product" && item.stockQty != null) Text("Stock ${item.stockQty}", style = MaterialTheme.typography.bodySmall)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = onEdit) { Text("Edit") }
                OutlinedButton(onClick = onDelete) { Text("Delete") }
                Button(onClick = onShare, enabled = shareUsername.isNotBlank()) { Text("Share") }
            }
        }
    }
}

@Composable
private fun MasterCatalogImage(controller: BusinessController, item: CatalogItem) {
    var bytes by remember(item.id, item.imagePath) { mutableStateOf<ByteArray?>(null) }
    LaunchedEffect(item.id, item.imagePath) {
        bytes = if (item.imagePath != null) controller.loadCatalogImage(item) else null
    }
    val bitmap = remember(bytes) { bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) } }
    if (bitmap != null) {
        Image(
            bitmap = bitmap.asImageBitmap(),
            contentDescription = item.title,
            modifier = Modifier.fillMaxWidth().height(160.dp),
            contentScale = ContentScale.Crop,
        )
    }
}

@Composable
private fun MasterOrders(controller: BusinessOpsController, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    LazyColumn(
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        item {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Column {
                    Text("Orders", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text("Buyer and seller workflow", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                TextButton(onClick = { scope.launch { controller.refreshOrders() } }, enabled = !controller.busy) { Text("Refresh") }
            }
        }

        if (controller.orders.isEmpty()) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Text("No orders yet.", modifier = Modifier.padding(16.dp))
                }
            }
        } else {
            items(controller.orders, key = { it.id }) { order ->
                MasterOrderCard(controller, order)
            }
        }

        controller.error?.let { error ->
            item { MasterBusinessError(error, controller::clearError) }
        }
    }
}

@Composable
private fun MasterOrderCard(controller: BusinessOpsController, order: BusinessOrder) {
    val scope = rememberCoroutineScope()
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(order.items.firstOrNull()?.title ?: "Order", fontWeight = FontWeight.Bold)
            Text(order.status.replace('_', ' ').replaceFirstChar { it.uppercase() }, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
            order.items.forEach { line ->
                Text("${line.quantity} × ${line.title}", style = MaterialTheme.typography.bodySmall)
            }
            Text(order.totalAmount?.let { "${order.currency} $it" } ?: "Ask price", fontWeight = FontWeight.SemiBold)
            if (order.note.isNotBlank()) Text(order.note, style = MaterialTheme.typography.bodySmall)
            val actions = controller.allowedStatusActions(order)
            if (actions.isNotEmpty()) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    actions.forEach { target ->
                        OutlinedButton(
                            onClick = { scope.launch { controller.setOrderStatus(order, target) } },
                            enabled = !controller.busy,
                        ) { Text(target.replace('_', ' ').replaceFirstChar { it.uppercase() }) }
                    }
                }
            }
        }
    }
}

@Composable
private fun MasterCrm(controller: BusinessOpsController, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    var shortcut by remember { mutableStateOf("") }
    var replyTitle by remember { mutableStateOf("") }
    var replyBody by remember { mutableStateOf("") }
    var labelName by remember { mutableStateOf("") }
    var customer by remember { mutableStateOf("") }

    LazyColumn(
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        item {
            Text("CRM", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("Quick replies and private customer labels", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }

        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Quick replies", fontWeight = FontWeight.Bold)
                    OutlinedTextField(shortcut, { shortcut = it.removePrefix("/") }, modifier = Modifier.fillMaxWidth(), label = { Text("Shortcut") }, singleLine = true)
                    OutlinedTextField(replyTitle, { replyTitle = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Title") }, singleLine = true)
                    OutlinedTextField(replyBody, { replyBody = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Reply text") }, minLines = 2, maxLines = 4)
                    Button(
                        onClick = {
                            scope.launch {
                                if (controller.createQuickReply(shortcut, replyTitle, replyBody)) {
                                    shortcut = ""
                                    replyTitle = ""
                                    replyBody = ""
                                }
                            }
                        },
                        enabled = shortcut.isNotBlank() && replyTitle.isNotBlank() && replyBody.isNotBlank() && !controller.busy,
                    ) { Text("Save quick reply") }
                }
            }
        }

        items(controller.quickReplies, key = { it.id }) { item ->
            Card(modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("/${item.shortcut} · ${item.title}", fontWeight = FontWeight.SemiBold)
                        Text(item.body, style = MaterialTheme.typography.bodySmall)
                    }
                    TextButton(onClick = { scope.launch { controller.deleteQuickReply(item) } }, enabled = !controller.busy) { Text("Delete") }
                }
            }
        }

        item { HorizontalDivider() }

        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Customer labels", fontWeight = FontWeight.Bold)
                    OutlinedTextField(labelName, { labelName = it }, modifier = Modifier.fillMaxWidth(), label = { Text("New label") }, singleLine = true)
                    Button(
                        onClick = { scope.launch { if (controller.createLabel(labelName)) labelName = "" } },
                        enabled = labelName.isNotBlank() && !controller.busy,
                    ) { Text("Create label") }
                    if (controller.labels.isNotEmpty()) {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            controller.labels.take(4).forEach { label ->
                                OutlinedButton(onClick = { scope.launch { controller.deleteLabel(label) } }, enabled = !controller.busy) {
                                    Text("${label.name} ×")
                                }
                            }
                        }
                    }
                    OutlinedTextField(customer, { customer = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Customer @username") }, singleLine = true)
                    Button(
                        onClick = { scope.launch { controller.loadCustomer(customer) } },
                        enabled = customer.isNotBlank() && !controller.busy,
                    ) { Text("Load customer") }
                }
            }
        }

        if (customer.isNotBlank() && controller.labels.isNotEmpty()) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Labels for @${customer.trim().removePrefix("@")}", fontWeight = FontWeight.SemiBold)
                        controller.labels.forEach { label ->
                            MasterCustomerLabelRow(controller, customer, label)
                        }
                    }
                }
            }
        }

        controller.error?.let { error ->
            item { MasterBusinessError(error, controller::clearError) }
        }
    }
}

@Composable
private fun MasterCustomerLabelRow(controller: BusinessOpsController, customer: String, label: CustomerLabel) {
    val scope = rememberCoroutineScope()
    val assigned = controller.selectedCustomerLabels.any { it.id == label.id }
    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label.name)
        if (assigned) {
            Button(onClick = { scope.launch { controller.toggleCustomerLabel(customer, label) } }, enabled = !controller.busy) { Text("Assigned") }
        } else {
            OutlinedButton(onClick = { scope.launch { controller.toggleCustomerLabel(customer, label) } }, enabled = !controller.busy) { Text("Assign") }
        }
    }
}

@Composable
private fun MasterBusinessError(message: String, onDismiss: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(message, modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            TextButton(onClick = onDismiss) { Text("Dismiss") }
        }
    }
}

private fun inspectMasterCatalogImage(context: Context, uri: Uri): CatalogImageInput {
    val resolver = context.contentResolver
    var fileName = "catalog-photo"
    var size = -1L
    resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (nameIndex >= 0 && !cursor.isNull(nameIndex)) fileName = cursor.getString(nameIndex)
            if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
        }
    }
    if (size < 0L) resolver.openAssetFileDescriptor(uri, "r")?.use { descriptor -> size = descriptor.length }
    if (size <= 0L) error("Could not read image size")
    if (size > MASTER_BUSINESS_IMAGE_MAX) error("Catalog photo exceeds 20 MB")
    val type = resolver.getType(uri)?.lowercase() ?: error("Unknown image type")
    if (type !in setOf("image/jpeg", "image/png", "image/webp")) error("Use JPG, PNG or WebP")
    return CatalogImageInput(uri.toString(), fileName.take(160), type, size)
}
