import UIKit

extension KeyboardViewController {

    // MARK: - Live Logger (sends events to /keyboard/log for real-time monitoring)

    func kbLog(_ event: String, _ data: [String: Any]? = nil) {
        guard let url = URL(string: "\(backendUrl)/keyboard/log") else { return }
        var body: [String: Any] = [
            "event": event,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
        if let uid = userId { body["userId"] = uid }
        if let data = data { body["data"] = data }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
        #if DEBUG
        NSLog("[KB-LOG] \(event) \(data ?? [:])")
        #endif
    }

    // MARK: - Helpers

    func currentTone() -> String { return availableTones[selectedToneIndex] }
    func currentObjective() -> String { return availableObjectives[selectedObjectiveIndex].id }
    func currentLanguage() -> String? { return sharedDefaults?.string(forKey: "userLanguage") }

    // MARK: - Objective Per Profile Keys

    func objectiveKey(for conv: ConversationContext) -> String {
        let name = conv.matchName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "_")
        return "kb_obj_\(name)_\(conv.platform)"
    }

    // MARK: - Persist Selected Conversation

    func saveSelectedConversation(_ conv: ConversationContext?) {
        guard let defaults = sharedDefaults else { return }
        if let conv = conv {
            defaults.set(conv.conversationId, forKey: "kb_selectedConvId")
            defaults.set(conv.profileId, forKey: "kb_selectedProfileId")
            defaults.set(conv.matchName, forKey: "kb_selectedMatchName")
            defaults.set(conv.platform, forKey: "kb_selectedPlatform")
            defaults.set(conv.lastMessage, forKey: "kb_selectedLastMsg")
            defaults.set(conv.threadId, forKey: "kb_selectedThreadId")
        } else {
            defaults.removeObject(forKey: "kb_selectedConvId")
            defaults.removeObject(forKey: "kb_selectedProfileId")
            defaults.removeObject(forKey: "kb_selectedMatchName")
            defaults.removeObject(forKey: "kb_selectedPlatform")
            defaults.removeObject(forKey: "kb_selectedLastMsg")
            defaults.removeObject(forKey: "kb_selectedThreadId")
        }
        defaults.synchronize()
    }

    // MARK: - Profile Cache

