package com.ardacore.moshi.business

import com.ardacore.moshi.BuildConfig
import com.ardacore.moshi.auth.ApiException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class BusinessApi(
    private val baseUrl: String = BuildConfig.API_BASE_URL.trimEnd('/'),
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build(),
) {
    private val jsonType = "application/json; charset=utf-8".toMediaType()

    suspend fun myProfile(accessToken: String): BusinessProfile? = withContext(Dispatchers.IO) {
        try {
            parseProfile(JSONObject(request("GET", "/v1/business/me/profile", accessToken)))
        } catch (error: ApiException) {
            if (error.statusCode == 404) null else throw error
        }
    }

    suspend fun saveProfile(
        accessToken: String,
        businessName: String,
        category: String,
        description: String,
        address: String,
        hours: String,
    ): BusinessProfile = withContext(Dispatchers.IO) {
        val payload = JSONObject()
            .put("business_name", businessName)
            .put("category", category)
            .put("description", description)
            .put("address", address)
            .put("hours", hours)
        parseProfile(JSONObject(request("PUT", "/v1/business/me/profile", accessToken, payload)))
    }

    suspend fun myCatalog(accessToken: String): List<CatalogItem> = withContext(Dispatchers.IO) {
        parseCatalog(request("GET", "/v1/business/me/catalog", accessToken))
    }

    suspend fun createItem(
        accessToken: String,
        kind: String,
        title: String,
        description: String,
        priceAmount: Long?,
        availability: String,
        stockQty: Int?,
        imageAttachmentId: String?,
    ): CatalogItem = withContext(Dispatchers.IO) {
        val payload = JSONObject()
            .put("kind", kind)
            .put("title", title)
            .put("description", description)
            .put("currency", "IDR")
            .put("availability", availability)
        payload.put("price_amount", priceAmount ?: JSONObject.NULL)
        if (kind == "product") payload.put("stock_qty", stockQty ?: JSONObject.NULL)
        if (imageAttachmentId != null) payload.put("image_attachment_id", imageAttachmentId)
        parseItem(JSONObject(request("POST", "/v1/business/catalog", accessToken, payload)))
    }

    suspend fun updateItem(
        accessToken: String,
        itemId: String,
        kind: String,
        title: String,
        description: String,
        priceAmount: Long?,
        availability: String,
        stockQty: Int?,
        imageAttachmentId: String? = null,
    ): CatalogItem = withContext(Dispatchers.IO) {
        val payload = JSONObject()
            .put("kind", kind)
            .put("title", title)
            .put("description", description)
            .put("currency", "IDR")
            .put("availability", availability)
            .put("price_amount", priceAmount ?: JSONObject.NULL)
        if (kind == "product") payload.put("stock_qty", stockQty ?: JSONObject.NULL)
        if (imageAttachmentId != null) payload.put("image_attachment_id", imageAttachmentId)
        parseItem(JSONObject(request("PATCH", "/v1/business/catalog/$itemId", accessToken, payload)))
    }

    suspend fun deleteItem(accessToken: String, itemId: String) = withContext(Dispatchers.IO) {
        request("DELETE", "/v1/business/catalog/$itemId", accessToken)
        Unit
    }

    suspend fun catalogImage(accessToken: String, path: String): ByteArray = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url(absoluteUrl(path))
            .header("Authorization", "Bearer $accessToken")
            .get()
            .build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throwApi(response.code, response.body?.string().orEmpty())
            response.body?.bytes()?.takeIf { it.isNotEmpty() } ?: error("Catalog image is empty")
        }
    }

    private fun request(method: String, path: String, accessToken: String, body: JSONObject? = null): String {
        val requestBody = body?.toString()?.toRequestBody(jsonType)
        val builder = Request.Builder()
            .url(absoluteUrl(path))
            .header("Accept", "application/json")
            .header("Authorization", "Bearer $accessToken")
        when (method) {
            "GET" -> builder.get()
            "POST" -> builder.post(requestBody ?: ByteArray(0).toRequestBody(null))
            "PUT" -> builder.put(requestBody ?: ByteArray(0).toRequestBody(null))
            "PATCH" -> builder.patch(requestBody ?: ByteArray(0).toRequestBody(null))
            "DELETE" -> builder.delete()
            else -> error("Unsupported method $method")
        }
        client.newCall(builder.build()).execute().use { response ->
            val text = response.body?.string().orEmpty()
            if (!response.isSuccessful) throwApi(response.code, text)
            return text
        }
    }

    private fun throwApi(code: Int, text: String): Nothing {
        val detail = runCatching { JSONObject(text).optString("detail") }.getOrNull()
        throw ApiException(detail?.takeIf { it.isNotBlank() } ?: "MOSHI business API error ($code)", code)
    }

    private fun absoluteUrl(path: String): String = if (path.startsWith("http://") || path.startsWith("https://")) path else "$baseUrl$path"

    private fun parseProfile(json: JSONObject) = BusinessProfile(
        businessName = json.getString("business_name"),
        category = json.optString("category"),
        description = json.optString("description"),
        address = json.optString("address"),
        hours = json.optString("hours"),
    )

    private fun parseCatalog(text: String): List<CatalogItem> {
        val array = JSONArray(text)
        return List(array.length()) { index -> parseItem(array.getJSONObject(index)) }
    }

    private fun parseItem(json: JSONObject) = CatalogItem(
        id = json.getString("id"),
        ownerId = json.getString("owner_id"),
        kind = json.getString("kind"),
        title = json.getString("title"),
        description = json.optString("description"),
        priceAmount = if (json.isNull("price_amount")) null else json.getLong("price_amount"),
        currency = json.optString("currency", "IDR"),
        availability = json.optString("availability", "available"),
        stockQty = if (json.isNull("stock_qty")) null else json.getInt("stock_qty"),
        imagePath = json.optString("image_path").takeIf { it.isNotBlank() && it != "null" },
        isActive = json.optBoolean("is_active", true),
    )
}
