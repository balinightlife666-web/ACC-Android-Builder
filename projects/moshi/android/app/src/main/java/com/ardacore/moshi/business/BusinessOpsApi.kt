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

data class BusinessOrderLine(
    val title: String,
    val quantity: Int,
    val unitPriceAmount: Long?,
    val currency: String,
)

data class BusinessOrder(
    val id: String,
    val conversationId: String,
    val buyerId: String,
    val sellerId: String,
    val status: String,
    val note: String,
    val totalAmount: Long?,
    val currency: String,
    val items: List<BusinessOrderLine>,
)

data class QuickReplyItem(val id: String, val shortcut: String, val title: String, val body: String)
data class CustomerLabel(val id: String, val name: String)

class BusinessOpsApi(
    private val baseUrl: String = BuildConfig.API_BASE_URL.trimEnd('/'),
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build(),
) {
    private val jsonType = "application/json; charset=utf-8".toMediaType()

    suspend fun orders(token: String): List<BusinessOrder> = withContext(Dispatchers.IO) {
        val array = JSONArray(request("GET", "/v1/orders/drafts", token))
        List(array.length()) { parseOrder(array.getJSONObject(it)) }
    }

    suspend fun updateOrderStatus(token: String, orderId: String, status: String): BusinessOrder = withContext(Dispatchers.IO) {
        parseOrder(JSONObject(request("PATCH", "/v1/orders/$orderId/status", token, JSONObject().put("status", status))))
    }

    suspend fun quickReplies(token: String): List<QuickReplyItem> = withContext(Dispatchers.IO) {
        parseQuickReplies(request("GET", "/v1/business/quick-replies", token))
    }

    suspend fun createQuickReply(token: String, shortcut: String, title: String, body: String): QuickReplyItem = withContext(Dispatchers.IO) {
        parseQuickReply(
            JSONObject(
                request(
                    "POST",
                    "/v1/business/quick-replies",
                    token,
                    JSONObject().put("shortcut", shortcut).put("title", title).put("body", body),
                )
            )
        )
    }

    suspend fun deleteQuickReply(token: String, id: String) = withContext(Dispatchers.IO) {
        request("DELETE", "/v1/business/quick-replies/$id", token)
        Unit
    }

    suspend fun labels(token: String): List<CustomerLabel> = withContext(Dispatchers.IO) {
        parseLabels(request("GET", "/v1/business/labels", token))
    }

    suspend fun createLabel(token: String, name: String): CustomerLabel = withContext(Dispatchers.IO) {
        parseLabel(JSONObject(request("POST", "/v1/business/labels", token, JSONObject().put("name", name))))
    }

    suspend fun deleteLabel(token: String, id: String) = withContext(Dispatchers.IO) {
        request("DELETE", "/v1/business/labels/$id", token)
        Unit
    }

    suspend fun customerLabels(token: String, username: String): List<CustomerLabel> = withContext(Dispatchers.IO) {
        parseLabels(request("GET", "/v1/business/customers/${clean(username)}/labels", token))
    }

    suspend fun assignLabel(token: String, username: String, labelId: String): List<CustomerLabel> = withContext(Dispatchers.IO) {
        parseLabels(request("POST", "/v1/business/customers/${clean(username)}/labels/$labelId", token))
    }

    suspend fun removeLabel(token: String, username: String, labelId: String): List<CustomerLabel> = withContext(Dispatchers.IO) {
        parseLabels(request("DELETE", "/v1/business/customers/${clean(username)}/labels/$labelId", token))
    }

    private fun clean(username: String) = username.trim().removePrefix("@").replace("/", "")

    private fun request(method: String, path: String, token: String, body: JSONObject? = null): String {
        val requestBody = body?.toString()?.toRequestBody(jsonType)
        val builder = Request.Builder()
            .url("$baseUrl$path")
            .header("Accept", "application/json")
            .header("Authorization", "Bearer $token")
        when (method) {
            "GET" -> builder.get()
            "POST" -> builder.post(requestBody ?: ByteArray(0).toRequestBody(null))
            "PATCH" -> builder.patch(requestBody ?: ByteArray(0).toRequestBody(null))
            "DELETE" -> builder.delete()
            else -> error("Unsupported method $method")
        }
        client.newCall(builder.build()).execute().use { response ->
            val text = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                val detail = runCatching { JSONObject(text).optString("detail") }.getOrNull()
                throw ApiException(detail?.takeIf { it.isNotBlank() } ?: "MOSHI business ops error (${response.code})", response.code)
            }
            return text
        }
    }

    private fun parseOrder(json: JSONObject): BusinessOrder {
        val itemsJson = json.optJSONArray("items") ?: JSONArray()
        val lines = List(itemsJson.length()) { index ->
            val item = itemsJson.getJSONObject(index)
            BusinessOrderLine(
                title = item.getString("title"),
                quantity = item.optInt("quantity", 1),
                unitPriceAmount = if (item.isNull("unit_price_amount")) null else item.getLong("unit_price_amount"),
                currency = item.optString("currency", "IDR"),
            )
        }
        return BusinessOrder(
            id = json.getString("id"),
            conversationId = json.getString("conversation_id"),
            buyerId = json.getString("buyer_id"),
            sellerId = json.getString("seller_id"),
            status = json.getString("status"),
            note = json.optString("note"),
            totalAmount = if (json.isNull("total_amount")) null else json.getLong("total_amount"),
            currency = json.optString("currency", "IDR"),
            items = lines,
        )
    }

    private fun parseQuickReplies(text: String): List<QuickReplyItem> {
        val array = JSONArray(text)
        return List(array.length()) { parseQuickReply(array.getJSONObject(it)) }
    }

    private fun parseQuickReply(json: JSONObject) = QuickReplyItem(
        id = json.getString("id"),
        shortcut = json.getString("shortcut"),
        title = json.getString("title"),
        body = json.getString("body"),
    )

    private fun parseLabels(text: String): List<CustomerLabel> {
        val array = JSONArray(text)
        return List(array.length()) { parseLabel(array.getJSONObject(it)) }
    }

    private fun parseLabel(json: JSONObject) = CustomerLabel(id = json.getString("id"), name = json.getString("name"))
}
