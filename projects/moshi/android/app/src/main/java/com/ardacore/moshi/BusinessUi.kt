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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.auth.AuthController
import com.ardacore.moshi.business.BusinessController
import com.ardacore.moshi.business.CatalogImageInput
import com.ardacore.moshi.business.CatalogItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private const val MAX_CATALOG_IMAGE_BYTES = 20 * 1024 * 1024L

@Composable
fun BusinessHubScreen(authController: AuthController, modifier: Modifier = Modifier) {
    val context = LocalContext.current.applicationContext
    val scope = rememberCoroutineScope()
    val session = authController.session ?: return
    val controller = remember(session.accessToken, session.user.businessMode) {
        BusinessController(session, context)
    }
    LaunchedEffect(controller) {
        if (session.user.businessMode) controller.load()
    }

    var businessName by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var hours by remember { mutableStateOf("") }
    var profileHydrated by remember(controller) { mutableStateOf(false) }

    var editorOpen by remember { mutableStateOf(false) }
    var editing by remember { mutableStateOf<CatalogItem?>(null) }
    var itemKind by remember { mutableStateOf("product") }
    var itemTitle by remember { mutableStateOf("") }
    var itemDescription by remember { mutableStateOf("") }
    var itemPrice by remember { mutableStateOf("") }
    var itemStock by remember { mutableStateOf("") }
    var itemAvailability by remember { mutableStateOf("available") }
    var selectedImage by remember { mutableStateOf<CatalogImageInput?>(null) }
    var localError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(controller.profile) {
        val profile = controller.profile
        if (profile != null && !profileHydrated) {
            businessName = profile.businessName
            category = profile.category
            description = profile.description
            address = profile.address
            hours = profile.hours
            profileHydrated = true
        }
    }

    fun resetEditor() {
        editorOpen = false
        editing = null
        itemKind = "product"
        itemTitle = ""
        itemDescription = ""
        itemPrice = ""
        itemStock = ""
        itemAvailability = "available"
        selectedImage = null
        localError = null
    }

    fun startEdit(item: CatalogItem) {
        editing = item
        editorOpen = true
        itemKind = item.kind
        itemTitle = item.title
        itemDescription = item.description
        itemPrice = item.priceAmount?.toString().orEmpty()
        itemStock = item.stockQty?.toString().orEmpty()
        itemAvailability = item.availability
        selectedImage = null
        localError = null
    }

    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            scope.launch {
                localError = null
                runCatching {
                    runCatching {
                        context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    withContext(Dispatchers.IO) { inspectCatalogImage(context, uri) }
                }.onSuccess { selectedImage = it }
                    .onFailure { localError = it.message ?: "Could not use catalog photo" }
            }
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text("Business", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Text("Personal chat + selling in one MOSHI app")
        }
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Business Mode", fontWeight = FontWeight.SemiBold)
                        Text("No separate business app required", style = MaterialTheme.typography.bodySmall)
                    }
                    Switch(
                        checked = session.user.businessMode,
                        enabled = !authController.busy && !controller.busy,
                        onCheckedChange = { enabled -> scope.launch { authController.setBusinessMode(enabled) } },
                    )
                }
            }
        }

        if (!session.user.businessMode) {
            item {
                Text("Enable Business Mode to create a business profile and catalog. Your personal account remains the same MOSHI account.")
            }
        } else {
            item {
                Text("Business profile", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = businessName,
                        onValueChange = { businessName = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Business name") },
                        singleLine = true,
                    )
                    OutlinedTextField(
                        value = category,
                        onValueChange = { category = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Category") },
                        singleLine = true,
                    )
                    OutlinedTextField(
                        value = description,
                        onValueChange = { description = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Description") },
                        minLines = 2,
                        maxLines = 4,
                    )
                    OutlinedTextField(
                        value = address,
                        onValueChange = { address = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Address") },
                        maxLines = 3,
                    )
                    OutlinedTextField(
                        value = hours,
                        onValueChange = { hours = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Opening hours") },
                        maxLines = 2,
                    )
                    Button(
                        onClick = {
                            scope.launch {
                                controller.saveProfile(businessName, category, description, address, hours)
                            }
                        },
                        enabled = businessName.isNotBlank() && !controller.busy,
                    ) {
                        Text(if (controller.profile == null) "Save business profile" else "Update business profile")
                    }
                }
            }

            item { HorizontalDivider() }
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text("Catalog", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                        Text("Products + services", style = MaterialTheme.typography.bodySmall)
                    }
                    if (controller.profile != null) {
                        OutlinedButton(
                            onClick = {
                                if (editorOpen) resetEditor()
                                else {
                                    editing = null
                                    editorOpen = true
                                }
                            },
                            enabled = !controller.busy,
                        ) { Text(if (editorOpen) "Close" else "Add item") }
                    }
                }
            }

            if (controller.profile == null) {
                item { Text("Save your business profile first, then add products or services.") }
            }

            if (editorOpen && controller.profile != null) {
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(if (editing == null) "New catalog item" else "Edit catalog item", fontWeight = FontWeight.SemiBold)
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                if (itemKind == "product") {
                                    Button(onClick = { itemKind = "product" }) { Text("Product") }
                                    OutlinedButton(onClick = { itemKind = "service"; itemStock = ""; if (itemAvailability == "out_of_stock") itemAvailability = "unavailable" }) { Text("Service") }
                                } else {
                                    OutlinedButton(onClick = { itemKind = "product" }) { Text("Product") }
                                    Button(onClick = { itemKind = "service" }) { Text("Service") }
                                }
                            }
                            OutlinedTextField(
                                value = itemTitle,
                                onValueChange = { itemTitle = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("Name") },
                                singleLine = true,
                            )
                            OutlinedTextField(
                                value = itemDescription,
                                onValueChange = { itemDescription = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("Description") },
                                minLines = 2,
                                maxLines = 4,
                            )
                            OutlinedTextField(
                                value = itemPrice,
                                onValueChange = { itemPrice = it.filter(Char::isDigit) },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("Price (IDR)") },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                singleLine = true,
                            )
                            if (itemKind == "product") {
                                OutlinedTextField(
                                    value = itemStock,
                                    onValueChange = { itemStock = it.filter(Char::isDigit) },
                                    modifier = Modifier.fillMaxWidth(),
                                    label = { Text("Stock quantity (optional)") },
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                    singleLine = true,
                                )
                            }
                            Text("Availability", fontWeight = FontWeight.Medium)
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                AvailabilityButton("Available", "available", itemAvailability) { itemAvailability = it }
                                AvailabilityButton("Unavailable", "unavailable", itemAvailability) { itemAvailability = it }
                                if (itemKind == "product") {
                                    AvailabilityButton("Out", "out_of_stock", itemAvailability) { itemAvailability = it }
                                }
                            }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                OutlinedButton(
                                    onClick = { imagePicker.launch(arrayOf("image/jpeg", "image/png", "image/webp", "image/gif")) },
                                    enabled = !controller.busy,
                                ) { Text(if (selectedImage == null) "Choose photo" else "Change photo") }
                                Text(
                                    selectedImage?.fileName
                                        ?: if (editing?.imagePath != null) "Existing photo kept" else "Optional",
                                    style = MaterialTheme.typography.bodySmall,
                                    maxLines = 1,
                                )
                            }
                            localError?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Button(
                                    onClick = {
                                        localError = null
                                        val price = itemPrice.takeIf { it.isNotBlank() }?.toLongOrNull()
                                        val stock = itemStock.takeIf { it.isNotBlank() }?.toIntOrNull()
                                        if (itemPrice.isNotBlank() && price == null) {
                                            localError = "Price is invalid"
                                        } else if (itemKind == "product" && itemStock.isNotBlank() && stock == null) {
                                            localError = "Stock is invalid"
                                        } else {
                                            scope.launch {
                                                val saved = controller.saveCatalogItem(
                                                    editing = editing,
                                                    kind = itemKind,
                                                    title = itemTitle,
                                                    description = itemDescription,
                                                    priceAmount = price,
                                                    availability = itemAvailability,
                                                    stockQty = stock,
                                                    image = selectedImage,
                                                )
                                                if (saved) resetEditor()
                                            }
                                        }
                                    },
                                    enabled = itemTitle.isNotBlank() && !controller.busy,
                                ) { Text(if (editing == null) "Add to catalog" else "Save changes") }
                                TextButton(onClick = ::resetEditor, enabled = !controller.busy) { Text("Cancel") }
                            }
                        }
                    }
                }
            }

            if (controller.catalog.isEmpty() && controller.profile != null) {
                item { Text("Your catalog is empty. Add a product or service.") }
            }

            controller.catalog.forEach { catalogItem ->
                item(key = catalogItem.id) {
                    CatalogCard(
                        item = catalogItem,
                        controller = controller,
                        busy = controller.busy,
                        onEdit = { startEdit(catalogItem) },
                        onDelete = { scope.launch { controller.deleteCatalogItem(catalogItem) } },
                    )
                }
            }
        }

        if (controller.busy || authController.busy) {
            item {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    CircularProgressIndicator(modifier = Modifier.height(20.dp), strokeWidth = 2.dp)
                    Text("Updating MOSHI Business…", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
        controller.error?.let { message ->
            item {
                Text(message, color = MaterialTheme.colorScheme.error)
                TextButton(onClick = controller::clearError) { Text("Dismiss") }
            }
        }
        authController.error?.let { message ->
            item { Text(message, color = MaterialTheme.colorScheme.error) }
        }
    }
}

@Composable
private fun AvailabilityButton(label: String, value: String, selected: String, onSelect: (String) -> Unit) {
    if (selected == value) Button(onClick = { onSelect(value) }) { Text(label) }
    else OutlinedButton(onClick = { onSelect(value) }) { Text(label) }
}

@Composable
private fun CatalogCard(
    item: CatalogItem,
    controller: BusinessController,
    busy: Boolean,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            CatalogImagePreview(item, controller)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(item.title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text(item.kind.replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.labelMedium)
                }
                Text(item.priceAmount?.let(::formatIdr) ?: "Ask price", fontWeight = FontWeight.SemiBold)
            }
            if (item.description.isNotBlank()) Text(item.description)
            val statusText = when (item.availability) {
                "out_of_stock" -> "Out of stock"
                "unavailable" -> "Unavailable"
                else -> "Available"
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(statusText, style = MaterialTheme.typography.bodySmall)
                if (item.kind == "product" && item.stockQty != null) {
                    Text("Stock: ${item.stockQty}", style = MaterialTheme.typography.bodySmall)
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = onEdit, enabled = !busy) { Text("Edit") }
                TextButton(onClick = onDelete, enabled = !busy) { Text("Delete") }
            }
        }
    }
}

