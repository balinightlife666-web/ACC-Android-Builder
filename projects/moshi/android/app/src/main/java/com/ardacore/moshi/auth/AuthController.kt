package com.ardacore.moshi.auth

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

class AuthController(context: Context) {
    private val api = AuthApi()
    private val vault = TokenVault(context.applicationContext)

    var session: AuthSession? by mutableStateOf(null)
        private set
    var restoring: Boolean by mutableStateOf(true)
        private set
    var busy: Boolean by mutableStateOf(false)
        private set
    var error: String? by mutableStateOf(null)
        private set

    suspend fun restore() {
        restoring = true
        val refreshToken = vault.loadRefreshToken()
        if (refreshToken == null) {
            restoring = false
            return
        }
        runCatching { api.refresh(refreshToken) }
            .onSuccess { acceptSession(it) }
            .onFailure { failure ->
                if (failure is ApiException && failure.statusCode == 401) {
                    vault.clear()
                } else {
                    error = "Could not restore the session. Check the MOSHI server connection and retry."
                }
                session = null
            }
        restoring = false
    }

    suspend fun register(username: String, displayName: String, password: String) = runBusy {
        acceptSession(api.register(username.trim(), displayName.trim(), password))
    }

    suspend fun login(username: String, password: String) = runBusy {
        acceptSession(api.login(username.trim(), password))
    }

    suspend fun setBusinessMode(enabled: Boolean) = runBusy {
        val current = session ?: return@runBusy
        val user = api.updateProfile(current, businessMode = enabled)
        session = current.copy(user = user)
    }

    suspend fun updateDisplayName(displayName: String) = runBusy {
        val current = session ?: return@runBusy
        val user = api.updateProfile(current, displayName = displayName.trim())
        session = current.copy(user = user)
    }

    suspend fun logout() {
        val current = session
        busy = true
        error = null
        if (current != null) runCatching { api.logout(current.refreshToken) }
        vault.clear()
        session = null
        busy = false
    }

    fun clearError() {
        error = null
    }

    private fun acceptSession(newSession: AuthSession) {
        vault.saveRefreshToken(newSession.refreshToken)
        session = newSession
        error = null
    }

    private suspend fun runBusy(block: suspend () -> Unit) {
        if (busy) return
        busy = true
        error = null
        try {
            block()
        } catch (t: Throwable) {
            error = t.message ?: "MOSHI could not complete the request."
        } finally {
            busy = false
        }
    }
}
