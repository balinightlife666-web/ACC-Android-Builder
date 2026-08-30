package com.offgrid.mesh.core

import android.content.Context
import java.util.UUID

class DeviceIdentity(context: Context) {
    private val prefs = context.getSharedPreferences("offgrid_identity", Context.MODE_PRIVATE)
    val id: String
        get() {
            val existing = prefs.getString(KEY_ID, null)
            if (existing != null) return existing
            val created = UUID.randomUUID().toString()
            prefs.edit().putString(KEY_ID, created).apply()
            return created
        }
    val shortId: String get() = id.replace("-", "").take(12)
    companion object { private const val KEY_ID = "device_id" }
}
