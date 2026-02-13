import UIKit

extension KeyboardViewController {

    // MARK: - Overlay Actions

    @objc func objectivePillTapped() {
        if activeOverlay == .objectiveSelector { dismissOverlay(); return }
        showObjectiveOverlay()
    }

    @objc func tonePillTapped() {
        if activeOverlay == .toneSelector { dismissOverlay(); return }
        showToneOverlay()
    }

    @objc func objectiveFromOverlayTapped(_ sender: UIButton) {
        selectedObjectiveIndex = sender.tag - 300
        // Persist objective + timestamp
        sharedDefaults?.set(selectedObjectiveIndex, forKey: "kb_selectedObjective")
        sharedDefaults?.set(Date(), forKey: "kb_objectiveSelectedAt")
        sharedDefaults?.synchronize()
        dismissOverlay()
        renderCurrentState()
    }

    @objc func toneFromOverlayTapped(_ sender: UIButton) {
        selectedToneIndex = sender.tag - 400
        dismissOverlay()
        // If suggestions are showing, regenerate with new tone
        if currentState == .suggestions || (currentState == .basicMode && !suggestions.isEmpty) {
            suggestions = []
            renderCurrentState()
            if let clip = clipboardText {
                analyzeText(clip, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
            }
        } else {
            renderCurrentState()
        }
    }

    @objc func dismissOverlay() {
        activeOverlay = .none
        containerView.viewWithTag(7777)?.removeFromSuperview()
    }

    // MARK: - Profile Selection

    @objc func profileTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < filteredConversations.count else { return }
        selectedConversation = filteredConversations[index]
        saveSelectedConversation(selectedConversation)
        clipboardText = nil
        suggestions = []
        searchText = ""
        isSearchActive = false
        previousClipboard = UIPasteboard.general.string

        // Check if objective was recently set (< 30 min)
        if let _ = sharedDefaults?.integer(forKey: "kb_selectedObjective"),
           let savedTime = sharedDefaults?.object(forKey: "kb_objectiveSelectedAt") as? Date,
           Date().timeIntervalSince(savedTime) < 1800 {
            // Recent objective → go straight to hub
            currentState = .awaitingClipboard
        } else {
            // No recent objective → show objective selection first
            currentState = .objectiveSelection
        }
        renderCurrentState()
    }

    // MARK: - Objective Selection