    func cacheConversations(_ conversations: [ConversationContext]) {
        guard let defaults = sharedDefaults else { return }
        let jsonArray: [[String: Any?]] = conversations.map { conv in
            return [
                "conversationId": conv.conversationId,
                "profileId": conv.profileId,
                "matchName": conv.matchName,
                "platform": conv.platform,
                "lastMessage": conv.lastMessage,
                "threadId": conv.threadId,
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: jsonArray) {
            defaults.set(data, forKey: "kb_cachedProfiles")
            defaults.synchronize()
        }
    }

    func loadCachedConversations() -> [ConversationContext]? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "kb_cachedProfiles"),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return arr.compactMap { dict -> ConversationContext? in
            guard let name = dict["matchName"] as? String else { return nil }
            return ConversationContext(
                conversationId: dict["conversationId"] as? String,
                profileId: dict["profileId"] as? String,
                matchName: name,
                platform: dict["platform"] as? String ?? "tinder",
                lastMessage: dict["lastMessage"] as? String,
                faceImageBase64: nil,
                threadId: dict["threadId"] as? String
            )
        }
    }

    // MARK: - Persist Multi-Message State

    func saveMultiMessageState() {
        guard let defaults = sharedDefaults else { return }
        defaults.set(true, forKey: "kb_inMultiMessage")
        if let data = try? JSONSerialization.data(withJSONObject: multiMessages) {
            defaults.set(data, forKey: "kb_multiMessages")
        }
        defaults.synchronize()
    }

    func clearMultiMessageState() {
        guard let defaults = sharedDefaults else { return }
        defaults.removeObject(forKey: "kb_inMultiMessage")
        defaults.removeObject(forKey: "kb_multiMessages")
        defaults.synchronize()
    }

    func restoreMultiMessageState() -> [String]? {
        guard let defaults = sharedDefaults,
              defaults.bool(forKey: "kb_inMultiMessage"),
              let data = defaults.data(forKey: "kb_multiMessages"),
              let messages = try? JSONSerialization.jsonObject(with: data) as? [String] else { return nil }
        return messages
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
            faceImageBase64: nil,
            threadId: defaults.string(forKey: "kb_selectedThreadId")
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

        let signed = RequestSigner.shared.sign(body: "")
        request.setValue(signed.signature, forHTTPHeaderField: "X-Signature")
        request.setValue(signed.timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signed.nonce, forHTTPHeaderField: "X-Nonce")

        PinnedURLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                let nsError = error as NSError
                ErrorReporter.shared.report(
                    errorCode: nsError.code,
                    message: nsError.localizedDescription,
                    context: "fetchConversations"
                )
                if !silent {
                    let errorMsg: String
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                        errorMsg = "Sem conexão. Verifique sua internet."
                    case NSURLErrorTimedOut:
                        errorMsg = "Servidor demorou para responder. Tente novamente."
                    case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateUntrusted:
                        errorMsg = "Erro de segurança na conexão (SSL)."
                    case NSURLErrorCannotFindHost:
                        errorMsg = "Servidor não encontrado. Verifique sua conexão e tente novamente."
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
                ErrorReporter.shared.report(errorCode: 401, message: "Sessão expirada", context: "fetchConversations")
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
                ErrorReporter.shared.report(errorCode: 403, message: "Assinatura necessária", context: "fetchConversations")
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
                ErrorReporter.shared.report(errorCode: http.statusCode, message: "Sem dados", context: "fetchConversations")
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
                var errorMsg = "Erro do servidor (HTTP \(http.statusCode))"
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String ?? json["error"] as? String {
                    errorMsg = msg
                }
                ErrorReporter.shared.report(errorCode: http.statusCode, message: errorMsg, context: "fetchConversations")
                if !silent {
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
                        let convId = dict["conversationId"] as? String
                        #if DEBUG
                        NSLog("[KB] fetchConversations: name=\(name) convId=\(convId ?? "nil")")
                        #endif
                        return ConversationContext(
                            conversationId: convId,
                            profileId: dict["profileId"] as? String,
                            matchName: name,
                            platform: dict["platform"] as? String ?? "tinder",
                            lastMessage: dict["lastMessage"] as? String,
                            faceImageBase64: dict["faceImageBase64"] as? String,
                            threadId: dict["threadId"] as? String
                        )
                    }
                    self?.kbLog("profiles:loaded", [
                        "count": contexts.count,
                        "profiles": contexts.map { ["name": $0.matchName, "threadId": $0.threadId ?? "nil", "convId": $0.conversationId ?? "nil", "platform": $0.platform] }
                    ])
                    DispatchQueue.main.async {
                        let oldNames = self?.conversations.map { $0.matchName } ?? []
                        self?.conversations = contexts
                        self?.filteredConversations = contexts
                        self?.isLoadingProfiles = false
                        self?.profilesError = nil
                        self?.cacheConversations(contexts)
                        let newNames = contexts.map { $0.matchName }
                        if !silent || oldNames != newNames {
                            self?.renderCurrentState()
                        }
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
        }
    }

    func analyzeText(_ text: String, tone: String, conversationId: String?, objective: String?, threadId: String? = nil, matchName: String? = nil) {
        guard let url = URL(string: "\(backendUrl)/analyze") else { return }

        kbLog("analyze:start", [
            "convId": conversationId ?? "nil",
            "threadId": threadId ?? "nil",
            "tone": tone,
            "objective": objective ?? "nil",
            "matchName": matchName ?? "nil",
            "textLen": text.count,
        ])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            #if DEBUG
            NSLog("[KB] analyzeText: WARNING — no auth token, message won't be saved to conversation")
            #endif
        }

        var body: [String: Any] = ["text": text, "tone": tone]
        if let convId = conversationId { body["conversationId"] = convId }
        if let tid = threadId { body["threadId"] = tid }
        if let name = matchName { body["matchName"] = name }
        if let obj = objective { body["objective"] = obj }
        if let lang = currentLanguage() { body["language"] = lang }

        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch { return }

        let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        let signedAnalyze = RequestSigner.shared.sign(body: bodyString)
        request.setValue(signedAnalyze.signature, forHTTPHeaderField: "X-Signature")
        request.setValue(signedAnalyze.timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signedAnalyze.nonce, forHTTPHeaderField: "X-Nonce")

        PinnedURLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                if let nsError = error as NSError? {
                    ErrorReporter.shared.report(errorCode: nsError.code, message: nsError.localizedDescription, context: "analyzeText")
                }
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
                    self?.kbLog("analyze:success", ["count": parsed.count, "first": parsed.first?.prefix(50).description ?? ""])
                    DispatchQueue.main.async {
                        self?.isLoadingSuggestions = false
                        self?.suggestions = parsed
                        self?.renderCurrentState()
                    }
                }
            } catch {
                self?.kbLog("analyze:parse-error", ["error": error.localizedDescription])
                DispatchQueue.main.async {
                    self?.isLoadingSuggestions = false
                    self?.suggestions = ["Erro ao processar resposta."]
                    self?.renderCurrentState()
                }
            }
        }
    }

    func sendMessageToServer(conversationId: String?, profileId: String?, content: String, wasAiSuggestion: Bool) {
        guard let token = authToken,
              (conversationId != nil || profileId != nil),
              let url = URL(string: "\(backendUrl)/keyboard/send-message") else {
            #if DEBUG
            NSLog("[KB] sendMessage: missing token or no id")
            #endif
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        var body: [String: Any] = [
            "content": content,
            "wasAiSuggestion": wasAiSuggestion,
            "tone": currentTone(),
            "objective": currentObjective(),
        ]
        if let convId = conversationId { body["conversationId"] = convId }
        if let pid = profileId { body["profileId"] = pid }

        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
            #if DEBUG
            NSLog("[KB] sendMessage: JSON serialization failed: \(error)")
            #endif
            return
        }

        #if DEBUG
        NSLog("[KB] sendMessage: sending to convId=\(conversationId) content=\(content.prefix(40))...")
        #endif

        let bodyStringSend = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        let signedSend = RequestSigner.shared.sign(body: bodyStringSend)
        request.setValue(signedSend.signature, forHTTPHeaderField: "X-Signature")
        request.setValue(signedSend.timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signedSend.nonce, forHTTPHeaderField: "X-Nonce")

        PinnedURLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                let nsError = error as NSError
                ErrorReporter.shared.report(errorCode: nsError.code, message: nsError.localizedDescription, context: "sendMessage")
                #if DEBUG
                NSLog("[KB] sendMessage FAILED: \(error.localizedDescription)")
                #endif
                return
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
            #if DEBUG
            if statusCode == 200 {
                NSLog("[KB] sendMessage OK (200)")
            } else {
                NSLog("[KB] sendMessage ERROR: HTTP \(statusCode) — \(body)")
            }
            #endif
        }
    }

    // MARK: - Generate First Message (Start Conversation)

    func generateFirstMessage() {
        guard let conv = selectedConversation else {
            kbLog("firstMsg:skip", ["reason": "no selected conversation"])
            return
        }

        kbLog("firstMsg:start", ["matchName": conv.matchName, "convId": conv.conversationId ?? "nil", "profileId": conv.profileId ?? "nil"])

        let endpoint = "\(backendUrl)/keyboard/start-conversation"
        guard let url = URL(string: endpoint) else { return }

        #if DEBUG
        NSLog("[KB] generateFirstMessage: convId=\(conv.conversationId ?? "nil") profileId=\(conv.profileId ?? "nil")")
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = [
            "objective": currentObjective(),
            "tone": currentTone(),
        ]
        if let convId = conv.conversationId { body["conversationId"] = convId }
        if let profileId = conv.profileId { body["profileId"] = profileId }
        if let lang = currentLanguage() { body["language"] = lang }

        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch { return }

        let bodyStringFirst = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        let signedFirst = RequestSigner.shared.sign(body: bodyStringFirst)
        request.setValue(signedFirst.signature, forHTTPHeaderField: "X-Signature")
        request.setValue(signedFirst.timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signedFirst.nonce, forHTTPHeaderField: "X-Nonce")

        PinnedURLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                if let nsError = error as NSError? {
                    ErrorReporter.shared.report(errorCode: nsError.code, message: nsError.localizedDescription, context: "generateFirstMessage")
                }
                #if DEBUG
                NSLog("[KB] generateFirstMessage FAILED: \(error?.localizedDescription ?? "unknown")")
                #endif
                DispatchQueue.main.async {
                    self?.isLoadingSuggestions = false
                    self?.suggestions = ["Erro de conexão. Tente novamente."]
                    self?.renderCurrentState()
                }
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            #if DEBUG
            NSLog("[KB] generateFirstMessage: HTTP \(statusCode)")
            #endif

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let analysis = json["analysis"] as? String {
                    let parsed = self?.parseSuggestions(analysis) ?? [analysis]
                    DispatchQueue.main.async {
                        self?.isLoadingSuggestions = false
                        self?.suggestions = parsed
                        self?.renderCurrentState()
                    }
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? "?"
                    #if DEBUG
                    NSLog("[KB] generateFirstMessage: unexpected format: \(raw.prefix(200))")
                    #endif
                    DispatchQueue.main.async {
                        self?.isLoadingSuggestions = false
                        self?.suggestions = ["Erro ao processar resposta."]
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
        }
    }

    // MARK: - Analyze Screenshot

    func analyzeScreenshot(_ imageBase64: String, mediaType: String) {
        guard let conv = selectedConversation else {
            #if DEBUG
            NSLog("[KB] analyzeScreenshot: no selected conversation")
            #endif
            return
        }

        let endpoint = "\(backendUrl)/keyboard/analyze-screenshot"
        guard let url = URL(string: endpoint) else { return }

        #if DEBUG
        NSLog("[KB] analyzeScreenshot: convId=\(conv.conversationId ?? "nil") imageSize=\(imageBase64.count) chars")
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = [
            "imageBase64": imageBase64,
            "imageMediaType": mediaType,
            "objective": currentObjective(),
            "tone": currentTone(),
        ]
        if let convId = conv.conversationId { body["conversationId"] = convId }
        if let lang = currentLanguage() { body["language"] = lang }

        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch { return }

        let bodyStringScreenshot = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        let signedScreenshot = RequestSigner.shared.sign(body: bodyStringScreenshot)
        request.setValue(signedScreenshot.signature, forHTTPHeaderField: "X-Signature")
        request.setValue(signedScreenshot.timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signedScreenshot.nonce, forHTTPHeaderField: "X-Nonce")

        PinnedURLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Release screenshot image to free memory
            DispatchQueue.main.async { self?.screenshotImage = nil }

            guard let data = data, error == nil else {
                if let nsError = error as NSError? {
                    ErrorReporter.shared.report(errorCode: nsError.code, message: nsError.localizedDescription, context: "analyzeScreenshot")
                }
                #if DEBUG
                NSLog("[KB] analyzeScreenshot FAILED: \(error?.localizedDescription ?? "unknown")")
                #endif
                DispatchQueue.main.async {
                    self?.isAnalyzingScreenshot = false
                    self?.isLoadingSuggestions = false
                    self?.suggestions = ["Erro de conexão. Tente novamente."]
                    self?.currentState = .suggestions
                    self?.renderCurrentState()
                }
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            #if DEBUG
            NSLog("[KB] analyzeScreenshot: HTTP \(statusCode)")
            #endif

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let analysis = json["analysis"] as? String {
                    let parsed = self?.parseSuggestions(analysis) ?? [analysis]
                    DispatchQueue.main.async {
                        self?.isAnalyzingScreenshot = false
                        self?.isLoadingSuggestions = false
                        self?.clipboardText = "[Screenshot analisado]"
                        self?.suggestions = parsed
                        self?.previousState = .hub
                        self?.currentState = .suggestions
                        self?.renderCurrentState()
                    }
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? "?"
                    #if DEBUG
                    NSLog("[KB] analyzeScreenshot: unexpected format: \(raw.prefix(200))")
                    #endif
                    DispatchQueue.main.async {
                        self?.isAnalyzingScreenshot = false
                        self?.isLoadingSuggestions = false
                        self?.suggestions = ["Erro ao processar resposta."]
                        self?.currentState = .suggestions
                        self?.renderCurrentState()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isAnalyzingScreenshot = false
                    self?.isLoadingSuggestions = false
                    self?.suggestions = ["Erro ao processar resposta."]
                    self?.currentState = .suggestions
                    self?.renderCurrentState()
                }
            }
        }
    }

    // MARK: - Conversation State Detection (auto-trigger on profile select)

    func fetchConversationState() {
        guard let conv = selectedConversation,
              let token = authToken else {
            kbLog("conv-state:skip", ["reason": "no conv or token"])
            return
        }

        // If no threadId, treat as no_history and auto-trigger first message
        guard let threadId = conv.threadId else {
            kbLog("conv-state:no-thread", ["matchName": conv.matchName, "platform": conv.platform])
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.kbLog("conv-state:auto-first-msg", ["matchName": conv.matchName])
                self.isLoadingSuggestions = true
                self.previousState = .hub
                self.currentState = .startConversation
                self.renderCurrentState()
                self.generateFirstMessage()
            }
            return
        }

        let encodedName = conv.matchName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? conv.matchName
        let urlStr = "\(backendUrl)/keyboard/conversation-state?threadId=\(threadId)&matchName=\(encodedName)"
        guard let url = URL(string: urlStr) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        let signed = RequestSigner.shared.sign(body: "")
        request.setValue(signed.signature, forHTTPHeaderField: "X-Signature")
        request.setValue(signed.timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signed.nonce, forHTTPHeaderField: "X-Nonce")

        kbLog("conv-state:fetch", ["threadId": threadId, "matchName": conv.matchName])

        PinnedURLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data, error == nil,
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let state = json["state"] as? String else {
                let errMsg = error?.localizedDescription ?? "unknown"
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
                self?.kbLog("conv-state:error", ["error": errMsg, "status": status, "body": body.prefix(200).description])
                return
            }

            let suggestedObjective = json["suggestedObjective"] as? String
            let contextHint = json["contextHint"] as? String
            let lastMsg = json["lastMessage"] as? [String: Any]
            let lastText = lastMsg?["text"] as? String
            let lastDirection = lastMsg?["direction"] as? String

            self.kbLog("conv-state:result", [
                "state": state,
                "suggestedObjective": suggestedObjective ?? "nil",
                "contextHint": contextHint ?? "nil",
                "lastDirection": lastDirection ?? "nil",
            ])

            DispatchQueue.main.async {
                guard self.selectedConversation?.threadId == threadId else { return }

                switch state {
                case "needs_response":
                    // She sent a message and user hasn't replied — auto-generate reply
                    if let text = lastText {
                        self.clipboardText = text
                        self.consumedClipboard = text
                        self.suggestions = []
                        self.isLoadingSuggestions = true
                        self.previousState = .hub
                        self.currentState = .suggestions
                        self.renderCurrentState()
                        self.analyzeText(
                            text,
                            tone: self.currentTone(),
                            conversationId: self.selectedConversation?.conversationId,
                            objective: self.currentObjective(),
                            threadId: threadId,
                            matchName: self.selectedConversation?.matchName
                        )
                    }

                case "cold_inbound", "cold_outbound":
                    // Conversation went cold — auto-set objective to "reacender" and generate
                    if let objIndex = self.availableObjectives.firstIndex(where: { $0.id == "reacender" }) {
                        self.selectedObjectiveIndex = objIndex
                    }
                    self.isLoadingSuggestions = true
                    self.previousState = .hub
                    self.currentState = .startConversation
                    self.renderCurrentState()
                    self.generateFirstMessage()

                case "no_history":
                    // No messages yet — auto-trigger first message
                    self.isLoadingSuggestions = true
                    self.previousState = .hub
                    self.currentState = .startConversation
                    self.renderCurrentState()
                    self.generateFirstMessage()

                case "waiting":
                    // User sent last msg, she hasn't replied yet — stay on hub but show hint
                    if let hint = contextHint {
                        self.clipboardText = nil
                        self.conversationHint = hint
                        self.renderCurrentState()
                    }

                default:
                    // recent_outbound, no_thread — just stay on hub, normal behavior
                    break
                }
            }
        }
    }

    // MARK: - Baileys Message Polling

    func startMessagePolling() {
        stopMessagePolling()
        guard let conv = selectedConversation,
              conv.platform.lowercased().contains("whatsapp") || conv.threadId != nil else { return }

        // Initialize lastPolledTimestamp if not set
        if lastPolledTimestamp == nil {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            lastPolledTimestamp = formatter.string(from: Date().addingTimeInterval(-30))
        }

        messagePollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.pollNewMessages()
        }
        #if DEBUG
        NSLog("[KB] Message polling started for \(conv.matchName)")
        #endif
    }

    func stopMessagePolling() {
        messagePollingTimer?.invalidate()
        messagePollingTimer = nil
    }

    func pollNewMessages() {
        guard !isPollingMessages,
              !isLoadingSuggestions,
              let conv = selectedConversation,
              let token = authToken,
              let since = lastPolledTimestamp else { return }

        isPollingMessages = true

        let encodedName = conv.matchName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? conv.matchName
        let encodedSince = since.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? since
        var urlStr = "\(backendUrl)/keyboard/poll-messages?matchName=\(encodedName)&since=\(encodedSince)"
        if let threadId = conv.threadId {
            urlStr += "&threadId=\(threadId)"
        }

        guard let url = URL(string: urlStr) else {
            isPollingMessages = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        let signed = RequestSigner.shared.sign(body: "")
        request.setValue(signed.signature, forHTTPHeaderField: "X-Signature")
        request.setValue(signed.timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signed.nonce, forHTTPHeaderField: "X-Nonce")

        PinnedURLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer { self?.isPollingMessages = false }

            guard let data = data, error == nil,
                  let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                #if DEBUG
                if let err = error { NSLog("[KB] poll error: \(err.localizedDescription)") }
                #endif
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let messages = json["messages"] as? [[String: Any]],
                      !messages.isEmpty else { return }

                // Update threadId if resolved by server
                if let threadId = json["threadId"] as? String, self?.selectedConversation?.threadId == nil {
                    DispatchQueue.main.async {
                        guard let self = self, let conv = self.selectedConversation else { return }
                        self.selectedConversation = ConversationContext(
                            conversationId: conv.conversationId,
                            profileId: conv.profileId,
                            matchName: conv.matchName,
                            platform: conv.platform,
                            lastMessage: conv.lastMessage,
                            faceImageBase64: conv.faceImageBase64,
                            threadId: threadId
                        )
                        self.saveSelectedConversation(self.selectedConversation)
                    }
                }

                // Update lastPolledTimestamp
                if let latestTs = json["latestTs"] as? String {
                    self?.lastPolledTimestamp = latestTs
                }

                // Concatenate all new inbound messages
                let allTexts = messages.compactMap { $0["text"] as? String }.filter { !$0.isEmpty }
                guard !allTexts.isEmpty else { return }
                let combinedText = allTexts.joined(separator: "\n")

                #if DEBUG
                NSLog("[KB] New messages detected (\(allTexts.count)): \(combinedText.prefix(60))...")
                #endif

                // Auto-trigger suggestion generation with threadId for full context
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.clipboardText = combinedText
                    self.consumedClipboard = combinedText
                    self.suggestions = []
                    self.isLoadingSuggestions = true
                    self.previousState = .hub
                    self.currentState = .suggestions
                    self.renderCurrentState()
                    self.analyzeText(
                        combinedText,
                        tone: self.currentTone(),
                        conversationId: self.selectedConversation?.conversationId,
                        objective: self.currentObjective(),
                        threadId: self.selectedConversation?.threadId,
                        matchName: self.selectedConversation?.matchName
                    )
                }
            } catch {
                #if DEBUG
                NSLog("[KB] poll parse error: \(error.localizedDescription)")
                #endif
            }
        }
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
              current != previousClipboard,
              current != consumedClipboard else { return }

        stopClipboardPolling()
        clipboardText = current
        previousClipboard = current
        consumedClipboard = current
        suggestions = []
        isLoadingSuggestions = true
        previousState = .hub
        currentState = .suggestions
        renderCurrentState()

        analyzeText(current, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective(), threadId: selectedConversation?.threadId, matchName: selectedConversation?.matchName)
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
