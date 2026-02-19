package com.desenrolaai.app.keyboard.accessibility

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONArray
import org.json.JSONObject

object ConversationStore {

    private const val TAG = "ConversationStore"
    private const val PREFS_NAME = "desenrola_a11y_store"
    private const val FALLBACK_PREFS_NAME = "desenrola_a11y_store_fallback"
    private const val KEY_CONVERSATIONS = "conversations"
    private const val MAX_CONVERSATIONS = 50
    private const val MAX_MESSAGES_PER_CONVERSATION = 30

    private lateinit var prefs: SharedPreferences
    private val cache = mutableMapOf<String, ParsedConversation>()
    private val listeners = mutableListOf<OnConversationUpdatedListener>()
    private var initialized = false

    interface OnConversationUpdatedListener {
        fun onConversationUpdated(key: String, conversation: ParsedConversation)
    }

    @Synchronized
    fun init(context: Context) {
        if (initialized) return

        prefs = try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create encrypted prefs, falling back", e)
            context.getSharedPreferences(FALLBACK_PREFS_NAME, Context.MODE_PRIVATE)
        }

        loadFromDisk()
        initialized = true
    }

    @Synchronized
    fun updateConversation(packageName: String, conversation: ParsedConversation) {
        val trimmed = conversation.copy(
            messages = conversation.messages.takeLast(MAX_MESSAGES_PER_CONVERSATION)
        )

        val key = buildKey(trimmed.platform, trimmed.contactName)
        cache[key] = trimmed

        // Prune oldest conversations if over the limit
        if (cache.size > MAX_CONVERSATIONS) {
            val oldest = cache.entries
                .sortedBy { it.value.timestamp }
                .take(cache.size - MAX_CONVERSATIONS)
            oldest.forEach { cache.remove(it.key) }
        }

        persistToDisk()

        // Notify listeners (copy list to avoid concurrent-modification)
        val snapshot = listeners.toList()
        snapshot.forEach { it.onConversationUpdated(key, trimmed) }
    }

    @Synchronized
    fun getConversation(platform: String, contactName: String): ParsedConversation? {
        return cache[buildKey(platform, contactName)]
    }

    @Synchronized
    fun getActiveConversation(platform: String): ParsedConversation? {
        return cache.values
            .filter { it.platform.equals(platform, ignoreCase = true) }
            .maxByOrNull { it.timestamp }
    }

    @Synchronized
    fun getAllConversations(): List<ParsedConversation> {
        return cache.values.toList()
    }

    @Synchronized
    fun addListener(listener: OnConversationUpdatedListener) {
        if (!listeners.contains(listener)) {
            listeners.add(listener)
        }
    }

    @Synchronized
    fun removeListener(listener: OnConversationUpdatedListener) {
        listeners.remove(listener)
    }

    // ──────────────────────────────────────────────
    // Serialization
    // ──────────────────────────────────────────────

    private fun persistToDisk() {
        try {
            val root = JSONArray()
            for ((_, conversation) in cache) {
                root.put(conversationToJson(conversation))
            }
            prefs.edit().putString(KEY_CONVERSATIONS, root.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist conversations", e)
        }
    }

    private fun loadFromDisk() {
        try {
            val raw = prefs.getString(KEY_CONVERSATIONS, null) ?: return
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val conv = jsonToConversation(array.getJSONObject(i))
                val key = buildKey(conv.platform, conv.contactName)
                cache[key] = conv
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load conversations from disk", e)
        }
    }

    private fun conversationToJson(conv: ParsedConversation): JSONObject {
        val obj = JSONObject()
        obj.put("contactName", conv.contactName)
        obj.put("platform", conv.platform)
        obj.put("timestamp", conv.timestamp)

        val msgs = JSONArray()
        for (msg in conv.messages) {
            val m = JSONObject()
            m.put("text", msg.text)
            m.put("isFromUser", msg.isFromUser)
            msg.timestamp?.let { m.put("timestamp", it) }
            msgs.put(m)
        }
        obj.put("messages", msgs)
        return obj
    }

    private fun jsonToConversation(obj: JSONObject): ParsedConversation {
        val msgs = mutableListOf<ParsedMessage>()
        val msgArray = obj.getJSONArray("messages")
        for (i in 0 until msgArray.length()) {
            val m = msgArray.getJSONObject(i)
            msgs.add(
                ParsedMessage(
                    text = m.getString("text"),
                    isFromUser = m.getBoolean("isFromUser"),
                    timestamp = if (m.has("timestamp")) m.getString("timestamp") else null
                )
            )
        }
        return ParsedConversation(
            contactName = obj.getString("contactName"),
            platform = obj.getString("platform"),
            messages = msgs,
            timestamp = obj.getLong("timestamp")
        )
    }

    private fun buildKey(platform: String, contactName: String): String {
        return "${platform}_${contactName}".lowercase()
    }
}
