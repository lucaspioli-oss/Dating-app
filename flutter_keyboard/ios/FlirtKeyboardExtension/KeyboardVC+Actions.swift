import UIKit

extension KeyboardViewController {

    // MARK: - Actions

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
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    // MARK: - QWERTY Keyboard Actions

    @objc func qwertyKeyTapped(_ sender: UIButton) {
        let tag = sender.tag
        // Tags 700-725 = letters mapped from qwerty layout
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

    @objc func quickModeTapped() {
        selectedConversation = nil
        saveSelectedConversation(nil)
        suggestions = []
        isSearchActive = false
        currentState = .basicMode
        renderCurrentState()
    }

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

    @objc func backFromSuggestionsTapped() {
        suggestions = []
        clipboardText = nil
        currentState = .awaitingClipboard
        renderCurrentState()
    }

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