    @objc func objectiveCardTapped(_ sender: UIButton) {
        selectedObjectiveIndex = sender.tag - 800
        // Persist objective + timestamp
        sharedDefaults?.set(selectedObjectiveIndex, forKey: "kb_selectedObjective")
        sharedDefaults?.set(Date(), forKey: "kb_objectiveSelectedAt")
        sharedDefaults?.synchronize()
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    // MARK: - Hub Actions

    @objc func startConversationTapped() {
        previousState = .awaitingClipboard
        currentState = .startConversation
        isLoadingSuggestions = true
        renderCurrentState()
        generateFirstMessage()
    }

    @objc func hubScreenshotTapped() {
        previousState = .awaitingClipboard
        screenshotImage = nil
        isAnalyzingScreenshot = false
        currentState = .screenshotAnalysis
        renderCurrentState()
    }

    @objc func hubMultipleTapped() {
        multiMessages = ["", ""]
        previousState = .awaitingClipboard
        currentState = .multipleMessages
        saveMultiMessageState()
        renderCurrentState()
    }

    // MARK: - QWERTY Keyboard Actions

    @objc func qwertyKeyTapped(_ sender: UIButton) {
        let tag = sender.tag
        let allKeys = "qwertyuiopasdfghjklzxcvbnm"
        let index = tag - 700
        guard index >= 0, index < allKeys.count else { return }
        let char = String(allKeys[allKeys.index(allKeys.startIndex, offsetBy: index)])
        let finalChar = isShiftActive ? char.uppercased() : char

        if currentState == .profileSelector {
            searchText += finalChar.lowercased()
            filteredConversations = conversations.filter {
                $0.matchName.localizedCaseInsensitiveContains(searchText)
            }
            renderCurrentState()
        } else if currentState == .writeOwn {
            writeOwnText += finalChar
            if isShiftActive { isShiftActive = false }
            updateWriteOwnDisplay()
        }
    }

    @objc func qwertyBackspaceTapped() {
        if currentState == .profileSelector {
            guard !searchText.isEmpty else { return }
            searchText = String(searchText.dropLast())
            filteredConversations = searchText.isEmpty ? conversations : conversations.filter {
                $0.matchName.localizedCaseInsensitiveContains(searchText)
            }
            renderCurrentState()
        } else if currentState == .writeOwn {
            guard !writeOwnText.isEmpty else { return }
            writeOwnText = String(writeOwnText.dropLast())
            updateWriteOwnDisplay()
        }
    }

    @objc func qwertySpaceTapped() {
        if currentState == .writeOwn {
            writeOwnText += " "
            updateWriteOwnDisplay()
        }
    }

    @objc func qwertyShiftTapped() {
        isShiftActive = !isShiftActive
        renderCurrentState()
    }

    @objc func qwertyClearTapped() {
        if currentState == .profileSelector {
            searchText = ""
            filteredConversations = conversations
            isSearchActive = false
            renderCurrentState()
        } else if currentState == .writeOwn {
            writeOwnText = ""
            updateWriteOwnDisplay()
        }
    }

    func updateWriteOwnDisplay() {
        guard let displayLabel = containerView.viewWithTag(998) as? UILabel else { return }
        displayLabel.text = writeOwnText.isEmpty ? "Digite sua resposta..." : writeOwnText
        displayLabel.textColor = writeOwnText.isEmpty ? Theme.textSecondary : .white
    }

    // MARK: - Mode Switching

    @objc func quickModeTapped() {
        selectedConversation = nil
        saveSelectedConversation(nil)
        suggestions = []
        isSearchActive = false
        currentState = .basicMode
        renderCurrentState()
    }

    // MARK: - Back Navigation

    @objc func backTapped() {
        stopClipboardPolling()
        suggestions = []
        searchText = ""
        isSearchActive = false
        multiMessages = ["", ""]
        clearMultiMessageState()
        selectedConversation = nil
        saveSelectedConversation(nil)
        filteredConversations = conversations
        currentState = authToken != nil ? .profileSelector : .basicMode
        renderCurrentState()
    }

    @objc func backFromObjectiveTapped() {
        selectedConversation = nil
        saveSelectedConversation(nil)
        filteredConversations = conversations
        currentState = .profileSelector
        renderCurrentState()
    }

    @objc func backFromAwaitingTapped() {
        stopClipboardPolling()
        selectedConversation = nil
        saveSelectedConversation(nil)
        filteredConversations = conversations
        currentState = .profileSelector
        renderCurrentState()
    }

    @objc func backFromSuggestionsTapped() {
        suggestions = []
        clipboardText = nil
        currentState = previousState ?? .awaitingClipboard
        renderCurrentState()
    }

    @objc func backFromScreenshotTapped() {
        screenshotImage = nil
        isAnalyzingScreenshot = false
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc func backFromStartConvTapped() {
        suggestions = []
        isLoadingSuggestions = false
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    // MARK: - Suggestion Actions

    @objc func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < suggestions.count else { return }
        let text = suggestions[index]
        UIPasteboard.general.string = text
        textDocumentProxy.insertText(text)

        if let conv = selectedConversation, let convId = conv.conversationId {
            sendMessageToServer(conversationId: convId, content: text, wasAiSuggestion: true)
        } else {
            NSLog("[KB] suggestionTapped: no conversation selected or missing convId — message NOT saved")
        }

        suggestions = []
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc func basicSuggestionTapped(_ sender: UIButton) {
        let index = sender.tag - 100
        guard index >= 0, index < suggestions.count else { return }
        let text = suggestions[index]
        UIPasteboard.general.string = text
        textDocumentProxy.insertText(text)
    }

    @objc func writeOwnTapped() {
        writeOwnText = ""
        isShiftActive = true
        currentState = .writeOwn
        renderCurrentState()
    }

    @objc func backToSuggestionsTapped() {
        currentState = .suggestions
        renderCurrentState()
    }

    @objc func insertOwnTapped() {
        guard !writeOwnText.isEmpty else { return }
        textDocumentProxy.insertText(writeOwnText)

        if let conv = selectedConversation, let convId = conv.conversationId {
            sendMessageToServer(conversationId: convId, content: writeOwnText, wasAiSuggestion: false)
        } else {
            NSLog("[KB] insertOwnTapped: no conversation selected or missing convId — message NOT saved")
        }

        writeOwnText = ""
        suggestions = []
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc func regenerateTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        isLoadingSuggestions = true
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
    }

    @objc func basicGenerateTapped() {
        guard let clip = getClipboardText() else { return }
        clipboardText = clip
        suggestions = []
        isLoadingSuggestions = true
        currentState = .basicMode
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: nil, objective: currentObjective())
    }

    @objc func basicRegenTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        isLoadingSuggestions = true
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: nil, objective: currentObjective())
    }
}
