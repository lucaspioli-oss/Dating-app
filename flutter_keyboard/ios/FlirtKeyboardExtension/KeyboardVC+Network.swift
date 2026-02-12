import UIKit

extension KeyboardViewController {

    // MARK: - Helpers

    func currentTone() -> String { return availableTones[selectedToneIndex] }
    func currentObjective() -> String { return availableObjectives[selectedObjectiveIndex].id }

    // MARK: - Persist Selected Conversation

    func saveSelectedConversation(_ conv: ConversationContext?) {
        guard let defaults = sharedDefaults else { return }
        if let conv = conv {
            defaults.set(conv.conversationId, forKey: "kb_selectedConvId")
            defaults.set(conv.profileId, forKey: "kb_selectedProfileId")
            defaults.set(conv.matchName, forKey: "kb_selectedMatchName")
            defaults.set(conv.platform, forKey: "kb_selectedPlatform")
            defaults.set(conv.lastMessage, forKey: "kb_selectedLastMsg")
        } else {
            defaults.removeObject(forKey: "kb_selectedConvId")
            defaults.removeObject(forKey: "kb_selectedProfileId")
            defaults.removeObject(forKey: "kb_selectedMatchName")
            defaults.removeObject(forKey: "kb_selectedPlatform")
            defaults.removeObject(forKey: "kb_selectedLastMsg")
        }
        defaults.synchronize()
    }

    func restoreSavedConversation() -> ConversationContext? {
        guard let defaults = sharedDefaults,
              let name = defaults.string(forKey: "kb_selectedMatchName"),
              !name.isEmpty else { return nil }
        return ConversationContext(
            conversationId: defaults.string(forKey: "kb_selectedConvId"),
            profileId: defaults.string(forKey: "kb_selectedProfileId"),
            matchName: name,
            platform: defaults.string(forKey: "kb_selectedPlatform") ?? "tinder",
            lastMessage: defaults.string(forKey: "kb_selectedLastMsg"),
            faceImageBase64: nil
        )
    }

    // MARK: - Network

