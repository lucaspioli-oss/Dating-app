package com.desenrolaai.app.keyboard.auth

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class AuthHelper(private val context: Context) {

    companion object {
        private const val TAG = "AuthHelper"
        private const val ENCRYPTED_PREFS_NAME = "DesenrolaEncryptedPrefs"
        private const val LEGACY_PREFS_NAME = "DesenrolaKeyboardPrefs"
        private const val KEY_AUTH_TOKEN = "authToken"
        private const val KEY_USER_ID = "userId"
        private const val KEY_BACKEND_URL = "backendUrl"
        private const val KEY_DEFAULT_TONE = "defaultTone"
        private const val DEFAULT_BACKEND_URL = "https://dating-app-production-ac43.up.railway.app"
    }

    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    private val encryptedPrefs: SharedPreferences by lazy {
        try {
            EncryptedSharedPreferences.create(
                context,
                ENCRYPTED_PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create encrypted prefs, falling back", e)
            context.getSharedPreferences(LEGACY_PREFS_NAME, Context.MODE_PRIVATE)
        }
    }

    init {
        migrateFromLegacy()
    }

    private fun migrateFromLegacy() {
        try {
            val legacy = context.getSharedPreferences(LEGACY_PREFS_NAME, Context.MODE_PRIVATE)
            val legacyToken = legacy.getString(KEY_AUTH_TOKEN, null)
            if (legacyToken != null) {
                // Migrate data to encrypted storage
                encryptedPrefs.edit()
                    .putString(KEY_AUTH_TOKEN, legacyToken)
                    .putString(KEY_USER_ID, legacy.getString(KEY_USER_ID, null))
                    .putString(KEY_BACKEND_URL, legacy.getString(KEY_BACKEND_URL, null))
                    .putString(KEY_DEFAULT_TONE, legacy.getString(KEY_DEFAULT_TONE, null))
                    .apply()

                // Copy objective and cache keys
                legacy.all.forEach { (key, value) ->
                    if (key.startsWith("kb_obj_") || key == "kb_cachedProfiles") {
                        when (value) {
                            is Int -> encryptedPrefs.edit().putInt(key, value).apply()
                            is String -> encryptedPrefs.edit().putString(key, value).apply()
                        }
                    }
                }

                // Clear legacy prefs
                legacy.edit().clear().apply()
                Log.d(TAG, "Migrated from legacy to encrypted prefs")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Migration failed", e)
        }
    }

    val authToken: String?
        get() = encryptedPrefs.getString(KEY_AUTH_TOKEN, null)

    val userId: String?
        get() = encryptedPrefs.getString(KEY_USER_ID, null)

    val backendUrl: String
        get() = encryptedPrefs.getString(KEY_BACKEND_URL, null) ?: DEFAULT_BACKEND_URL

    val defaultTone: String?
        get() = encryptedPrefs.getString(KEY_DEFAULT_TONE, null)

    val isAuthenticated: Boolean
        get() = !authToken.isNullOrEmpty()

    fun saveAuth(authToken: String, userId: String) {
        encryptedPrefs.edit()
            .putString(KEY_AUTH_TOKEN, authToken)
            .putString(KEY_USER_ID, userId)
            .apply()
    }

    fun clearAuth() {
        encryptedPrefs.edit()
            .remove(KEY_AUTH_TOKEN)
            .remove(KEY_USER_ID)
            .apply()
    }

    fun setBackendUrl(url: String) {
        encryptedPrefs.edit()
            .putString(KEY_BACKEND_URL, url)
            .apply()
    }

    fun setDefaultTone(tone: String) {
        encryptedPrefs.edit()
            .putString(KEY_DEFAULT_TONE, tone)
            .apply()
    }

    fun getObjective(profileKey: String): Int {
        return encryptedPrefs.getInt("kb_obj_$profileKey", 0)
    }

    fun setObjective(profileKey: String, index: Int) {
        encryptedPrefs.edit().putInt("kb_obj_$profileKey", index).apply()
    }

    fun getCachedProfiles(): String? {
        return encryptedPrefs.getString("kb_cachedProfiles", null)
    }

    fun setCachedProfiles(json: String) {
        encryptedPrefs.edit().putString("kb_cachedProfiles", json).apply()
    }
}
