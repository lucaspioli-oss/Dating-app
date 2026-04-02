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
        if let conv = selectedConversation {
            let key = objectiveKey(for: conv)
            sharedDefaults?.set(selectedObjectiveIndex, forKey: key)
            sharedDefaults?.set(Date(), forKey: "\(key)_at")
        }
        sharedDefaults?.set(selectedObjectiveIndex, forKey: "kb_selectedObjective")
        sharedDefaults?.set(Date(), forKey: "kb_objectiveSelectedAt")
        sharedDefaults?.synchronize()
        dismissOverlay()
        renderCurrentState()
    }

    @objc func toneFromOverlayTapped(_ sender: UIButton) {
        selectedToneIndex = sender.tag - 400
        dismissOverlay()
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
        stopMessagePolling()
        lastPolledTimestamp = nil
        selectedConversation = filteredConversations[index]
        saveSelectedConversation(selectedConversation)
        clipboardText = nil
        suggestions = []
        searchText = ""
        isSearchActive = false
        // Restore objective if recently set for this profile
        let conv = filteredConversations[index]
        let objKey = objectiveKey(for: conv)
        if let savedObj = sharedDefaults?.integer(forKey: objKey),
           let savedTime = sharedDefaults?.object(forKey: "\(objKey)_at") as? Date,
           Date().timeIntervalSince(savedTime) < 1800 {
            selectedObjectiveIndex = savedObj
        }
        currentState = .hub
        renderCurrentState()
    }

    // MARK: - Hub Actions

    @objc func startConversationTapped() {
        previousState = .hub
        currentState = .startConversation
        isLoadingSuggestions = true
        renderCurrentState()
        generateFirstMessage()
    }

    @objc func hubScreenshotTapped() {
        previousState = .hub
        screenshotImage = nil
        isAnalyzingScreenshot = false
        currentState = .screenshotAnalysis
        renderCurrentState()
    }

    @objc func hubMultipleTapped() {
        multiMessages = ["", ""]
        previousState = .hub
        currentState = .multipleMessages
        saveMultiMessageState()
        renderCurrentState()
    }

    // MARK: - Clipboard Paste (from hub no-clipboard state)

    @objc func pasteBoxTapped() {
        if let text = UIPasteboard.general.string, !text.isEmpty, text != consumedClipboard {
            clipboardText = text
            previousClipboard = text
            consumedClipboard = text
            stopClipboardPolling()
            suggestions = []
            isLoadingSuggestions = true
            previousState = .hub
            currentState = .suggestions
            renderCurrentState()
            analyzeText(text, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
        }
    }

    // MARK: - QWERTY Keyboard Actions

    @objc func qwertyKeyTapped(_ sender: UIButton) {
        let tag = sender.tag
        let allKeys = "qwertyuiopasdfghjklzxcvbnm"
        let index = tag - 700
        guard index >= 0, index < allKeys.count else { return }
        let char = String(allKeys[allKeys.index(allKeys.startIndex, offsetBy: index)])
        let finalChar = isShiftActive ? char.uppercased() : char

        if currentState == .profilePicker {
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
        if currentState == .profilePicker {
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
        if currentState == .profilePicker {
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
        stopMessagePolling()
        lastPolledTimestamp = nil
        suggestions = []
        searchText = ""
        isSearchActive = false
        multiMessages = ["", ""]
        clearMultiMessageState()
        selectedConversation = nil
        saveSelectedConversation(nil)
        filteredConversations = conversations
        currentState = authToken != nil ? .hub : .basicMode
        renderCurrentState()
    }

    @objc func backFromSuggestionsTapped() {
        suggestions = []
        clipboardText = nil
        currentState = previousState ?? .hub
        renderCurrentState()
    }

    @objc func backFromScreenshotTapped() {
        screenshotImage = nil
        isAnalyzingScreenshot = false
        currentState = .hub
        renderCurrentState()
    }

    @objc func backFromStartConvTapped() {
        suggestions = []
        isLoadingSuggestions = false
        currentState = .hub
        renderCurrentState()
    }

    // Legacy back methods (redirect to hub)
    @objc func backFromObjectiveTapped() {
        currentState = .hub
        renderCurrentState()
    }

    @objc func backFromAwaitingTapped() {
        stopClipboardPolling()
        currentState = .hub
        renderCurrentState()
    }

    // MARK: - Suggestion Actions

    @objc func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < suggestions.count else { return }
        let text = suggestions[index]
        UIPasteboard.general.string = text
        textDocumentProxy.insertText(text)

        if let conv = selectedConversation {
            sendMessageToServer(conversationId: conv.conversationId, profileId: conv.profileId, content: text, wasAiSuggestion: true)
        }

        suggestions = []
        clipboardText = nil
        consumedClipboard = UIPasteboard.general.string
        currentState = .hub
        renderCurrentState()
    }

    @objc func basicSuggestionTapped(_ sender: UIButton) {
        let index = sender.tag - 100
        guard index >= 0, index < suggestions.count else { return }
        let text = suggestions[index]
        UIPasteboard.general.string = text
        textDocumentProxy.insertText(text)
        // Auto-switch to system keyboard so user can tap Send
        advanceToNextInputMode()
    }

    @objc func editSuggestionTapped(_ sender: UIButton) {
        let index = sender.tag - 200
        guard index >= 0, index < suggestions.count else { return }
        writeOwnText = suggestions[index]
        isShiftActive = false
        currentState = .writeOwn
        renderCurrentState()
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

        if let conv = selectedConversation {
            sendMessageToServer(conversationId: conv.conversationId, profileId: conv.profileId, content: writeOwnText, wasAiSuggestion: false)
        }

        writeOwnText = ""
        suggestions = []
        clipboardText = nil
        consumedClipboard = UIPasteboard.general.string
        currentState = .hub
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