    func fetchConversations(silent: Bool = false) {
        guard let token = authToken,
              let url = URL(string: "\(backendUrl)/keyboard/context") else {
            if !silent {
                isLoadingProfiles = false
                profilesError = "Token não encontrado. Abra o app para fazer login."
                renderCurrentState()
            }
            return
        }

        if !silent {
            isLoadingProfiles = true
            profilesError = nil
            renderCurrentState()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                if !silent {
                    let nsError = error as NSError
                    let errorMsg: String
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                        errorMsg = "Sem conexão. Verifique sua internet."
                    case NSURLErrorTimedOut:
                        errorMsg = "Servidor demorou para responder. Tente novamente."
                    case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateUntrusted:
                        errorMsg = "Erro de segurança na conexão (SSL)."
                    default:
                        errorMsg = "Erro de conexão: \(nsError.localizedDescription) (\(nsError.code))"
                    }
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = errorMsg
                        self?.renderCurrentState()
                    }
                }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Servidor indisponível. Tente novamente."
                        self?.renderCurrentState()
                    }
                }
                return
            }

            if http.statusCode == 401 {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Sessão expirada. Abra o app Desenrola para renovar."
                        self?.renderCurrentState()
                    }
                }
                return
            }

            if http.statusCode == 403 {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Assinatura necessária para usar o teclado."
                        self?.renderCurrentState()
                    }
                }
                return
            }

            guard let data = data else {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Sem dados (HTTP \(http.statusCode))."
                        self?.renderCurrentState()
                    }
                }
                return
            }

            // Handle non-200 status codes
            if http.statusCode != 200 {
                if !silent {
                    var errorMsg = "Erro do servidor (HTTP \(http.statusCode))"
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let msg = json["message"] as? String ?? json["error"] as? String {
                        errorMsg = msg
                    }
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = errorMsg
                        self?.renderCurrentState()
                    }
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let arr = json["conversations"] as? [[String: Any]] {
                    let contexts = arr.compactMap { dict -> ConversationContext? in
                        guard let name = dict["matchName"] as? String else { return nil }
                        return ConversationContext(
                            conversationId: dict["conversationId"] as? String,
                            profileId: dict["profileId"] as? String,
                            matchName: name,
                            platform: dict["platform"] as? String ?? "tinder",
                            lastMessage: dict["lastMessage"] as? String,
                            faceImageBase64: dict["faceImageBase64"] as? String
                        )
                    }
                    DispatchQueue.main.async {
                        self?.conversations = contexts
                        self?.filteredConversations = contexts
                        self?.isLoadingProfiles = false
                        self?.profilesError = nil
                        if !silent { self?.renderCurrentState() }
                    }
                } else if !silent {
                    let raw = String(data: data, encoding: .utf8) ?? "?"
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Formato inesperado: \(raw.prefix(80))"
                        self?.renderCurrentState()
                    }
                }
            } catch {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Erro ao processar: \(error.localizedDescription)"
                        self?.renderCurrentState()
                    }
                }
            }
        }.resume()
    }

    func analyzeText(_ text: String, tone: String, conversationId: String?, objective: String?) {
        guard let url = URL(string: "\(backendUrl)/analyze") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = ["text": text, "tone": tone]
        if let convId = conversationId { body["conversationId"] = convId }
        if let obj = objective { body["objective"] = obj }

        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch { return }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.isLoadingSuggestions = false
                    self?.suggestions = ["Erro de conexão. Tente novamente."]
                    self?.renderCurrentState()
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let analysis = json["analysis"] as? String {
                    let parsed = self?.parseSuggestions(analysis) ?? [analysis]
                    DispatchQueue.main.async {
                        self?.isLoadingSuggestions = false
                        self?.suggestions = parsed
                        self?.renderCurrentState()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoadingSuggestions = false
                    self?.suggestions = ["Erro ao processar resposta."]
                    self?.renderCurrentState()
                }
            }
        }.resume()
    }

    func sendMessageToServer(conversationId: String, content: String, wasAiSuggestion: Bool) {
        guard let token = authToken,
              let url = URL(string: "\(backendUrl)/keyboard/send-message") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "conversationId": conversationId,
            "content": content,
            "wasAiSuggestion": wasAiSuggestion,
            "tone": currentTone(),
            "objective": currentObjective(),
        ]

        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch { return }
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    // MARK: - Clipboard Polling

    func startClipboardPolling() {
        stopClipboardPolling()
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopClipboardPolling() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }

    func checkClipboard() {
        guard let current = UIPasteboard.general.string,
              !current.isEmpty,
              current != previousClipboard else { return }

        stopClipboardPolling()
        clipboardText = current
        previousClipboard = current
        suggestions = []
        isLoadingSuggestions = true
        currentState = .suggestions
        renderCurrentState()

        analyzeText(current, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
    }

    // MARK: - Parse & Clipboard Helpers

    func getClipboardText() -> String? {
        guard let text = UIPasteboard.general.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }

    func parseSuggestions(_ text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var numberedItems: [String] = []

        // Headers/analysis keywords to skip
        let skipPatterns = ["#", "⚠️", "🚩", "📊", "📋", "═", "───", "❌", "✅", "✓",
                           "ANÁLISE", "ANALISE", "RED FLAG", "GRAU DE", "CHECKLIST",
                           "INVESTIMENTO", "LEI #", "CALIBRA", "VALIDAÇÃO", "SITUAÇÃO"]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Check if this is a numbered line (1. / 1) / 1: etc)
            guard let range = trimmed.range(of: #"^\d+[\.\)\:]\s*"#, options: .regularExpression) else { continue }

            var suggestion = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if suggestion.isEmpty { continue }

            // Skip lines that look like analysis headers
            let upper = suggestion.uppercased()
            let isHeader = skipPatterns.contains(where: { upper.contains($0) })
            if isHeader { continue }

            // Remove surrounding quotes
            if (suggestion.hasPrefix("\"") && suggestion.hasSuffix("\"")) ||
               (suggestion.hasPrefix("'") && suggestion.hasSuffix("'")) ||
               (suggestion.hasPrefix("\u{201C}") && suggestion.hasSuffix("\u{201D}")) {
                suggestion = String(suggestion.dropFirst().dropLast())
            }

            if !suggestion.isEmpty {
                numberedItems.append(suggestion)
            }
        }

        if !numberedItems.isEmpty {
            return Array(numberedItems.prefix(3))
        }

        // Fallback: try to find any quoted text in the response
        var quoted: [String] = []
        let quoteRegex = try? NSRegularExpression(pattern: #"“([^”]{5,})”"#)
        if let regex = quoteRegex {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    quoted.append(String(text[range]))
                }
            }
        }

        if !quoted.isEmpty {
            return Array(quoted.prefix(3))
        }

        // Last resort: split into sentences, filter out analysis content
        let sentences = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                !line.isEmpty &&
                line.count > 3 &&
                !skipPatterns.contains(where: { line.uppercased().contains($0) }) &&
                !line.hasPrefix("-") &&
                !line.hasPrefix("*")
            }

        if !sentences.isEmpty {
            return Array(sentences.prefix(3))
        }

        return ["Erro ao processar sugestões. Tente novamente."]
    }
}
