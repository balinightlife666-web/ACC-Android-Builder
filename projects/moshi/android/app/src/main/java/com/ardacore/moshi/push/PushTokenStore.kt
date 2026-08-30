package com.ardacore.moshi.push

import android.content.Context

class PushTokenStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("moshi_push", Context.MODE_PRIVATE)

    fun save(token: String) {
        prefs.edit().putString("fcm_token", token).apply()
    }

    fun load(): String? = prefs.getString("fcm_token", null)?.takeIf { it.isNotBlank() }

    fun clear() {
        prefs.edit().remove("fcm_token").apply()
    }
}
