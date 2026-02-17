package com.desenrolaai.app.keyboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.inputmethodservice.InputMethodService
import android.net.Uri
import android.util.Base64
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import com.desenrolaai.app.keyboard.auth.AuthHelper
import com.desenrolaai.app.keyboard.data.ConversationContext
import com.desenrolaai.app.keyboard.data.availableObjectives
import com.desenrolaai.app.keyboard.data.availableTones
import com.desenrolaai.app.keyboard.network.KeyboardApiClient
import com.desenrolaai.app.keyboard.network.SuggestionParser
import com.desenrolaai.app.keyboard.ui.*
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

class DesenrolaKeyboardService : InputMethodService(), CoroutineScope {

    // Coroutine scope tied to service lifecycle
    private val job = SupervisorJob()
    override val coroutineContext = Dispatchers.Main + job

    // State
    private var currentState = KeyboardState.PROFILE_SELECTOR
    private var activeOverlay = OverlayType.NONE
    private var conversations = listOf<ConversationContext>()
    private var filteredConversations = listOf<ConversationContext>()
    private var selectedConversation: ConversationContext? = null
    private var clipboardText: String? = null
    private var consumedClipboard: String? = null
    private var suggestions = listOf<String>()
    private var searchText = ""
    private var writeOwnInitialText = ""
    private var selectedToneIndex = 0
    private var selectedObjectiveIndex = 0
    private var isLoadingProfiles = true
    private var isLoadingSuggestions = false
    private var isAnalyzingScreenshot = false
    private var screenshotBitmap: Bitmap? = null
    private var profilesError: String? = null

    // Components
    private lateinit var apiClient: KeyboardApiClient
    private lateinit var authHelper: AuthHelper

    private var containerView: FrameLayout? = null

    // MARK: - Lifecycle

