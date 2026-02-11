package com.desenrolaai.app.keyboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.inputmethodservice.InputMethodService
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
    private var suggestions = listOf<String>()
    private var searchText = ""
    private var selectedToneIndex = 0
    private var selectedObjectiveIndex = 0
    private var isLoadingProfiles = true
    private var isLoadingSuggestions = false
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
                (220 * density).toInt()
            )
            setBackgroundColor(Theme.bg)
        }

        if (authHelper.isAuthenticated) {
            currentState = KeyboardState.PROFILE_SELECTOR
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

        when (currentState) {
            KeyboardState.PROFILE_SELECTOR -> renderProfileSelector(container)
            KeyboardState.AWAITING_CLIPBOARD -> renderAwaitingClipboard(container)
            KeyboardState.SUGGESTIONS -> renderSuggestions(container)
            KeyboardState.WRITE_OWN -> renderWriteOwn(container)
            KeyboardState.BASIC_MODE -> renderBasicMode(container)
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
            onSwitchKeyboard = { switchKeyboard() }
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
            onBack = { goBackFromSuggestions() }
        ).render()
    }

    private fun renderWriteOwn(container: FrameLayout) {
        WriteOwnView(
            context = this,
            container = container,
            conversation = selectedConversation,
            clipboardText = clipboardText,
            onBack = { currentState = KeyboardState.SUGGESTIONS; renderCurrentState() },
            onInsert = { text -> insertAndTrack(text, wasAiSuggestion = false) }
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

    // MARK: - Actions

    private fun selectProfile(conv: ConversationContext) {
        selectedConversation = conv
        searchText = ""
        suggestions = emptyList()
        clipboardText = null
        currentState = KeyboardState.AWAITING_CLIPBOARD
        renderCurrentState()
    }

    private fun enterBasicMode() {
        currentState = KeyboardState.BASIC_MODE
        suggestions = emptyList()
        clipboardText = null
        renderCurrentState()
    }

    private fun goBackToProfileSelector() {
        if (authHelper.isAuthenticated) {
            currentState = KeyboardState.PROFILE_SELECTOR
            selectedConversation = null
            suggestions = emptyList()
            clipboardText = null
            searchText = ""
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

    private fun handlePaste() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        val text = clip?.getItemAt(0)?.text?.toString()

        if (!text.isNullOrEmpty()) {
            clipboardText = text
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

    private fun handleSuggestionTap(text: String) {
        // Insert into text field
        currentInputConnection?.commitText(text, 1)

        // Copy to clipboard
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("suggestion", text))

        // Track on server
        val conv = selectedConversation
        if (conv?.conversationId != null && authHelper.authToken != null) {
            apiClient.sendMessage(
                backendUrl = authHelper.backendUrl,
                token = authHelper.authToken!!,
                conversationId = conv.conversationId,
                content = text,
                wasAiSuggestion = true,
                tone = currentTone(),
                objective = currentObjective()
            )
        }

        // Go back to awaiting clipboard for next message
        suggestions = emptyList()
        clipboardText = null
        currentState = KeyboardState.AWAITING_CLIPBOARD
        renderCurrentState()
    }

    private fun handleBasicSuggestionTap(text: String) {
        // Insert into text field
        currentInputConnection?.commitText(text, 1)

        // Copy to clipboard
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("suggestion", text))

        // Reset for next use
        suggestions = emptyList()
        clipboardText = null
        renderCurrentState()
    }

    private fun insertAndTrack(text: String, wasAiSuggestion: Boolean) {
        currentInputConnection?.commitText(text, 1)

        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("message", text))

        val conv = selectedConversation
        if (conv?.conversationId != null && authHelper.authToken != null) {
            apiClient.sendMessage(
                backendUrl = authHelper.backendUrl,
                token = authHelper.authToken!!,
                conversationId = conv.conversationId,
                content = text,
                wasAiSuggestion = wasAiSuggestion,
                tone = currentTone(),
                objective = currentObjective()
            )
        }

        suggestions = emptyList()
        clipboardText = null
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
                renderCurrentState()
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
                // Auto-regenerate if tone changed during suggestions view
                if (previousIndex != index && currentState == KeyboardState.SUGGESTIONS && clipboardText != null) {
                    suggestions = emptyList()
                    isLoadingSuggestions = true
                    renderCurrentState()
                    analyzeCurrentText()
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
                renderCurrentState()
            }.onFailure { e ->
                isLoadingProfiles = false
                profilesError = "Erro ao carregar perfis: ${e.message}"
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

    // MARK: - Helpers

    private fun currentTone(): String {
        return availableTones.getOrNull(selectedToneIndex)?.id ?: "automatico"
    }

    private fun currentObjective(): String {
        return availableObjectives.getOrNull(selectedObjectiveIndex)?.id ?: "automatico"
    }
}
