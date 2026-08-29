package com.ardacore.moshi.auth

import com.ardacore.moshi.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class AuthApi(private val baseUrl: String = BuildConfig.API_BASE_URL.trimEnd('/')) {
    suspend fun register(username: String, displayName: String, password: String): AuthSession =
        requestAuth(
            path = "/v1/auth/register",
            body = JSONObject()
                .put("username", username)
                .put("display_name", displayName)
                .put("password", password)
                .put("device_name", "MOSHI Android"),
        )

    suspend fun login(username: String, password: String): AuthSession =
        requestAuth(
            path = "/v1/auth/login",
            body = JSONObject()
                .put("username", username)
                .put("password", password)
                .put("device_name", "MOSHI Android"),
        )

    suspend fun refresh(refreshToken: String): AuthSession =
        requestAuth(
            path = "/v1/auth/refresh",
            body = JSONObject().put("refresh_token", refreshToken),
        )

    suspend fun updateProfile(
        session: AuthSession,
        displayName: String? = null,
        businessMode: Boolean? = null,
    ): MoshiUser = withContext(Dispatchers.IO) {
        val body = JSONObject()
        if (displayName != null) body.put("display_name", displayName)
        if (businessMode != null) body.put("business_mode", businessMode)
        val result = request(
            method = "PATCH",
            path = "/v1/me",
            body = body,
            accessToken = session.accessToken,
        )
        parseUser(result)
    }

    suspend fun logout(refreshToken: String) = withContext(Dispatchers.IO) {
        request(
            method = "POST",
            path = "/v1/auth/logout",
            body = JSONObject().put("refresh_token", refreshToken),
        )
        Unit
    }

    private suspend fun requestAuth(path: String, body: JSONObject): AuthSession = withContext(Dispatchers.IO) {
        val json = request(method = "POST", path = path, body = body)
        AuthSession(
            user = parseUser(json.getJSONObject("user")),
            accessToken = json.getString("access_token"),
            refreshToken = json.getString("refresh_token"),
        )
    }

    private fun request(
        method: String,
        path: String,
        body: JSONObject? = null,
        accessToken: String? = null,
    ): JSONObject {
        val connection = (URL("$baseUrl$path").openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = 10_000
            readTimeout = 15_000
            setRequestProperty("Accept", "application/json")
            if (accessToken != null) setRequestProperty("Authorization", "Bearer $accessToken")
            if (body != null) {
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                outputStream.bufferedWriter(Charsets.UTF_8).use { it.write(body.toString()) }
            }
        }

        try {
            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val text = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            if (status !in 200..299) {
                val detail = runCatching { JSONObject(text).optString("detail") }.getOrNull()
                throw ApiException(detail?.takeIf { it.isNotBlank() } ?: "MOSHI API error ($status)", status)
            }
            return if (text.isBlank()) JSONObject() else JSONObject(text)
        } finally {
            connection.disconnect()
        }
    }

    private fun parseUser(json: JSONObject): MoshiUser = MoshiUser(
        id = json.getString("id"),
        username = json.getString("username"),
        displayName = json.getString("display_name"),
        businessMode = json.getBoolean("business_mode"),
    )
}