    override fun onCreateInputView(): View {
        apiClient = KeyboardApiClient()
        authHelper = AuthHelper(applicationContext)

        val density = resources.displayMetrics.density
        containerView = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                (320 * density).toInt()
            )
            setBackgroundColor(Theme.bg)
        }

        if (authHelper.isAuthenticated) {
            currentState = KeyboardState.PROFILE_SELECTOR
            // Load cached profiles first for instant display
            loadCachedProfiles()
            fetchConversations()
        } else {
            currentState = KeyboardState.BASIC_MODE
            isLoadingProfiles = false
        }

        renderCurrentState()
        return containerView!!
    }

    override fun onDestroy() {
        job.cancel()
        super.onDestroy()
    }

    // MARK: - State Rendering

    private fun renderCurrentState() {
        val container = containerView ?: return
        container.removeAllViews()
        activeOverlay = OverlayType.NONE

        // Update height based on state
        val density = resources.displayMetrics.density
        val height = when (currentState) {
            KeyboardState.WRITE_OWN -> (350 * density).toInt()
            KeyboardState.PROFILE_SELECTOR -> if (searchText.isNotEmpty()) (350 * density).toInt() else (320 * density).toInt()
            else -> (320 * density).toInt()
        }
        container.layoutParams = container.layoutParams?.apply {
            this.height = height
        }

        when (currentState) {
            KeyboardState.PROFILE_SELECTOR -> renderProfileSelector(container)
            KeyboardState.AWAITING_CLIPBOARD -> renderAwaitingClipboard(container)
            KeyboardState.SUGGESTIONS -> renderSuggestions(container)
            KeyboardState.WRITE_OWN -> renderWriteOwn(container)
            KeyboardState.BASIC_MODE -> renderBasicMode(container)
            KeyboardState.SCREENSHOT_ANALYSIS -> renderScreenshotAnalysis(container)
            KeyboardState.START_CONVERSATION -> renderStartConversation(container)
        }
    }

    private fun renderProfileSelector(container: FrameLayout) {
        ProfileSelectorView(
            context = this,
            container = container,
            conversations = conversations,
            filteredConversations = filteredConversations,
            searchText = searchText,
            isLoading = isLoadingProfiles,
            error = profilesError,
            onProfileSelected = { conv -> selectProfile(conv) },
            onQuickMode = { enterBasicMode() },
            onSearchChanged = { text -> updateSearch(text) },
            onSwitchKeyboard = { switchKeyboard() }
        ).render()
    }

    private fun renderAwaitingClipboard(container: FrameLayout) {
        val conv = selectedConversation ?: return
        AwaitingClipboardView(
            context = this,
            container = container,
            conversation = conv,
            selectedObjectiveIndex = selectedObjectiveIndex,
            selectedToneIndex = selectedToneIndex,
            onBack = { goBackToProfileSelector() },
            onPaste = { handlePaste() },
            onObjectiveTap = { showObjectiveOverlay() },
            onToneTap = { showToneOverlay() },
            onSwitchKeyboard = { switchKeyboard() },
            onScreenshot = { enterScreenshotAnalysis() },
            onStartConversation = { enterStartConversation() }
        ).render()
    }

    private fun renderSuggestions(container: FrameLayout) {
        SuggestionsView(
            context = this,
            container = container,
            conversation = selectedConversation,
            clipboardText = clipboardText,
            suggestions = suggestions,
            isLoading = isLoadingSuggestions,
            selectedObjectiveIndex = selectedObjectiveIndex,
            selectedToneIndex = selectedToneIndex,
            onSuggestionTap = { text -> handleSuggestionTap(text) },
            onWriteOwn = { enterWriteOwn() },
            onRegenerate = { regenerate() },
            onObjectiveTap = { showObjectiveOverlay() },
            onToneTap = { showToneOverlay() },
            onBack = { goBackFromSuggestions() },
            onEditSuggestion = { text -> editSuggestion(text) }
        ).render()
    }

    private fun renderWriteOwn(container: FrameLayout) {
        WriteOwnView(
            context = this,
            container = container,
            conversation = selectedConversation,
            clipboardText = clipboardText,
            onBack = {
                writeOwnInitialText = ""
                currentState = KeyboardState.SUGGESTIONS
                renderCurrentState()
            },
            onInsert = { text -> insertAndTrack(text, wasAiSuggestion = false) },
            initialText = writeOwnInitialText
        ).render()
    }

    private fun renderBasicMode(container: FrameLayout) {
        BasicModeView(
            context = this,
            container = container,
            clipboardText = clipboardText,
            suggestions = suggestions,
            isLoading = isLoadingSuggestions,
            selectedObjectiveIndex = selectedObjectiveIndex,
            selectedToneIndex = selectedToneIndex,
            hasAuth = authHelper.isAuthenticated,
            onPaste = { handlePaste() },
            onGenerate = { analyzeCurrentText() },
            onSuggestionTap = { text -> handleBasicSuggestionTap(text) },
            onRegenerate = { regenerate() },
            onObjectiveTap = { showObjectiveOverlay() },
            onToneTap = { showToneOverlay() },
            onBack = { goBackToProfileSelector() },
            onSwitchKeyboard = { switchKeyboard() }
        ).render()
    }

    private fun renderScreenshotAnalysis(container: FrameLayout) {
        ScreenshotAnalysisView(
            context = this,
            container = container,
            isAnalyzing = isAnalyzingScreenshot,
            screenshotBitmap = screenshotBitmap,
            onBack = {
                isAnalyzingScreenshot = false
                screenshotBitmap = null
                currentState = KeyboardState.AWAITING_CLIPBOARD
                renderCurrentState()
            },
            onPasteScreenshot = { handlePasteScreenshot() },
            onSwitchKeyboard = { switchKeyboard() }
        ).render()
    }

    private fun renderStartConversation(container: FrameLayout) {
        StartConversationView(
            context = this,
            container = container,
            conversation = selectedConversation,
            suggestions = suggestions,
            isLoading = isLoadingSuggestions,
            selectedObjectiveIndex = selectedObjectiveIndex,
            selectedToneIndex = selectedToneIndex,
            onSuggestionTap = { text -> handleSuggestionTap(text) },
            onWriteOwn = { enterWriteOwn() },
            onRegenerate = { startConversationRequest() },
            onObjectiveTap = { showObjectiveOverlay() },
            onToneTap = { showToneOverlay() },
            onBack = {
                suggestions = emptyList()
                currentState = KeyboardState.AWAITING_CLIPBOARD
                renderCurrentState()
            },
            onSwitchKeyboard = { switchKeyboard() }
        ).render()
    }

    // MARK: - Actions

    private fun selectProfile(conv: ConversationContext) {
        selectedConversation = conv
        searchText = ""
        suggestions = emptyList()
        clipboardText = null
        consumedClipboard = null
        writeOwnInitialText = ""

        // Restore objective for this profile
        val key = objectiveKey(conv)
        selectedObjectiveIndex = authHelper.getObjective(key)

        // Go to start conversation if no messages, otherwise awaiting clipboard
        if (!conv.hasMessages) {
            currentState = KeyboardState.START_CONVERSATION
            isLoadingSuggestions = true
            renderCurrentState()
            startConversationRequest()
        } else {
            currentState = KeyboardState.AWAITING_CLIPBOARD
            renderCurrentState()
        }
    }

    private fun enterBasicMode() {
        currentState = KeyboardState.BASIC_MODE
        suggestions = emptyList()
        clipboardText = null
        consumedClipboard = null
        renderCurrentState()
    }

    private fun goBackToProfileSelector() {
        if (authHelper.isAuthenticated) {
            currentState = KeyboardState.PROFILE_SELECTOR
            selectedConversation = null
            suggestions = emptyList()
            clipboardText = null
            consumedClipboard = null
            searchText = ""
            writeOwnInitialText = ""
            renderCurrentState()
        }
    }

    private fun goBackFromSuggestions() {
        if (selectedConversation != null) {
            currentState = KeyboardState.AWAITING_CLIPBOARD
        } else {
            currentState = KeyboardState.BASIC_MODE
        }
        suggestions = emptyList()
        renderCurrentState()
    }

    private fun enterWriteOwn() {
        currentState = KeyboardState.WRITE_OWN
        renderCurrentState()
    }

    private fun editSuggestion(text: String) {
        writeOwnInitialText = text
        currentState = KeyboardState.WRITE_OWN
        renderCurrentState()
    }

    private fun enterScreenshotAnalysis() {
        isAnalyzingScreenshot = false
        screenshotBitmap = null
        currentState = KeyboardState.SCREENSHOT_ANALYSIS
        renderCurrentState()
    }

    private fun enterStartConversation() {
        suggestions = emptyList()
        isLoadingSuggestions = true
        currentState = KeyboardState.START_CONVERSATION
        renderCurrentState()
        startConversationRequest()
    }

    private fun handlePaste() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        val text = clip?.getItemAt(0)?.text?.toString()

        if (!text.isNullOrEmpty()) {
            // Guard: don't reuse the same clipboard text
            if (text == consumedClipboard) return

            clipboardText = text
            consumedClipboard = text

            if (currentState == KeyboardState.AWAITING_CLIPBOARD) {
                suggestions = emptyList()
                isLoadingSuggestions = true
                currentState = KeyboardState.SUGGESTIONS
                renderCurrentState()
                analyzeCurrentText()
            } else if (currentState == KeyboardState.BASIC_MODE) {
                suggestions = emptyList()
                renderCurrentState()
            }
        }
    }

    private fun handlePasteScreenshot() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip ?: return
        val item = clip.getItemAt(0) ?: return

        // Try to get image from clipboard
        val bitmap = getBitmapFromClipItem(item)
        if (bitmap == null) {
            // No image found
            return
        }

        screenshotBitmap = bitmap
        isAnalyzingScreenshot = true
        renderCurrentState()

        // Resize and compress
        val resized = resizeBitmap(bitmap, 1024)
        val stream = ByteArrayOutputStream()
        resized.compress(Bitmap.CompressFormat.JPEG, 50, stream)
        val base64 = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)

        analyzeScreenshot(base64)
    }

    private fun getBitmapFromClipItem(item: ClipData.Item): Bitmap? {
        // Try URI first
        val uri: Uri? = item.uri
        if (uri != null) {
            try {
                val inputStream = contentResolver.openInputStream(uri)
                if (inputStream != null) {
                    val bitmap = BitmapFactory.decodeStream(inputStream)
                    inputStream.close()
                    return bitmap
                }
            } catch (_: Exception) {}
        }
        return null
    }

    private fun resizeBitmap(bitmap: Bitmap, maxDimension: Int): Bitmap {
        val maxSide = maxOf(bitmap.width, bitmap.height)
        if (maxSide <= maxDimension) return bitmap
        val scale = maxDimension.toFloat() / maxSide
        val newWidth = (bitmap.width * scale).toInt()
        val newHeight = (bitmap.height * scale).toInt()
        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }

    private fun handleSuggestionTap(text: String) {
        // Insert into text field
        currentInputConnection?.commitText(text, 1)

        // Copy to clipboard
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("suggestion", text))

        // Mark as consumed so we don't re-detect it
        consumedClipboard = text

        // Track on server
        val conv = selectedConversation
        if (authHelper.authToken != null) {
            apiClient.sendMessage(
                backendUrl = authHelper.backendUrl,
                token = authHelper.authToken!!,
                conversationId = conv?.conversationId ?: "",
                content = text,
                wasAiSuggestion = true,
                tone = currentTone(),
                objective = currentObjective(),
                profileId = conv?.profileId
            )
        }

        // Go back to awaiting clipboard for next message
        suggestions = emptyList()
        clipboardText = null
        writeOwnInitialText = ""
        currentState = if (selectedConversation != null) KeyboardState.AWAITING_CLIPBOARD else KeyboardState.BASIC_MODE
        renderCurrentState()
    }

    private fun handleBasicSuggestionTap(text: String) {
        currentInputConnection?.commitText(text, 1)

        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("suggestion", text))
        consumedClipboard = text

        suggestions = emptyList()
        clipboardText = null
        renderCurrentState()
    }

    private fun insertAndTrack(text: String, wasAiSuggestion: Boolean) {
        currentInputConnection?.commitText(text, 1)

        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("message", text))
        consumedClipboard = text

        val conv = selectedConversation
        if (authHelper.authToken != null) {
            apiClient.sendMessage(
                backendUrl = authHelper.backendUrl,
                token = authHelper.authToken!!,
                conversationId = conv?.conversationId ?: "",
                content = text,
                wasAiSuggestion = wasAiSuggestion,
                tone = currentTone(),
                objective = currentObjective(),
                profileId = conv?.profileId
            )
        }

        suggestions = emptyList()
        clipboardText = null
        writeOwnInitialText = ""
        currentState = if (selectedConversation != null) KeyboardState.AWAITING_CLIPBOARD else KeyboardState.BASIC_MODE
        renderCurrentState()
    }

    private fun regenerate() {
        if (clipboardText != null) {
            suggestions = emptyList()
            isLoadingSuggestions = true
            renderCurrentState()
            analyzeCurrentText()
        }
    }

    private fun updateSearch(text: String) {
        searchText = text
        filteredConversations = if (text.isEmpty()) {
            conversations
        } else {
            conversations.filter {
                it.matchName.contains(text, ignoreCase = true)
            }
        }
        renderCurrentState()
    }

    private fun switchKeyboard() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        imm.showInputMethodPicker()
    }

    // MARK: - Overlays

    private fun showObjectiveOverlay() {
        val container = containerView ?: return
        activeOverlay = OverlayType.OBJECTIVE_SELECTOR
        OverlayViews.showObjectiveOverlay(
            context = this,
            container = container,
            selectedIndex = selectedObjectiveIndex,
            onSelect = { index ->
                selectedObjectiveIndex = index
                activeOverlay = OverlayType.NONE

                // Save objective per profile
                selectedConversation?.let {
                    authHelper.setObjective(objectiveKey(it), index)
                }

                // Auto-regenerate if in suggestions/start conversation
                if (currentState == KeyboardState.SUGGESTIONS && clipboardText != null) {
                    suggestions = emptyList()
                    isLoadingSuggestions = true
                    renderCurrentState()
                    analyzeCurrentText()
                } else if (currentState == KeyboardState.START_CONVERSATION) {
                    suggestions = emptyList()
                    isLoadingSuggestions = true
                    renderCurrentState()
                    startConversationRequest()
                } else {
                    renderCurrentState()
                }
            },
            onClose = {
                activeOverlay = OverlayType.NONE
                renderCurrentState()
            }
        )
    }

    private fun showToneOverlay() {
        val container = containerView ?: return
        activeOverlay = OverlayType.TONE_SELECTOR
        OverlayViews.showToneOverlay(
            context = this,
            container = container,
            selectedIndex = selectedToneIndex,
            onSelect = { index ->
                val previousIndex = selectedToneIndex
                selectedToneIndex = index
                activeOverlay = OverlayType.NONE

                if (previousIndex != index) {
                    if (currentState == KeyboardState.SUGGESTIONS && clipboardText != null) {
                        suggestions = emptyList()
                        isLoadingSuggestions = true
                        renderCurrentState()
                        analyzeCurrentText()
                    } else if (currentState == KeyboardState.START_CONVERSATION) {
                        suggestions = emptyList()
                        isLoadingSuggestions = true
                        renderCurrentState()
                        startConversationRequest()
                    } else {
                        renderCurrentState()
                    }
                } else {
                    renderCurrentState()
                }
            },
            onClose = {
                activeOverlay = OverlayType.NONE
                renderCurrentState()
            }
        )
    }

    // MARK: - Network

    private fun fetchConversations() {
        val token = authHelper.authToken ?: return
        isLoadingProfiles = true
        profilesError = null

        launch {
            val result = apiClient.fetchConversations(authHelper.backendUrl, token)
            result.onSuccess { convList ->
                conversations = convList
                filteredConversations = convList
                isLoadingProfiles = false
                profilesError = null

                // Cache profiles (without face images)
                cacheProfiles(convList)

                renderCurrentState()
            }.onFailure { e ->
                isLoadingProfiles = false
                profilesError = if (conversations.isEmpty()) "Erro ao carregar perfis: ${e.message}" else null
                renderCurrentState()
            }
        }
    }

    private fun analyzeCurrentText() {
        val text = clipboardText ?: return
        isLoadingSuggestions = true

        launch {
            val result = apiClient.analyzeText(
                backendUrl = authHelper.backendUrl,
                token = authHelper.authToken,
                text = text,
                tone = currentTone(),
                conversationId = selectedConversation?.conversationId,
                objective = currentObjective()
            )

            result.onSuccess { analysis ->
                suggestions = SuggestionParser.parse(analysis)
                isLoadingSuggestions = false
                renderCurrentState()
            }.onFailure { e ->
                suggestions = listOf("Erro: ${e.message ?: "Tente novamente"}")
                isLoadingSuggestions = false
                renderCurrentState()
            }
        }
    }

    private fun analyzeScreenshot(imageBase64: String) {
        val token = authHelper.authToken ?: return

        launch {
            val result = apiClient.analyzeScreenshot(
                backendUrl = authHelper.backendUrl,
                token = token,
                imageBase64 = imageBase64,
                conversationId = selectedConversation?.conversationId
            )

            result.onSuccess { analysis ->
                suggestions = SuggestionParser.parse(analysis)
                isAnalyzingScreenshot = false
                currentState = KeyboardState.SUGGESTIONS
                renderCurrentState()
            }.onFailure { e ->
                suggestions = listOf("Erro: ${e.message ?: "Tente novamente"}")
                isAnalyzingScreenshot = false
                currentState = KeyboardState.SUGGESTIONS
                renderCurrentState()
            }
        }
    }

    private fun startConversationRequest() {
        val token = authHelper.authToken ?: return
        isLoadingSuggestions = true
        suggestions = emptyList()

        launch {
            val result = apiClient.startConversation(
                backendUrl = authHelper.backendUrl,
                token = token,
                conversationId = selectedConversation?.conversationId,
                profileId = selectedConversation?.profileId,
                objective = currentObjective(),
                tone = currentTone()
            )

            result.onSuccess { analysis ->
                suggestions = SuggestionParser.parse(analysis)
                isLoadingSuggestions = false
                renderCurrentState()
            }.onFailure { e ->
                suggestions = listOf("Erro: ${e.message ?: "Tente novamente"}")
                isLoadingSuggestions = false
                renderCurrentState()
            }
        }
    }

    // MARK: - Profile Caching

    private fun loadCachedProfiles() {
        val cached = authHelper.getCachedProfiles() ?: return
        try {
            val arr = JSONArray(cached)
            val list = mutableListOf<ConversationContext>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                list.add(ConversationContext(
                    conversationId = obj.optString("conversationId", null),
                    profileId = obj.optString("profileId", null),
                    matchName = obj.optString("matchName", "?"),
                    platform = obj.optString("platform", ""),
                    lastMessage = obj.optString("lastMessage", null),
                    faceImageBase64 = null, // Don't cache face images
                    hasMessages = obj.optBoolean("hasMessages", true)
                ))
            }
            if (list.isNotEmpty()) {
                conversations = list
                filteredConversations = list
                isLoadingProfiles = false
            }
        } catch (_: Exception) {}
    }

    private fun cacheProfiles(profiles: List<ConversationContext>) {
        try {
            val arr = JSONArray()
            for (p in profiles) {
                arr.put(JSONObject().apply {
                    put("conversationId", p.conversationId ?: "")
                    put("profileId", p.profileId ?: "")
                    put("matchName", p.matchName)
                    put("platform", p.platform)
                    put("lastMessage", p.lastMessage ?: "")
                    put("hasMessages", p.hasMessages)
                })
            }
            authHelper.setCachedProfiles(arr.toString())
        } catch (_: Exception) {}
    }

    // MARK: - Helpers

    private fun objectiveKey(conv: ConversationContext): String {
        return "${conv.matchName}_${conv.platform}".lowercase().replace(" ", "_")
    }

    private fun currentTone(): String {
        return availableTones.getOrNull(selectedToneIndex)?.id ?: "automatico"
    }

    private fun currentObjective(): String {
        return availableObjectives.getOrNull(selectedObjectiveIndex)?.id ?: "automatico"
    }
}
