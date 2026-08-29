package com.ardacore.moshi.push

import android.content.Context
import com.ardacore.moshi.auth.AuthSession
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class PushTokenRegistrar(context: Context) {
    private val appContext = context.applicationContext
    private val store = PushTokenStore(appContext)
    private val api = PushApi()

    suspend fun sync(session: AuthSession): Boolean {
        if (!isFirebaseConfigured(appContext)) return false
        val token = store.load() ?: currentFcmToken() ?: return false
        api.register(session.accessToken, token)
        store.save(token)
        return true
    }

    suspend fun unregister(session: AuthSession) {
        runCatching { api.unregister(session.accessToken) }
    }

    private suspend fun currentFcmToken(): String? = suspendCoroutine { continuation ->
        runCatching {
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                continuation.resume(if (task.isSuccessful) task.result else null)
            }
        }.onFailure {
            continuation.resume(null)
        }
    }

    companion object {
        fun isFirebaseConfigured(context: Context): Boolean =
            runCatching { FirebaseApp.getApps(context.applicationContext).isNotEmpty() }.getOrDefault(false)
    }
}
