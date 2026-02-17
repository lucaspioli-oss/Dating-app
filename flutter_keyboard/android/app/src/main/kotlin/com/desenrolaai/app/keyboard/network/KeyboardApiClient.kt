package com.desenrolaai.app.keyboard.network

import com.desenrolaai.app.keyboard.data.ConversationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class KeyboardApiClient {

    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()

    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    /**
     * GET /keyboard/context - fetch conversations list
     */
    suspend fun fetchConversations(
        backendUrl: String,
        token: String
    ): Result<List<ConversationContext>> = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("$backendUrl/keyboard/context")
                .addHeader("Authorization", "Bearer $token")
                .get()
                .build()

            val response = client.newCall(request).execute()
            val body = response.body?.string() ?: ""

            if (!response.isSuccessful) {
                return@withContext Result.failure(Exception("HTTP ${response.code}: $body"))
            }

            val json = JSONObject(body)
            val conversationsArray = json.optJSONArray("conversations") ?: run {
                return@withContext Result.success(emptyList())
            }

            val conversations = mutableListOf<ConversationContext>()
            for (i in 0 until conversationsArray.length()) {
                val obj = conversationsArray.getJSONObject(i)
                conversations.add(
                    ConversationContext(
                        conversationId = obj.optString("conversationId", null),
                        profileId = obj.optString("profileId", null),
                        matchName = obj.optString("matchName", "?"),
                        platform = obj.optString("platform", ""),
                        lastMessage = obj.optString("lastMessage", null),
                        faceImageBase64 = obj.optString("faceImageBase64", null)
                    )
                )
            }

            Result.success(conversations)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * POST /analyze - send text for AI suggestions
     */
    suspend fun analyzeText(
        backendUrl: String,
        token: String?,
        text: String,
        tone: String,
        conversationId: String?,
        objective: String?
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            val jsonBody = JSONObject().apply {
                put("text", text)
                put("tone", tone)
                if (!conversationId.isNullOrEmpty()) put("conversationId", conversationId)
                if (!objective.isNullOrEmpty()) put("objective", objective)
            }

            val requestBuilder = Request.Builder()
                .url("$backendUrl/analyze")
                .addHeader("Content-Type", "application/json")
                .post(jsonBody.toString().toRequestBody(jsonMediaType))

            if (!token.isNullOrEmpty()) {
                requestBuilder.addHeader("Authorization", "Bearer $token")
            }

            val response = client.newCall(requestBuilder.build()).execute()
            val body = response.body?.string() ?: ""

            if (!response.isSuccessful) {
                return@withContext Result.failure(Exception("HTTP ${response.code}: $body"))
            }

            val json = JSONObject(body)
            val analysis = json.optString("analysis", "")

            if (analysis.isEmpty()) {
                return@withContext Result.failure(Exception("Empty analysis response"))
            }

            Result.success(analysis)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * POST /keyboard/send-message - track sent message (fire-and-forget)
     */
    fun sendMessage(
        backendUrl: String,
        token: String,
        conversationId: String,
        content: String,
        wasAiSuggestion: Boolean,
        tone: String,
        objective: String
    ) {
        val jsonBody = JSONObject().apply {
            put("conversationId", conversationId)
            put("content", content)
            put("wasAiSuggestion", wasAiSuggestion)
            put("tone", tone)
            put("objective", objective)
        }

        val request = Request.Builder()
            .url("$backendUrl/keyboard/send-message")
            .addHeader("Content-Type", "application/json")
            .addHeader("Authorization", "Bearer $token")
            .post(jsonBody.toString().toRequestBody(jsonMediaType))
            .build()

        // Fire-and-forget using OkHttp async
        client.newCall(request).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: java.io.IOException) {
                // Silently ignore - non-critical tracking
            }
            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                response.close()
            }
        })
    }
}