@Composable
private fun CatalogImagePreview(item: CatalogItem, controller: BusinessController) {
    var image by remember(item.id, item.imagePath) { mutableStateOf<ImageBitmap?>(null) }
    LaunchedEffect(item.id, item.imagePath) {
        image = null
        if (item.imagePath != null) {
            val bytes = controller.loadCatalogImage(item)
            if (bytes != null) image = withContext(Dispatchers.Default) { decodeCatalogPreview(bytes) }
        }
    }
    image?.let {
        Image(
            bitmap = it,
            contentDescription = item.title,
            modifier = Modifier.fillMaxWidth().height(160.dp),
            contentScale = ContentScale.Crop,
        )
    }
}

private fun inspectCatalogImage(context: Context, uri: Uri): CatalogImageInput {
    val resolver = context.contentResolver
    var fileName = "catalog-image"
    var declaredSize: Long? = null
    resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (nameIndex >= 0 && !cursor.isNull(nameIndex)) fileName = cursor.getString(nameIndex)
            if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) declaredSize = cursor.getLong(sizeIndex)
        }
    }
    val contentType = resolver.getType(uri)?.lowercase() ?: error("Unknown image type")
    if (contentType !in setOf("image/jpeg", "image/png", "image/webp", "image/gif")) error("Unsupported image type")
    val size = declaredSize?.takeIf { it > 0 } ?: resolver.openInputStream(uri)?.use { input ->
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            total += count
            if (total > MAX_CATALOG_IMAGE_BYTES) error("Catalog photo is larger than 20 MB")
        }
        total
    } ?: error("Could not inspect catalog photo")
    if (size <= 0L) error("Catalog photo is empty")
    if (size > MAX_CATALOG_IMAGE_BYTES) error("Catalog photo is larger than 20 MB")
    return CatalogImageInput(uri.toString(), fileName, contentType, size)
}

private fun decodeCatalogPreview(bytes: ByteArray): ImageBitmap? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    var sample = 1
    while (bounds.outWidth / sample > 1280 || bounds.outHeight / sample > 1280) sample *= 2
    val options = BitmapFactory.Options().apply { inSampleSize = sample }
    return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)?.asImageBitmap()
}

private fun formatIdr(amount: Long): String = "Rp ${String.format("%,d", amount).replace(',', '.')}"
