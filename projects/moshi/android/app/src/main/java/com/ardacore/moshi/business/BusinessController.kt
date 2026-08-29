package com.ardacore.moshi.business

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.ardacore.moshi.auth.AuthSession
import com.ardacore.moshi.chat.ChatApi
import com.ardacore.moshi.chat.local.ContentUriRequestBody
import java.util.UUID

class BusinessController(
    private val session: AuthSession,
    context: Context,
    private val api: BusinessApi = BusinessApi(),
    private val chatApi: ChatApi = ChatApi(),
) {
    private val appContext = context.applicationContext

    var profile: BusinessProfile? by mutableStateOf(null)
        private set
    var catalog: List<CatalogItem> by mutableStateOf(emptyList())
        private set
    var lastShareMessage: String? by mutableStateOf(null)
        private set
    var busy: Boolean by mutableStateOf(false)
        private set
    var error: String? by mutableStateOf(null)
        private set

    suspend fun load() {
        if (!session.user.businessMode) {
            profile = null
            catalog = emptyList()
            return
        }
        runBusy {
            profile = api.myProfile(session.accessToken)
            catalog = api.myCatalog(session.accessToken)
        }
    }

    suspend fun saveProfile(
        businessName: String,
        category: String,
        description: String,
        address: String,
        hours: String,
    ): Boolean = runBusyResult {
        profile = api.saveProfile(
            accessToken = session.accessToken,
            businessName = businessName.trim(),
            category = category.trim(),
            description = description.trim(),
            address = address.trim(),
            hours = hours.trim(),
        )
        catalog = api.myCatalog(session.accessToken)
        true
    } ?: false

    suspend fun saveCatalogItem(
        editing: CatalogItem?,
        kind: String,
        title: String,
        description: String,
        priceAmount: Long?,
        availability: String,
        stockQty: Int?,
        image: CatalogImageInput?,
    ): Boolean = runBusyResult {
        val imageAttachmentId = image?.let { input ->
            val body = ContentUriRequestBody(
                context = appContext,
                uriText = input.uri,
                contentType = input.contentType,
                expectedSize = input.sizeBytes,
            )
            val ticket = chatApi.initUpload(
                accessToken = session.accessToken,
                kind = "image",
                fileName = input.fileName,
                contentType = input.contentType,
                sizeBytes = input.sizeBytes,
            )
            chatApi.uploadContent(session.accessToken, ticket, body).id
        }

        if (editing == null) {
            api.createItem(
                accessToken = session.accessToken,
                kind = kind,
                title = title.trim(),
                description = description.trim(),
                priceAmount = priceAmount,
                availability = availability,
                stockQty = if (kind == "product") stockQty else null,
                imageAttachmentId = imageAttachmentId,
            )
        } else {
            api.updateItem(
                accessToken = session.accessToken,
                itemId = editing.id,
                kind = kind,
                title = title.trim(),
                description = description.trim(),
                priceAmount = priceAmount,
                availability = availability,
                stockQty = if (kind == "product") stockQty else null,
                imageAttachmentId = imageAttachmentId,
            )
        }
        catalog = api.myCatalog(session.accessToken)
        true
    } ?: false

    suspend fun deleteCatalogItem(item: CatalogItem): Boolean = runBusyResult {
        api.deleteItem(session.accessToken, item.id)
        catalog = api.myCatalog(session.accessToken)
        true
    } ?: false

    suspend fun shareCatalogItem(item: CatalogItem, username: String): Boolean = runBusyResult {
        val cleanUsername = username.trim().removePrefix("@")
        require(cleanUsername.isNotBlank()) { "Enter a MOSHI username" }
        val conversation = chatApi.createDirect(session.accessToken, cleanUsername)
        chatApi.shareCatalogCard(
            accessToken = session.accessToken,
            conversationId = conversation.id,
            clientMessageId = UUID.randomUUID().toString(),
            catalogItemId = item.id,
        )
        lastShareMessage = "${item.title} shared to @$cleanUsername"
        true
    } ?: false

    suspend fun loadCatalogImage(item: CatalogItem): ByteArray? {
        val path = item.imagePath ?: return null
        return runCatching { api.catalogImage(session.accessToken, path) }.getOrNull()
    }

    fun clearShareMessage() {
        lastShareMessage = null
    }

    fun clearError() {
        error = null
    }

    private suspend fun runBusy(block: suspend () -> Unit) {
        if (busy) return
        busy = true
        error = null
        try {
            block()
        } catch (t: Throwable) {
            error = t.message ?: "MOSHI business request failed"
        } finally {
            busy = false
        }
    }

    private suspend fun <T> runBusyResult(block: suspend () -> T): T? {
        if (busy) return null
        busy = true
        error = null
        return try {
            block()
        } catch (t: Throwable) {
            error = t.message ?: "MOSHI business request failed"
            null
        } finally {
            busy = false
        }
    }
}
