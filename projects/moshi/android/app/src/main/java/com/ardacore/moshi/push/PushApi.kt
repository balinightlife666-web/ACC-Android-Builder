package com.ardacore.moshi.push

import com.ardacore.moshi.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class PushApi(private val baseUrl: String = BuildConfig.API_BASE_URL.trimEnd('/')) {
    suspend fun register(accessToken: String, token: String) = withContext(Dispatchers.IO) {
        val connection = (URL("$baseUrl/v1/devices/push").openConnection() as HttpURLConnection).apply {
            requestMethod = "PUT"
            connectTimeout = 10_000
            readTimeout = 15_000
            doOutput = true
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("Authorization", "Bearer $accessToken")
        }
        try {
            val payload = JSONObject()
                .put("provider", "fcm")
                .put("platform", "android")
                .put("token", token)
            connection.outputStream.bufferedWriter(Charsets.UTF_8).use { it.write(payload.toString()) }
            val status = connection.responseCode
            if (status !in 200..299) {
                val detail = connection.errorStream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }
                error("Push registration failed ($status)${detail?.let { ": $it" }.orEmpty()}")
            }
        } finally {
            connection.disconnect()
        }
    }

    suspend fun unregister(accessToken: String) = withContext(Dispatchers.IO) {
        val connection = (URL("$baseUrl/v1/devices/push").openConnection() as HttpURLConnection).apply {
            requestMethod = "DELETE"
            connectTimeout = 10_000
            readTimeout = 15_000
            setRequestProperty("Authorization", "Bearer $accessToken")
        }
        try {
            connection.responseCode
        } finally {
            connection.disconnect()
        }
    }
}
