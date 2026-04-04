import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - State Machine (reduced from 9 to 5)

    enum KeyboardState {
        case hub              // Smart hub: profile + clipboard + actions
        case suggestions      // AI suggestions display
        case writeOwn         // Custom text editor
        case basicMode        // Quick mode without profile
        case profilePicker    // Profile selection screen
        // Sub-flows (entered from hub, back navigates to hub)
        case screenshotAnalysis
        case startConversation
        case multipleMessages
    }

    enum OverlayType {
        case none
        case objectiveSelector
        case toneSelector
    }

    // MARK: - Theme (brand gradient: #FF4B2B → #FF9021 → #D830A0 → #7A29C0)

    struct Theme {
        static let bg = UIColor(red: 0.03, green: 0.02, blue: 0.03, alpha: 1.0)           // #050505
        static let cardBg = UIColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 1.0)     // #111111
        static let cardHover = UIColor(red: 0.086, green: 0.086, blue: 0.086, alpha: 1.0)  // #161616

        // Brand gradient stops
        static let flameRed = UIColor(red: 1.0, green: 0.294, blue: 0.169, alpha: 1.0)     // #FF4B2B
        static let flameOrange = UIColor(red: 1.0, green: 0.565, blue: 0.129, alpha: 1.0)  // #FF9021
        static let magenta = UIColor(red: 0.847, green: 0.188, blue: 0.627, alpha: 1.0)    // #D830A0
        static let purple = UIColor(red: 0.478, green: 0.161, blue: 0.753, alpha: 1.0)     // #7A29C0

        // Functional
        static let accent = magenta          // Primary accent
        static let accentWarm = flameOrange  // Secondary accent
        static let textPrimary = UIColor.white.withAlphaComponent(0.95)
        static let textSecondary = UIColor.white.withAlphaComponent(0.56)
        static let textTertiary = UIColor.white.withAlphaComponent(0.32)
        static let border = UIColor.white.withAlphaComponent(0.06)
        static let borderHover = UIColor.white.withAlphaComponent(0.12)
        static let clipText = UIColor(red: 1.0, green: 0.75, blue: 0.6, alpha: 1.0)
        static let suggestionBg = UIColor(red: 0.08, green: 0.06, blue: 0.10, alpha: 1.0)
        static let overlayBg = UIColor(red: 0.03, green: 0.02, blue: 0.03, alpha: 0.97)
        static let selectedBg = UIColor(red: 0.847, green: 0.188, blue: 0.627, alpha: 0.12)
        static let errorText = UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
        static let successGreen = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0)

        // Legacy aliases (for files not yet refactored)
        static let rose = magenta
        static let orange = flameOrange
    }

    // MARK: - Objective Data

    struct Objective {
        let id: String
        let emoji: String
        let title: String
        let description: String
    }

    let availableObjectives: [Objective] = [
        Objective(id: "automatico", emoji: "🎯", title: "Automático", description: "IA escolhe com base no contexto"),
        Objective(id: "pegar_numero", emoji: "📱", title: "Pegar Número", description: "Pedir o número dela naturalmente"),
        Objective(id: "marcar_encontro", emoji: "☕", title: "Marcar Encontro", description: "Convite confiante para sair"),
        Objective(id: "modo_intimo", emoji: "🔥", title: "Modo Íntimo", description: "Mensagens sedutoras"),
        Objective(id: "mudar_plataforma", emoji: "💬", title: "Mudar Plataforma", description: "Migrar para outro app"),
        Objective(id: "reacender", emoji: "🔄", title: "Reacender", description: "Retomar conversa parada"),
        Objective(id: "virar_romantico", emoji: "💕", title: "Virar Romântico", description: "De amigável para flerte"),
        Objective(id: "video_call", emoji: "🎥", title: "Video Call", description: "Conduzir para vídeo chamada"),
        Objective(id: "pedir_desculpas", emoji: "🙏", title: "Desculpas", description: "Pedido genuíno de desculpas"),
        Objective(id: "criar_conexao", emoji: "🤝", title: "Criar Conexão", description: "Aprofundar conexão emocional"),
    ]

    // MARK: - Tone Data

    let availableTones = ["automatico", "engraçado", "ousado", "romântico", "casual", "confiante"]
    let toneEmojis = ["🤖", "😄", "🔥", "❤️", "😎", "💪"]
    let toneLabels = ["Auto", "Engraçado", "Ousado", "Romântico", "Casual", "Confiante"]

    // MARK: - Properties

    var currentState: KeyboardState = .hub
    var activeOverlay: OverlayType = .none
    var containerView: UIView!

    struct ConversationContext {
        let conversationId: String?
        let profileId: String?
        let matchName: String
        let platform: String
        let lastMessage: String?
        let faceImageBase64: String?
        let threadId: String?
    }

    var conversations: [ConversationContext] = []
    var filteredConversations: [ConversationContext] = []
    var selectedConversation: ConversationContext?
    var clipboardText: String?
    var suggestions: [String] = []
    var previousClipboard: String?
    var consumedClipboard: String?
    var isLoadingProfiles = true
    var profilesError: String?
    var searchText: String = ""
    var selectedToneIndex: Int = 0
    var selectedObjectiveIndex: Int = 0
    var isLoadingSuggestions = false
    var writeOwnText: String = ""
    var isShiftActive: Bool = true
    var isSearchActive: Bool = false
    var multiMessages: [String] = ["", ""]
    var clipboardTimer: Timer?
    var previousState: KeyboardState? = nil
    var screenshotImage: UIImage? = nil
    var isAnalyzingScreenshot = false
    var conversationHint: String? = nil

    // Baileys message polling
    var messagePollingTimer: Timer?
    var lastPolledTimestamp: String?
    var isPollingMessages: Bool = false

    // Shared config
    var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.desenrolaai.app.shared")
    }

    var backendUrl: String {
        return sharedDefaults?.string(forKey: "backendUrl") ?? "https://api.desenrolaai.site"
    }

    var authToken: String? {
        if let token = KeychainHelper.shared.read(forKey: "authToken") {
            return token
        }
        if let token = sharedDefaults?.string(forKey: "authToken") {
            KeychainHelper.shared.save(token, forKey: "authToken")
            return token
        }
        return nil
    }

    var userId: String? {
        if let uid = KeychainHelper.shared.read(forKey: "userId") {
            return uid
        }
        if let uid = sharedDefaults?.string(forKey: "userId") {
            KeychainHelper.shared.save(uid, forKey: "userId")
            return uid
        }
        return nil
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bg

        // Read clipboard FIRST, before any views exist.
        // The iOS paste dialog (if any) appears before the keyboard is visible,
        // so the user never sees it. The value is cached in clipboardText
        // and used later during rendering — never access UIPasteboard during render.
        previousClipboard = UIPasteboard.general.string
        if let clip = UIPasteboard.general.string, !clip.isEmpty {
            clipboardText = clip
        }

        if !SecurityHelper.isSecureEnvironment() {
            NSLog("[KB] Security check FAILED")
            currentState = .basicMode
            renderCurrentState()
            return
        }

        // Check if app left a pending text to insert (screenshot flow)
        checkPendingInsert()

        if authToken != nil {
            // Start at profile picker so user always chooses who to talk to
            currentState = .profilePicker

            // Load cached profiles for instant display
            if let cached = loadCachedConversations(), !cached.isEmpty {
                conversations = cached
                filteredConversations = cached
                isLoadingProfiles = false
            }
            fetchConversations(silent: !conversations.isEmpty)
        } else {
            currentState = .basicMode
        }

        renderCurrentState()
    }

    // MARK: - Height

    func heightForState(_ state: KeyboardState) -> CGFloat {
        switch state {
        case .profilePicker: return 350
        case .writeOwn: return 350
        case .multipleMessages: return 350
        default: return 320
        }
    }

    // MARK: - State Rendering

    func renderCurrentState() {
        view.subviews.forEach { $0.removeFromSuperview() }
        activeOverlay = .none

        containerView = UIView()
        containerView.backgroundColor = Theme.bg
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: heightForState(currentState))
        ])

        switch currentState {
        case .hub: renderHub()
        case .suggestions: renderSuggestions()
        case .writeOwn: renderWriteOwn()
        case .basicMode: renderBasicMode()
        case .profilePicker: renderProfileSelector()
        case .screenshotAnalysis: renderScreenshotAnalysis()
        case .startConversation: renderStartConversation()
        case .multipleMessages: renderMultipleMessages()
        }
    }

    // MARK: - Smart Hub (replaces profileSelector + objectiveSelection + awaitingClipboard)

    func renderHub() {
        // ── Row 1: Profile header + globe ──
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerStack)

        // Profile avatar button (tap to switch)
        let avatarBtn = UIButton(type: .system)
        avatarBtn.translatesAutoresizingMaskIntoConstraints = false
        avatarBtn.widthAnchor.constraint(equalToConstant: 32).isActive = true
        avatarBtn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        avatarBtn.layer.cornerRadius = 16
        avatarBtn.clipsToBounds = true

        if let conv = selectedConversation,
           let base64 = conv.faceImageBase64,
           let data = Data(base64Encoded: base64),
           let image = UIImage(data: data) {
            avatarBtn.setBackgroundImage(image, for: .normal)
        } else {
            avatarBtn.backgroundColor = Theme.cardBg
            let initial = selectedConversation?.matchName.prefix(1).uppercased() ?? "?"
            avatarBtn.setTitle(initial, for: .normal)
            avatarBtn.setTitleColor(.white, for: .normal)
            avatarBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        }

        // Gradient border for avatar
        let avatarBorder = CAGradientLayer()
        avatarBorder.colors = [Theme.flameRed.cgColor, Theme.magenta.cgColor, Theme.purple.cgColor]
        avatarBorder.startPoint = CGPoint(x: 0, y: 0)
        avatarBorder.endPoint = CGPoint(x: 1, y: 1)
        avatarBorder.frame = CGRect(x: -1.5, y: -1.5, width: 35, height: 35)
        avatarBorder.cornerRadius = 17.5

        let maskLayer = CAShapeLayer()
        let outerPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 35, height: 35), cornerRadius: 17.5)
        let innerPath = UIBezierPath(roundedRect: CGRect(x: 1.5, y: 1.5, width: 32, height: 32), cornerRadius: 16)
        outerPath.append(innerPath)
        outerPath.usesEvenOddFillRule = true
        maskLayer.path = outerPath.cgPath
        maskLayer.fillRule = .evenOdd
        avatarBorder.mask = maskLayer
        avatarBtn.layer.addSublayer(avatarBorder)

        avatarBtn.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        headerStack.addArrangedSubview(avatarBtn)

        // Profile name + platform
        let nameStack = UIStackView()
        nameStack.axis = .vertical
        nameStack.spacing = 1
        nameStack.translatesAutoresizingMaskIntoConstraints = false

        if let conv = selectedConversation {
            let nameRow = UIStackView()
            nameRow.axis = .horizontal
            nameRow.spacing = 5
            nameRow.alignment = .center

            let nameLabel = UILabel()
            nameLabel.text = conv.matchName
            nameLabel.textColor = Theme.textPrimary
            nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            nameRow.addArrangedSubview(nameLabel)

            // Green pulsing dot for WhatsApp-connected contacts
            let isWhatsApp = conv.platform.lowercased().contains("whatsapp") || conv.threadId != nil
            if isWhatsApp {
                let dot = UIView()
                dot.backgroundColor = Theme.successGreen
                dot.layer.cornerRadius = 4
                dot.translatesAutoresizingMaskIntoConstraints = false
                dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
                dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
                nameRow.addArrangedSubview(dot)

                UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
                    dot.alpha = 0.3
                }
            }
            nameStack.addArrangedSubview(nameRow)

            let platformLabel = UILabel()
            platformLabel.text = isWhatsApp ? "WhatsApp · Sincronizado" : conv.platform.capitalized
            platformLabel.textColor = isWhatsApp ? Theme.successGreen.withAlphaComponent(0.7) : Theme.textTertiary
            platformLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            nameStack.addArrangedSubview(platformLabel)
        } else {
            let nameLabel = UILabel()
            nameLabel.text = "Toque para selecionar perfil"
            nameLabel.textColor = Theme.textSecondary
            nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            nameStack.addArrangedSubview(nameLabel)
        }

        let nameTap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        nameStack.addGestureRecognizer(nameTap)
        nameStack.isUserInteractionEnabled = true
        headerStack.addArrangedSubview(nameStack)

        let headerSpacer = UIView()
        headerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(headerSpacer)

        // Pills inline in header
        headerStack.addArrangedSubview(makeObjectivePill(compact: true))
        headerStack.addArrangedSubview(makeTonePill(compact: true))

        let switchBtn = makeKeyboardSwitchButton()
        headerStack.addArrangedSubview(switchBtn)

        // ── Row 2: Clipboard detection / paste area ──
        let clipArea = UIView()
        clipArea.translatesAutoresizingMaskIntoConstraints = false
        clipArea.layer.cornerRadius = 12
        clipArea.isUserInteractionEnabled = true
        containerView.addSubview(clipArea)

        // Never access UIPasteboard during render — it triggers the iOS paste
        // permission dialog which blocks the run loop and corrupts the view.
        let currentClip = clipboardText
        let hasClip = currentClip != nil && !currentClip!.isEmpty && currentClip != consumedClipboard

        if hasClip {
            // Clipboard detected — show preview + CTA
            clipArea.backgroundColor = Theme.selectedBg
            clipArea.layer.borderWidth = 1
            clipArea.layer.borderColor = Theme.accent.withAlphaComponent(0.2).cgColor

            let clipIcon = UILabel()
            clipIcon.text = "💬"
            clipIcon.font = UIFont.systemFont(ofSize: 16)
            clipIcon.translatesAutoresizingMaskIntoConstraints = false
            clipArea.addSubview(clipIcon)

            let clipPreview = UILabel()
            let previewText = currentClip!.count > 60 ? String(currentClip!.prefix(57)) + "..." : currentClip!
            clipPreview.text = "\"\(previewText)\""
            clipPreview.font = UIFont.systemFont(ofSize: 12)
            clipPreview.textColor = Theme.clipText
            clipPreview.numberOfLines = 2
            clipPreview.translatesAutoresizingMaskIntoConstraints = false
            clipArea.addSubview(clipPreview)

            let suggestBtn = UIView()
            suggestBtn.translatesAutoresizingMaskIntoConstraints = false
            suggestBtn.layer.cornerRadius = 8
            suggestBtn.clipsToBounds = true
            clipArea.addSubview(suggestBtn)

            let suggestGradient = GradientView()
            suggestGradient.translatesAutoresizingMaskIntoConstraints = false
            suggestBtn.addSubview(suggestGradient)

            let suggestLabel = UILabel()
            suggestLabel.text = "Sugerir ↗"
            suggestLabel.textColor = .white
            suggestLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            suggestLabel.textAlignment = .center
            suggestLabel.translatesAutoresizingMaskIntoConstraints = false
            suggestBtn.addSubview(suggestLabel)

            NSLayoutConstraint.activate([
                clipIcon.leadingAnchor.constraint(equalTo: clipArea.leadingAnchor, constant: 12),
                clipIcon.centerYAnchor.constraint(equalTo: clipArea.centerYAnchor),
                clipPreview.leadingAnchor.constraint(equalTo: clipIcon.trailingAnchor, constant: 8),
                clipPreview.trailingAnchor.constraint(equalTo: suggestBtn.leadingAnchor, constant: -8),
                clipPreview.centerYAnchor.constraint(equalTo: clipArea.centerYAnchor),
                suggestBtn.trailingAnchor.constraint(equalTo: clipArea.trailingAnchor, constant: -8),
                suggestBtn.centerYAnchor.constraint(equalTo: clipArea.centerYAnchor),
                suggestBtn.widthAnchor.constraint(equalToConstant: 76),
                suggestBtn.heightAnchor.constraint(equalToConstant: 32),
                suggestGradient.topAnchor.constraint(equalTo: suggestBtn.topAnchor),
                suggestGradient.bottomAnchor.constraint(equalTo: suggestBtn.bottomAnchor),
                suggestGradient.leadingAnchor.constraint(equalTo: suggestBtn.leadingAnchor),
                suggestGradient.trailingAnchor.constraint(equalTo: suggestBtn.trailingAnchor),
                suggestLabel.topAnchor.constraint(equalTo: suggestBtn.topAnchor),
                suggestLabel.bottomAnchor.constraint(equalTo: suggestBtn.bottomAnchor),
                suggestLabel.leadingAnchor.constraint(equalTo: suggestBtn.leadingAnchor),
                suggestLabel.trailingAnchor.constraint(equalTo: suggestBtn.trailingAnchor),
            ])

            let areaTap = UITapGestureRecognizer(target: self, action: #selector(clipAreaTapped))
            clipArea.addGestureRecognizer(areaTap)
        } else {
            // No clipboard — show context-aware message
            let isWhatsAppSync = selectedConversation?.threadId != nil ||
                (selectedConversation?.platform.lowercased().contains("whatsapp") ?? false)

            clipArea.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            clipArea.layer.borderWidth = 1
            clipArea.layer.borderColor = isWhatsAppSync ? Theme.successGreen.withAlphaComponent(0.15).cgColor : Theme.border.cgColor

            if isWhatsAppSync {
                // WhatsApp synced — show hint or waiting message
                let pulseIcon = UIView()
                pulseIcon.backgroundColor = conversationHint != nil ? Theme.accentWarm : Theme.successGreen
                pulseIcon.layer.cornerRadius = 5
                pulseIcon.translatesAutoresizingMaskIntoConstraints = false
                clipArea.addSubview(pulseIcon)

                UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
                    pulseIcon.alpha = 0.3
                }

                let waitLabel = UILabel()
                if let hint = conversationHint {
                    waitLabel.text = hint
                    waitLabel.textColor = Theme.accentWarm.withAlphaComponent(0.9)
                } else {
                    let name = selectedConversation?.matchName ?? "contato"
                    waitLabel.text = "Aguardando mensagem de \(name)..."
                    waitLabel.textColor = Theme.successGreen.withAlphaComponent(0.8)
                }
                waitLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                waitLabel.numberOfLines = 2
                waitLabel.translatesAutoresizingMaskIntoConstraints = false
                clipArea.addSubview(waitLabel)

                NSLayoutConstraint.activate([
                    pulseIcon.leadingAnchor.constraint(equalTo: clipArea.leadingAnchor, constant: 14),
                    pulseIcon.centerYAnchor.constraint(equalTo: clipArea.centerYAnchor),
                    pulseIcon.widthAnchor.constraint(equalToConstant: 10),
                    pulseIcon.heightAnchor.constraint(equalToConstant: 10),
                    waitLabel.leadingAnchor.constraint(equalTo: pulseIcon.trailingAnchor, constant: 10),
                    waitLabel.trailingAnchor.constraint(equalTo: clipArea.trailingAnchor, constant: -12),
                    waitLabel.centerYAnchor.constraint(equalTo: clipArea.centerYAnchor),
                ])
            } else {
                // Non-WhatsApp — show paste instruction
                let pasteIcon = UIImageView(image: UIImage(systemName: "doc.on.clipboard"))
                pasteIcon.tintColor = Theme.accent
                pasteIcon.translatesAutoresizingMaskIntoConstraints = false
                pasteIcon.contentMode = .scaleAspectFit
                clipArea.addSubview(pasteIcon)

                let pasteLabel = UILabel()
                pasteLabel.text = "Copie a mensagem dela e volte aqui"
                pasteLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
                pasteLabel.textColor = Theme.textSecondary
                pasteLabel.translatesAutoresizingMaskIntoConstraints = false
                clipArea.addSubview(pasteLabel)

                NSLayoutConstraint.activate([
                    pasteIcon.leadingAnchor.constraint(equalTo: clipArea.leadingAnchor, constant: 14),
                    pasteIcon.centerYAnchor.constraint(equalTo: clipArea.centerYAnchor),
                    pasteIcon.widthAnchor.constraint(equalToConstant: 20),
                    pasteIcon.heightAnchor.constraint(equalToConstant: 20),
                    pasteLabel.leadingAnchor.constraint(equalTo: pasteIcon.trailingAnchor, constant: 10),
                    pasteLabel.centerYAnchor.constraint(equalTo: clipArea.centerYAnchor),
                ])
            }

            let pasteTap = UITapGestureRecognizer(target: self, action: #selector(pasteBoxTapped))
            clipArea.addGestureRecognizer(pasteTap)
        }

        // ── Row 3: Two input buttons ──
        let actionsStack = UIStackView()
        actionsStack.axis = .horizontal
        actionsStack.spacing = 10
        actionsStack.distribution = .fillEqually
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(actionsStack)

        let screenshotBtn = makeActionButton(emoji: "📸", label: "Analisar Print", action: #selector(openAppForScreenshot))
        let pasteBtn = makeActionButton(emoji: "📋", label: "Colar Mensagem", action: #selector(pasteBoxTapped))

        actionsStack.addArrangedSubview(screenshotBtn)
        actionsStack.addArrangedSubview(pasteBtn)

        // ── Row 4: Secondary link ──
        let startLabel = UILabel()
        startLabel.text = "🚀 Gerar abertura criativa"
        startLabel.textColor = Theme.textSecondary
        startLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        startLabel.textAlignment = .center
        startLabel.translatesAutoresizingMaskIntoConstraints = false
        startLabel.isUserInteractionEnabled = true
        let startTap = UITapGestureRecognizer(target: self, action: #selector(startConversationTapped))
        startLabel.addGestureRecognizer(startTap)
        containerView.addSubview(startLabel)

        // ── Layout ──
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            headerStack.heightAnchor.constraint(equalToConstant: 36),

            clipArea.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            clipArea.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            clipArea.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            clipArea.heightAnchor.constraint(equalToConstant: 52),

            actionsStack.topAnchor.constraint(equalTo: clipArea.bottomAnchor, constant: 10),
            actionsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            actionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            actionsStack.heightAnchor.constraint(equalToConstant: 64),

            startLabel.topAnchor.constraint(equalTo: actionsStack.bottomAnchor, constant: 10),
            startLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])

        startClipboardPolling()
        startMessagePolling()
    }

    // MARK: - Hub Helpers

    func makeActionButton(emoji: String, label: String, action: Selector) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = Theme.cardBg
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = Theme.border.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false
        container.addSubview(stack)

        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 22)
        stack.addArrangedSubview(emojiLabel)

        let textLabel = UILabel()
        textLabel.text = label
        textLabel.textColor = Theme.textSecondary
        textLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        stack.addArrangedSubview(textLabel)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: action)
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true

        return container
    }

    @objc func avatarTapped() {
        currentState = .profilePicker
        renderCurrentState()
    }

    @objc func openAppForScreenshot() {
        // Save current profile context for the app
        if let conv = selectedConversation {
            sharedDefaults?.set(conv.matchName, forKey: "kb_pendingProfileName")
            sharedDefaults?.synchronize()
        }
        // Open main app via URL scheme using responder chain
        if let url = URL(string: "desenrolaai://analyze-screenshot") {
            var responder: UIResponder? = self
            while let r = responder {
                if let app = r as? UIApplication {
                    app.open(url, options: [:], completionHandler: nil)
                    break
                }
                responder = r.next
            }
        }
    }

    // Check for pending text from app (auto-insert after returning from screenshot analysis)
    func checkPendingInsert() {
        guard let text = sharedDefaults?.string(forKey: "kb_pendingInsertText"),
              !text.isEmpty else { return }
        // Clear the pending text
        sharedDefaults?.removeObject(forKey: "kb_pendingInsertText")
        sharedDefaults?.synchronize()
        // Insert into text field
        textDocumentProxy.insertText(text)
        // Send to server if profile selected
        if let conv = selectedConversation {
            sendMessageToServer(conversationId: conv.conversationId, profileId: conv.profileId, content: text, wasAiSuggestion: true)
        }
        // Switch back to system keyboard
        advanceToNextInputMode()
    }

    @objc func clipAreaTapped() {
        let clip = clipboardText
        guard let text = clip, !text.isEmpty else { return }
        clipboardText = text
        consumedClipboard = text
        stopClipboardPolling()
        suggestions = []
        isLoadingSuggestions = true
        previousState = .hub
        currentState = .suggestions
        renderCurrentState()
        analyzeText(text, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective(), threadId: selectedConversation?.threadId, matchName: selectedConversation?.matchName)
    }
}
