package com.desenrolaai.app.keyboard.auth

import android.content.Context
import android.content.SharedPreferences

/**
 * Reads auth token, userId, and backendUrl from SharedPreferences.
 * The main Flutter app writes these values via MethodChannel → MainActivity.
 * The IME service reads them here.
 *
 * Since the IME service runs in the same process (same package), direct
 * SharedPreferences access works reliably. If process isolation becomes
 * an issue on specific OEMs, migrate to ContentProvider.
 */
class AuthHelper(private val context: Context) {

    companion object {
        private const val PREFS_NAME = "DesenrolaKeyboardPrefs"
        private const val KEY_AUTH_TOKEN = "authToken"
        private const val KEY_USER_ID = "userId"
        private const val KEY_BACKEND_URL = "backendUrl"
        private const val KEY_DEFAULT_TONE = "defaultTone"
        private const val DEFAULT_BACKEND_URL = "https://dating-app-production-ac43.up.railway.app"
    }

    private val prefs: SharedPreferences
        get() = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    val authToken: String?
        get() = prefs.getString(KEY_AUTH_TOKEN, null)

    val userId: String?
        get() = prefs.getString(KEY_USER_ID, null)

    val backendUrl: String
        get() = prefs.getString(KEY_BACKEND_URL, null) ?: DEFAULT_BACKEND_URL

    val defaultTone: String?
        get() = prefs.getString(KEY_DEFAULT_TONE, null)

    val isAuthenticated: Boolean
        get() = !authToken.isNullOrEmpty()

    fun saveAuth(authToken: String, userId: String) {
        prefs.edit()
            .putString(KEY_AUTH_TOKEN, authToken)
            .putString(KEY_USER_ID, userId)
            .apply()
    }

    fun clearAuth() {
        prefs.edit()
            .remove(KEY_AUTH_TOKEN)
            .remove(KEY_USER_ID)
            .apply()
    }

    fun setBackendUrl(url: String) {
        prefs.edit()
            .putString(KEY_BACKEND_URL, url)
            .apply()
    }

    fun setDefaultTone(tone: String) {
        prefs.edit()
            .putString(KEY_DEFAULT_TONE, tone)
            .apply()
    }
}
