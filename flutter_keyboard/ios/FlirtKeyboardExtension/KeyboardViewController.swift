import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - State Machine

    enum KeyboardState {
        case profileSelector
        case awaitingClipboard
        case suggestions
        case writeOwn
        case basicMode
        case multipleMessages
    }

    enum OverlayType {
        case none
        case objectiveSelector
        case toneSelector
    }

    // MARK: - Theme Colors (derived from app logo flame gradient)

    private struct Theme {
        static let bg = UIColor(red: 0.07, green: 0.055, blue: 0.086, alpha: 1.0)
        static let cardBg = UIColor(red: 0.137, green: 0.11, blue: 0.176, alpha: 1.0)
        static let rose = UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0)
        static let orange = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0)
        static let purple = UIColor(red: 0.48, green: 0.18, blue: 0.74, alpha: 1.0)
        static let textSecondary = UIColor(red: 0.63, green: 0.59, blue: 0.67, alpha: 1.0)
        static let clipText = UIColor(red: 1.0, green: 0.71, blue: 0.59, alpha: 1.0)
        static let suggestionBg = UIColor(red: 0.157, green: 0.125, blue: 0.204, alpha: 1.0)
        static let overlayBg = UIColor(red: 0.07, green: 0.055, blue: 0.086, alpha: 0.97)
        static let selectedBg = UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 0.15)
        static let errorText = UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
    }

    // MARK: - Objective Data

    private struct Objective {
        let id: String
        let emoji: String
        let title: String
        let description: String
    }

    private let availableObjectives: [Objective] = [
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

    // MARK: - Tone Data (with Auto)

    private let availableTones = ["automatico", "engraçado", "ousado", "romântico", "casual", "confiante"]
    private let toneEmojis = ["🤖", "😄", "🔥", "❤️", "😎", "💪"]
    private let toneLabels = ["Auto", "Engraçado", "Ousado", "Romântico", "Casual", "Confiante"]

    // MARK: - Properties

    private var currentState: KeyboardState = .profileSelector
    private var activeOverlay: OverlayType = .none
    private var containerView: UIView!

    private struct ConversationContext {
        let conversationId: String?
        let profileId: String?
        let matchName: String
        let platform: String
        let lastMessage: String?
        let faceImageBase64: String?
    }

    private var conversations: [ConversationContext] = []
    private var filteredConversations: [ConversationContext] = []
    private var selectedConversation: ConversationContext?
    private var clipboardText: String?
    private var suggestions: [String] = []
    private var previousClipboard: String?
    private var isLoadingProfiles = true
    private var profilesError: String?
    private var searchText: String = ""
    private var selectedToneIndex: Int = 0
    private var selectedObjectiveIndex: Int = 0
    private var isLoadingSuggestions = false
    private var writeOwnText: String = ""
    private var isShiftActive: Bool = true
    private var isSearchActive: Bool = false
    private var multiMessages: [String] = ["", ""]

    // Shared config
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.desenrolaai.app.shared")
    }

    private var backendUrl: String {
        return sharedDefaults?.string(forKey: "backendUrl") ?? "https://dating-app-production-ac43.up.railway.app"
    }

    private var authToken: String? {
        return sharedDefaults?.string(forKey: "authToken")
    }

    private var userId: String? {
        return sharedDefaults?.string(forKey: "userId")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bg
        previousClipboard = UIPasteboard.general.string

        if authToken != nil {
            // Try to restore previously selected conversation
            if let saved = restoreSavedConversation() {
                selectedConversation = saved
                currentState = .awaitingClipboard
                // Also fetch conversations in background so back button works
                fetchConversations(silent: true)
            } else {
                currentState = .profileSelector
                fetchConversations()
            }
        } else {
            currentState = .basicMode
        }

        renderCurrentState()
    }

    // MARK: - State Rendering

    private func renderCurrentState() {
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
            containerView.heightAnchor.constraint(equalToConstant: (currentState == .profileSelector && isSearchActive || currentState == .multipleMessages) ? 260 : 220)
        ])

        switch currentState {
        case .profileSelector: renderProfileSelector()
        case .awaitingClipboard: renderAwaitingClipboard()
        case .suggestions: renderSuggestions()
        case .writeOwn: renderWriteOwn()
        case .basicMode: renderBasicMode()
        case .multipleMessages: renderMultipleMessages()
        }
    }

    // MARK: - Estado 1: Profile Selector

    private func renderProfileSelector() {
        // Search bar (tappable — opens QWERTY overlay)
        let searchContainer = UIView()
        searchContainer.backgroundColor = isSearchActive ? Theme.rose.withAlphaComponent(0.15) : Theme.cardBg
        searchContainer.layer.cornerRadius = 8
        if isSearchActive {
            searchContainer.layer.borderWidth = 0.5
            searchContainer.layer.borderColor = Theme.rose.withAlphaComponent(0.5).cgColor
        }
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.isUserInteractionEnabled = true
        let searchTap = UITapGestureRecognizer(target: self, action: #selector(searchBarTapped))
        searchContainer.addGestureRecognizer(searchTap)
        containerView.addSubview(searchContainer)

        let searchLabel = UILabel()
        searchLabel.text = searchText.isEmpty ? "🔍 Buscar perfil..." : "🔍 \(searchText)"
        searchLabel.textColor = searchText.isEmpty ? Theme.textSecondary : .white
        searchLabel.font = UIFont.systemFont(ofSize: 13)
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchLabel)

        if isSearchActive {
            // --- SEARCH MODE: no title, input at top, QWERTY + profiles ---

            // Blinking cursor in search bar
            let cursor = UIView()
            cursor.backgroundColor = Theme.rose
            cursor.translatesAutoresizingMaskIntoConstraints = false
            searchContainer.addSubview(cursor)

            NSLayoutConstraint.activate([
                searchContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                searchContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                searchContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                searchContainer.heightAnchor.constraint(equalToConstant: 32),
                searchLabel.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
                searchLabel.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
                cursor.leadingAnchor.constraint(equalTo: searchLabel.trailingAnchor, constant: 1),
                cursor.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
                cursor.widthAnchor.constraint(equalToConstant: 2),
                cursor.heightAnchor.constraint(equalToConstant: 16),
            ])

            UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
                cursor.alpha = 0
            })

            let qwertyView = makeQWERTYKeyboard(forSearch: true)
            containerView.addSubview(qwertyView)

            NSLayoutConstraint.activate([
                qwertyView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 3),
                qwertyView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
                qwertyView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
                qwertyView.heightAnchor.constraint(equalToConstant: 82),
            ])

            // Filtered profile list below QWERTY
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsHorizontalScrollIndicator = false
            containerView.addSubview(scrollView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: qwertyView.bottomAnchor, constant: 4),
                scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
            ])

            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            ])

            if filteredConversations.isEmpty && !searchText.isEmpty {
                let l = makeLabel("Nenhum perfil encontrado", size: 12)
                l.textColor = Theme.textSecondary
                stackView.addArrangedSubview(l)
            } else {
                for (index, conv) in filteredConversations.enumerated() {
                    stackView.addArrangedSubview(makeProfileButton(conv, tag: index))
                }
            }

        } else {
            // --- NORMAL MODE: title + search bar + profiles + quick button ---
            let titleLabel = makeLabel("Com quem você está falando?", size: 14, bold: true)
            containerView.addSubview(titleLabel)

            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                searchContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                searchContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                searchContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                searchContainer.heightAnchor.constraint(equalToConstant: 28),
                searchLabel.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
                searchLabel.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -8),
                searchLabel.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            ])
            // --- Normal mode: profiles + quick button visible ---
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsHorizontalScrollIndicator = false
            containerView.addSubview(scrollView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 8),
                scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                scrollView.heightAnchor.constraint(equalToConstant: 80),
            ])

            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            ])

            if isLoadingProfiles {
                let l = makeLabel("Carregando perfis...", size: 12)
                l.textColor = Theme.textSecondary
                stackView.addArrangedSubview(l)
            } else if let error = profilesError {
                let l = makeLabel(error, size: 11)
                l.textColor = Theme.errorText
                l.numberOfLines = 2
                stackView.addArrangedSubview(l)
            } else if conversations.isEmpty {
                let l = makeLabel("Nenhum perfil criado.\nCrie um perfil no app primeiro.", size: 12)
                l.textColor = Theme.textSecondary
                l.numberOfLines = 2
                stackView.addArrangedSubview(l)
            } else {
                for (index, conv) in filteredConversations.enumerated() {
                    stackView.addArrangedSubview(makeProfileButton(conv, tag: index))
                }
            }

            let quickButton = makeGradientButton("⚡ Modo Rápido — sem perfil", fontSize: 13)
            quickButton.addTarget(self, action: #selector(quickModeTapped), for: .touchUpInside)
            containerView.addSubview(quickButton)

            let switchBtn = makeKeyboardSwitchButton()
            containerView.addSubview(switchBtn)

            NSLayoutConstraint.activate([
                quickButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
                quickButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                quickButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -56),
                quickButton.heightAnchor.constraint(equalToConstant: 36),
                switchBtn.centerYAnchor.constraint(equalTo: quickButton.centerYAnchor),
                switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                switchBtn.widthAnchor.constraint(equalToConstant: 32),
            ])
        }
    }

    @objc private func searchBarTapped() {
        isSearchActive = !isSearchActive
        if !isSearchActive {
            searchText = ""
            filteredConversations = conversations
        }
        renderCurrentState()
    }

    // MARK: - Estado 2: Awaiting Clipboard (PRO)

    private func renderAwaitingClipboard() {
        guard let conv = selectedConversation else { return }

        let headerView = makeHeader("👤 \(conv.matchName) (\(conv.platform))", showBack: true)
        containerView.addSubview(headerView)

        let switchBtn = makeKeyboardSwitchButton()
        containerView.addSubview(switchBtn)

        // Pills row
        let pillsStack = UIStackView()
        pillsStack.axis = .horizontal
        pillsStack.spacing = 8
        pillsStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(pillsStack)

        let objPill = makeObjectivePill()
        let tonePill = makeTonePill()
        pillsStack.addArrangedSubview(objPill)
        pillsStack.addArrangedSubview(tonePill)
        let pillSpacer = UIView()
        pillsStack.addArrangedSubview(pillSpacer)

        // Paste input box
        let pasteBox = UIButton(type: .system)
        pasteBox.translatesAutoresizingMaskIntoConstraints = false
        pasteBox.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        pasteBox.layer.cornerRadius = 12
        pasteBox.layer.borderWidth = 1
        pasteBox.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor

        let pasteIcon = UIImageView(image: UIImage(systemName: "doc.on.clipboard"))
        pasteIcon.tintColor = Theme.rose
        pasteIcon.translatesAutoresizingMaskIntoConstraints = false
        pasteIcon.contentMode = .scaleAspectFit
        pasteBox.addSubview(pasteIcon)

        let pasteLabel = UILabel()
        pasteLabel.text = "Cole a mensagem dela aqui"
        pasteLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        pasteLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        pasteLabel.translatesAutoresizingMaskIntoConstraints = false
        pasteBox.addSubview(pasteLabel)

        pasteBox.addTarget(self, action: #selector(pasteBoxTapped), for: .touchUpInside)
        containerView.addSubview(pasteBox)

        let hintLabel = makeLabel("Copie a mensagem no app de conversa e toque aqui", size: 11)
        hintLabel.textColor = Theme.textSecondary
        hintLabel.textAlignment = .center
        containerView.addSubview(hintLabel)

        // Multi-message link
        let multiBtn = UIButton(type: .system)
        multiBtn.translatesAutoresizingMaskIntoConstraints = false
        multiBtn.setTitle("Recebeu várias mensagens? Toque aqui", for: .normal)
        multiBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        multiBtn.setTitleColor(Theme.rose.withAlphaComponent(0.7), for: .normal)
        multiBtn.addTarget(self, action: #selector(multiMessageModeTapped), for: .touchUpInside)
        containerView.addSubview(multiBtn)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),
            switchBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            pillsStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            pillsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            pillsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            pillsStack.heightAnchor.constraint(equalToConstant: 28),
            pasteBox.topAnchor.constraint(equalTo: pillsStack.bottomAnchor, constant: 12),
            pasteBox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            pasteBox.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            pasteBox.heightAnchor.constraint(equalToConstant: 48),
            pasteIcon.leadingAnchor.constraint(equalTo: pasteBox.leadingAnchor, constant: 14),
            pasteIcon.centerYAnchor.constraint(equalTo: pasteBox.centerYAnchor),
            pasteIcon.widthAnchor.constraint(equalToConstant: 20),
            pasteIcon.heightAnchor.constraint(equalToConstant: 20),
            pasteLabel.leadingAnchor.constraint(equalTo: pasteIcon.trailingAnchor, constant: 10),
            pasteLabel.centerYAnchor.constraint(equalTo: pasteBox.centerYAnchor),
            hintLabel.topAnchor.constraint(equalTo: pasteBox.bottomAnchor, constant: 6),
            hintLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            multiBtn.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 4),
            multiBtn.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])

        startClipboardPolling()
    }

    @objc private func pasteBoxTapped() {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            clipboardText = text
            previousClipboard = text
            stopClipboardPolling()
            suggestions = []
            isLoadingSuggestions = true
            currentState = .suggestions
            renderCurrentState()
            analyzeText(text, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
        }
    }

    @objc private func multiMessageModeTapped() {
        stopClipboardPolling()
        multiMessages = ["", ""]
        currentState = .multipleMessages
        renderCurrentState()
    }

    // MARK: - Estado 2.5: Multiple Messages

    private func renderMultipleMessages() {
        guard let conv = selectedConversation else { return }

        // Custom header with back to awaitingClipboard (not profileSelector)
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let backBtn = UIButton(type: .system)
        backBtn.setTitle("←", for: .normal)
        backBtn.setTitleColor(Theme.textSecondary, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        backBtn.addTarget(self, action: #selector(backToAwaitingTapped), for: .touchUpInside)
        headerStack.addArrangedSubview(backBtn)

        let titleLabel = UILabel()
        titleLabel.text = "📋 Várias mensagens"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(UIView())

        let headerView = headerStack
        containerView.addSubview(headerView)

        let switchBtn = makeKeyboardSwitchButton()
        containerView.addSubview(switchBtn)

        // Scroll view for message fields
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.alwaysBounceVertical = true
        containerView.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Message fields
        for (index, message) in multiMessages.enumerated() {
            let card = makeMultiMessageCard(index: index, text: message)
            contentStack.addArrangedSubview(card)
        }

        // "+ Adicionar mensagem" button
        let addBtn = UIButton(type: .system)
        addBtn.translatesAutoresizingMaskIntoConstraints = false
        addBtn.setTitle("+ Adicionar mensagem", for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        addBtn.setTitleColor(Theme.rose, for: .normal)
        addBtn.backgroundColor = Theme.rose.withAlphaComponent(0.1)
        addBtn.layer.cornerRadius = 10
        addBtn.layer.borderWidth = 1
        addBtn.layer.borderColor = Theme.rose.withAlphaComponent(0.3).cgColor
        addBtn.addTarget(self, action: #selector(addMultiMessageTapped), for: .touchUpInside)
        addBtn.heightAnchor.constraint(equalToConstant: 36).isActive = true
        contentStack.addArrangedSubview(addBtn)

        // "Gerar Respostas" button
        let hasContent = multiMessages.contains { !$0.isEmpty }
        let generateBtn = makeGradientButton("Gerar Respostas", fontSize: 14)
        generateBtn.addTarget(self, action: #selector(multiMessageGenerateTapped), for: .touchUpInside)
        generateBtn.alpha = hasContent ? 1.0 : 0.4
        generateBtn.isEnabled = hasContent
        generateBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(generateBtn)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),
            switchBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -24),
        ])
    }

    private func makeMultiMessageCard(index: Int, text: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = Theme.cardBg
        card.layer.cornerRadius = 10
        card.layer.borderWidth = 1
        card.layer.borderColor = text.isEmpty
            ? UIColor.white.withAlphaComponent(0.1).cgColor
            : Theme.rose.withAlphaComponent(0.3).cgColor

        // Number label
        let numLabel = UILabel()
        numLabel.text = "Mensagem \(index + 1)"
        numLabel.font = UIFont.boldSystemFont(ofSize: 11)
        numLabel.textColor = Theme.textSecondary
        numLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(numLabel)

        if text.isEmpty {
            // Paste button (empty state)
            let pasteBtn = UIButton(type: .system)
            pasteBtn.tag = 500 + index
            pasteBtn.translatesAutoresizingMaskIntoConstraints = false

            let icon = UIImageView(image: UIImage(systemName: "doc.on.clipboard"))
            icon.tintColor = Theme.rose.withAlphaComponent(0.6)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFit
            pasteBtn.addSubview(icon)

            let label = UILabel()
            label.text = "Toque para colar"
            label.font = UIFont.systemFont(ofSize: 13)
            label.textColor = UIColor.white.withAlphaComponent(0.4)
            label.translatesAutoresizingMaskIntoConstraints = false
            pasteBtn.addSubview(label)

            pasteBtn.addTarget(self, action: #selector(multiMessagePasteTapped(_:)), for: .touchUpInside)
            card.addSubview(pasteBtn)

            NSLayoutConstraint.activate([
                numLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
                numLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),

                pasteBtn.topAnchor.constraint(equalTo: card.topAnchor),
                pasteBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                pasteBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                pasteBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor),

                icon.leadingAnchor.constraint(equalTo: pasteBtn.leadingAnchor, constant: 12),
                icon.bottomAnchor.constraint(equalTo: pasteBtn.bottomAnchor, constant: -10),
                icon.widthAnchor.constraint(equalToConstant: 16),
                icon.heightAnchor.constraint(equalToConstant: 16),

                label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6),
                label.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            ])
        } else {
            // Filled state - show text + clear button
            let textLabel = UILabel()
            textLabel.text = text
            textLabel.font = UIFont.systemFont(ofSize: 12)
            textLabel.textColor = .white
            textLabel.numberOfLines = 2
            textLabel.lineBreakMode = .byTruncatingTail
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(textLabel)

            let checkIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            checkIcon.tintColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
            checkIcon.translatesAutoresizingMaskIntoConstraints = false
            checkIcon.contentMode = .scaleAspectFit
            card.addSubview(checkIcon)

            let clearBtn = UIButton(type: .system)
            clearBtn.tag = 600 + index
            clearBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            clearBtn.tintColor = Theme.textSecondary
            clearBtn.translatesAutoresizingMaskIntoConstraints = false
            clearBtn.addTarget(self, action: #selector(multiMessageClearTapped(_:)), for: .touchUpInside)
            card.addSubview(clearBtn)

            NSLayoutConstraint.activate([
                numLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
                numLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),

                checkIcon.centerYAnchor.constraint(equalTo: numLabel.centerYAnchor),
                checkIcon.leadingAnchor.constraint(equalTo: numLabel.trailingAnchor, constant: 4),
                checkIcon.widthAnchor.constraint(equalToConstant: 14),
                checkIcon.heightAnchor.constraint(equalToConstant: 14),

                clearBtn.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
                clearBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
                clearBtn.widthAnchor.constraint(equalToConstant: 24),
                clearBtn.heightAnchor.constraint(equalToConstant: 24),

                textLabel.topAnchor.constraint(equalTo: numLabel.bottomAnchor, constant: 4),
                textLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                textLabel.trailingAnchor.constraint(equalTo: clearBtn.leadingAnchor, constant: -4),
                textLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            ])
        }

        card.heightAnchor.constraint(greaterThanOrEqualToConstant: text.isEmpty ? 52 : 56).isActive = true
        return card
    }

    @objc private func backToAwaitingTapped() {
        multiMessages = ["", ""]
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func multiMessagePasteTapped(_ sender: UIButton) {
        let index = sender.tag - 500
        guard index >= 0 && index < multiMessages.count else { return }
        if let text = UIPasteboard.general.string, !text.isEmpty {
            multiMessages[index] = text
            renderCurrentState()
        }
    }

    @objc private func multiMessageClearTapped(_ sender: UIButton) {
        let index = sender.tag - 600
        guard index >= 0 && index < multiMessages.count else { return }
        multiMessages[index] = ""
        renderCurrentState()
    }

    @objc private func addMultiMessageTapped() {
        multiMessages.append("")
        renderCurrentState()
    }

    @objc private func multiMessageGenerateTapped() {
        let filledMessages = multiMessages.filter { !$0.isEmpty }
        guard !filledMessages.isEmpty else { return }

        let combinedText = filledMessages.enumerated().map { (i, msg) in
            "Mensagem \(i + 1): \(msg)"
        }.joined(separator: "\n")

        clipboardText = combinedText
        previousClipboard = UIPasteboard.general.string
        stopClipboardPolling()
        suggestions = []
        isLoadingSuggestions = true
        currentState = .suggestions
        renderCurrentState()
        analyzeText(combinedText, tone: currentTone(),
                    conversationId: selectedConversation?.conversationId,
                    objective: currentObjective())
    }

    // MARK: - Estado 3: Suggestions (PRO)

    private func renderSuggestions() {
        guard let conv = selectedConversation else { return }

        // Compact header with message preview
        let headerLabel = makeLabel("👤 \(conv.matchName)", size: 11, bold: true)
        containerView.addSubview(headerLabel)

        let clipPreview = makeLabel("💬 \"\(clipboardText?.prefix(50) ?? "")\"", size: 10)
        clipPreview.textColor = Theme.clipText
        clipPreview.numberOfLines = 1
        containerView.addSubview(clipPreview)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            clipPreview.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            clipPreview.leadingAnchor.constraint(equalTo: headerLabel.trailingAnchor, constant: 8),
            clipPreview.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
        ])

        if suggestions.isEmpty {
            let loadingStack = UIStackView()
            loadingStack.axis = .horizontal
            loadingStack.spacing = 10
            loadingStack.alignment = .center
            loadingStack.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(loadingStack)

            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = Theme.rose
            spinner.startAnimating()
            loadingStack.addArrangedSubview(spinner)

            let loadLabel = UILabel()
            loadLabel.text = "Gerando sugestões..."
            loadLabel.textColor = Theme.textSecondary
            loadLabel.font = UIFont.systemFont(ofSize: 14)
            loadingStack.addArrangedSubview(loadLabel)

            NSLayoutConstraint.activate([
                loadingStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 30),
                loadingStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            ])
            return
        }

        // Scrollable suggestions area
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.alwaysBounceVertical = false
        containerView.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        for (index, suggestion) in suggestions.prefix(3).enumerated() {
            let card = makeSuggestionCard(index: index, text: suggestion)
            contentStack.addArrangedSubview(card)
        }

        // Bottom bar with styled input bar + regen button + pills
        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bottomBar)

        // Text input bar (tap to enter writeOwn state)
        let writeBar = UIView()
        writeBar.backgroundColor = Theme.cardBg
        writeBar.layer.cornerRadius = 8
        writeBar.layer.borderWidth = 0.5
        writeBar.layer.borderColor = Theme.rose.withAlphaComponent(0.3).cgColor
        writeBar.translatesAutoresizingMaskIntoConstraints = false
        writeBar.isUserInteractionEnabled = true
        let writeTap = UITapGestureRecognizer(target: self, action: #selector(writeOwnTapped))
        writeBar.addGestureRecognizer(writeTap)
        bottomBar.addSubview(writeBar)

        let writeIcon = UILabel()
        writeIcon.text = "✎"
        writeIcon.textColor = Theme.textSecondary
        writeIcon.font = UIFont.systemFont(ofSize: 11)
        writeIcon.translatesAutoresizingMaskIntoConstraints = false
        writeBar.addSubview(writeIcon)

        let writeLabel = UILabel()
        writeLabel.text = "Escrever resposta..."
        writeLabel.textColor = Theme.textSecondary
        writeLabel.font = UIFont.systemFont(ofSize: 11)
        writeLabel.translatesAutoresizingMaskIntoConstraints = false
        writeBar.addSubview(writeLabel)

        // Blinking cursor in write bar
        let writeCursor = UIView()
        writeCursor.backgroundColor = Theme.rose
        writeCursor.translatesAutoresizingMaskIntoConstraints = false
        writeBar.addSubview(writeCursor)

        // Styled regen button
        let regenBtn = UIButton(type: .system)
        if #available(iOSApplicationExtension 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            regenBtn.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: config), for: .normal)
        } else {
            regenBtn.setTitle("↻", for: .normal)
        }
        regenBtn.tintColor = .white
        regenBtn.backgroundColor = Theme.rose.withAlphaComponent(0.25)
        regenBtn.layer.cornerRadius = 8
        regenBtn.translatesAutoresizingMaskIntoConstraints = false
        regenBtn.addTarget(self, action: #selector(regenerateTapped), for: .touchUpInside)
        bottomBar.addSubview(regenBtn)

        let objPill = makeObjectivePill(compact: true)
        let tonePill = makeTonePill(compact: true)
        bottomBar.addSubview(objPill)
        bottomBar.addSubview(tonePill)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            bottomBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            bottomBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6),
            bottomBar.heightAnchor.constraint(equalToConstant: 30),

            writeBar.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            writeBar.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            writeBar.heightAnchor.constraint(equalToConstant: 28),
            writeIcon.leadingAnchor.constraint(equalTo: writeBar.leadingAnchor, constant: 8),
            writeIcon.centerYAnchor.constraint(equalTo: writeBar.centerYAnchor),
            writeLabel.leadingAnchor.constraint(equalTo: writeIcon.trailingAnchor, constant: 4),
            writeLabel.centerYAnchor.constraint(equalTo: writeBar.centerYAnchor),
            writeCursor.leadingAnchor.constraint(equalTo: writeLabel.trailingAnchor, constant: 1),
            writeCursor.centerYAnchor.constraint(equalTo: writeBar.centerYAnchor),
            writeCursor.widthAnchor.constraint(equalToConstant: 1.5),
            writeCursor.heightAnchor.constraint(equalToConstant: 14),
            writeCursor.trailingAnchor.constraint(lessThanOrEqualTo: writeBar.trailingAnchor, constant: -4),

            regenBtn.leadingAnchor.constraint(equalTo: writeBar.trailingAnchor, constant: 6),
            regenBtn.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            regenBtn.widthAnchor.constraint(equalToConstant: 32),
            regenBtn.heightAnchor.constraint(equalToConstant: 28),

            objPill.leadingAnchor.constraint(equalTo: regenBtn.trailingAnchor, constant: 6),
            objPill.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            tonePill.leadingAnchor.constraint(equalTo: objPill.trailingAnchor, constant: 4),
            tonePill.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            tonePill.trailingAnchor.constraint(lessThanOrEqualTo: bottomBar.trailingAnchor),
        ])

        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            writeCursor.alpha = 0
        })
    }

    private func makeSuggestionCard(index: Int, text: String, isBasicMode: Bool = false) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = Theme.suggestionBg
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 0.5
        card.layer.borderColor = Theme.rose.withAlphaComponent(0.2).cgColor

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = .white
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textLabel)

        // Send/select button
        let sendBtn = UIButton(type: .system)
        sendBtn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendBtn.tintColor = Theme.rose
        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        sendBtn.tag = isBasicMode ? (100 + index) : index
        sendBtn.addTarget(self, action: isBasicMode ? #selector(basicSuggestionTapped(_:)) : #selector(suggestionTapped(_:)), for: .touchUpInside)
        card.addSubview(sendBtn)

        // Make entire card tappable
        let tapBtn = UIButton(type: .system)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        tapBtn.tag = isBasicMode ? (100 + index) : index
        tapBtn.addTarget(self, action: isBasicMode ? #selector(basicSuggestionTapped(_:)) : #selector(suggestionTapped(_:)), for: .touchUpInside)
        card.insertSubview(tapBtn, at: 0)

        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            textLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: sendBtn.leadingAnchor, constant: -8),
            textLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            sendBtn.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            sendBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            sendBtn.widthAnchor.constraint(equalToConstant: 30),
            sendBtn.heightAnchor.constraint(equalToConstant: 30),
            tapBtn.topAnchor.constraint(equalTo: card.topAnchor),
            tapBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tapBtn.trailingAnchor.constraint(equalTo: sendBtn.leadingAnchor),
            tapBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        return card
    }

    // MARK: - Estado 3B: Write Own (PRO)

    private func renderWriteOwn() {
        guard let conv = selectedConversation else { return }

        // Text display bar showing what user is typing
        let textDisplay = UIView()
        textDisplay.backgroundColor = Theme.cardBg
        textDisplay.layer.cornerRadius = 8
        textDisplay.layer.borderWidth = 1
        textDisplay.layer.borderColor = Theme.rose.withAlphaComponent(0.4).cgColor
        textDisplay.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textDisplay)

        let displayLabel = UILabel()
        displayLabel.tag = 998
        displayLabel.text = writeOwnText.isEmpty ? "Digite sua resposta..." : writeOwnText
        displayLabel.textColor = writeOwnText.isEmpty ? Theme.textSecondary : .white
        displayLabel.font = UIFont.systemFont(ofSize: 14)
        displayLabel.translatesAutoresizingMaskIntoConstraints = false
        textDisplay.addSubview(displayLabel)

        // Cursor blink indicator
        let cursor = UIView()
        cursor.backgroundColor = Theme.rose
        cursor.translatesAutoresizingMaskIntoConstraints = false
        textDisplay.addSubview(cursor)

        // QWERTY keyboard for typing
        let qwertyView = makeQWERTYKeyboard(forSearch: false)
        containerView.addSubview(qwertyView)

        // Bottom buttons row (inside QWERTY bottom row)
        NSLayoutConstraint.activate([
            textDisplay.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            textDisplay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            textDisplay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            textDisplay.heightAnchor.constraint(equalToConstant: 34),

            displayLabel.leadingAnchor.constraint(equalTo: textDisplay.leadingAnchor, constant: 10),
            displayLabel.trailingAnchor.constraint(equalTo: textDisplay.trailingAnchor, constant: -10),
            displayLabel.centerYAnchor.constraint(equalTo: textDisplay.centerYAnchor),

            qwertyView.topAnchor.constraint(equalTo: textDisplay.bottomAnchor, constant: 4),
            qwertyView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            qwertyView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            qwertyView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
        ])

        NSLayoutConstraint.activate([
            cursor.leadingAnchor.constraint(equalTo: displayLabel.trailingAnchor, constant: 1),
            cursor.centerYAnchor.constraint(equalTo: textDisplay.centerYAnchor),
            cursor.widthAnchor.constraint(equalToConstant: 2),
            cursor.heightAnchor.constraint(equalToConstant: 18),
        ])

        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            cursor.alpha = 0
        })
    }

    // MARK: - Estado 4: Basic Mode

    private func renderBasicMode() {
        let headerView = makeHeader("⚡ Modo Rápido", showBack: authToken != nil)
        containerView.addSubview(headerView)

        let switchBtn = makeKeyboardSwitchButton()
        containerView.addSubview(switchBtn)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),
            switchBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
        ])

        let clip = getClipboardText()

        if let clip = clip {
            let clipLabel = makeLabel("\"\(clip.count > 80 ? String(clip.prefix(77)) + "..." : clip)\"", size: 11)
            clipLabel.textColor = Theme.clipText
            clipLabel.numberOfLines = 2
            containerView.addSubview(clipLabel)

            NSLayoutConstraint.activate([
                clipLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
                clipLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                clipLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            ])

            if !suggestions.isEmpty {
                // Scrollable suggestions area (same card style as PRO mode)
                let scrollView = UIScrollView()
                scrollView.translatesAutoresizingMaskIntoConstraints = false
                scrollView.showsVerticalScrollIndicator = true
                scrollView.indicatorStyle = .white
                scrollView.alwaysBounceVertical = false
                containerView.addSubview(scrollView)

                let contentStack = UIStackView()
                contentStack.axis = .vertical
                contentStack.spacing = 6
                contentStack.translatesAutoresizingMaskIntoConstraints = false
                scrollView.addSubview(contentStack)

                for (index, suggestion) in suggestions.prefix(3).enumerated() {
                    let card = makeSuggestionCard(index: index, text: suggestion, isBasicMode: true)
                    contentStack.addArrangedSubview(card)
                }

                let bottomStack = UIStackView()
                bottomStack.axis = .horizontal
                bottomStack.spacing = 6
                bottomStack.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(bottomStack)

                let regenBtn = UIButton(type: .system)
                if #available(iOSApplicationExtension 13.0, *) {
                    let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
                    regenBtn.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: config), for: .normal)
                } else {
                    regenBtn.setTitle("↻", for: .normal)
                }
                regenBtn.tintColor = .white
                regenBtn.backgroundColor = Theme.rose.withAlphaComponent(0.25)
                regenBtn.layer.cornerRadius = 8
                regenBtn.translatesAutoresizingMaskIntoConstraints = false
                regenBtn.widthAnchor.constraint(equalToConstant: 32).isActive = true
                regenBtn.heightAnchor.constraint(equalToConstant: 28).isActive = true
                regenBtn.addTarget(self, action: #selector(basicRegenTapped), for: .touchUpInside)
                bottomStack.addArrangedSubview(regenBtn)

                let spacer = UIView()
                bottomStack.addArrangedSubview(spacer)

                bottomStack.addArrangedSubview(makeObjectivePill(compact: true))
                bottomStack.addArrangedSubview(makeTonePill(compact: true))

                NSLayoutConstraint.activate([
                    scrollView.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 6),
                    scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
                    scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
                    scrollView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -4),
                    contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
                    contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                    contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                    contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                    contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                    bottomStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    bottomStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                    bottomStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6),
                    bottomStack.heightAnchor.constraint(equalToConstant: 28),
                ])
            } else if isLoadingSuggestions {
                // Loading indicator
                let loadingStack = UIStackView()
                loadingStack.axis = .horizontal
                loadingStack.spacing = 10
                loadingStack.alignment = .center
                loadingStack.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(loadingStack)

                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = Theme.rose
                spinner.startAnimating()
                loadingStack.addArrangedSubview(spinner)

                let loadLabel = UILabel()
                loadLabel.text = "Gerando sugestões..."
                loadLabel.textColor = Theme.textSecondary
                loadLabel.font = UIFont.systemFont(ofSize: 14)
                loadingStack.addArrangedSubview(loadLabel)

                NSLayoutConstraint.activate([
                    loadingStack.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 30),
                    loadingStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                ])
            } else {
                // Pills + Generate button
                let pillsStack = UIStackView()
                pillsStack.axis = .horizontal
                pillsStack.spacing = 8
                pillsStack.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(pillsStack)
                pillsStack.addArrangedSubview(makeObjectivePill())
                pillsStack.addArrangedSubview(makeTonePill())
                pillsStack.addArrangedSubview(UIView())

                let genBtn = makeGradientButton("✨ Sugerir Resposta", fontSize: 15)
                genBtn.addTarget(self, action: #selector(basicGenerateTapped), for: .touchUpInside)
                containerView.addSubview(genBtn)

                NSLayoutConstraint.activate([
                    pillsStack.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 10),
                    pillsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    pillsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                    pillsStack.heightAnchor.constraint(equalToConstant: 28),
                    genBtn.topAnchor.constraint(equalTo: pillsStack.bottomAnchor, constant: 10),
                    genBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    genBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                    genBtn.heightAnchor.constraint(equalToConstant: 40),
                ])
            }
        } else {
            let instructionLabel = makeLabel("📋 Copie uma mensagem primeiro", size: 14)
            instructionLabel.textColor = Theme.textSecondary
            containerView.addSubview(instructionLabel)

            let pillsStack = UIStackView()
            pillsStack.axis = .horizontal
            pillsStack.spacing = 8
            pillsStack.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(pillsStack)
            pillsStack.addArrangedSubview(makeObjectivePill())
            pillsStack.addArrangedSubview(makeTonePill())
            pillsStack.addArrangedSubview(UIView())

            NSLayoutConstraint.activate([
                instructionLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
                instructionLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                pillsStack.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
                pillsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                pillsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                pillsStack.heightAnchor.constraint(equalToConstant: 28),
            ])
        }
    }

    // MARK: - Overlays

    private func showObjectiveOverlay() {
        activeOverlay = .objectiveSelector
        containerView.viewWithTag(7777)?.removeFromSuperview()

        let overlay = UIView()
        overlay.tag = 7777
        overlay.backgroundColor = Theme.overlayBg
        overlay.layer.cornerRadius = 12
        overlay.clipsToBounds = true
        overlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            overlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            overlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            overlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
        ])

        let titleLabel = makeLabel("Escolha um Objetivo", size: 14, bold: true)
        overlay.addSubview(titleLabel)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(Theme.textSecondary, for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(dismissOverlay), for: .touchUpInside)
        overlay.addSubview(closeBtn)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        overlay.addSubview(scrollView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 12),
            closeBtn.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 6),
            closeBtn.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
            closeBtn.widthAnchor.constraint(equalToConstant: 28),
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -4),
        ])

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        for (i, obj) in availableObjectives.enumerated() {
            let card = makeObjectiveCard(obj, index: i, isSelected: i == selectedObjectiveIndex)
            contentStack.addArrangedSubview(card)
        }
    }

    private func showToneOverlay() {
        activeOverlay = .toneSelector
        containerView.viewWithTag(7777)?.removeFromSuperview()

        let overlay = UIView()
        overlay.tag = 7777
        overlay.backgroundColor = Theme.overlayBg
        overlay.layer.cornerRadius = 12
        overlay.clipsToBounds = true
        overlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            overlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            overlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            overlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
        ])

        let titleLabel = makeLabel("Escolha o Tom", size: 14, bold: true)
        overlay.addSubview(titleLabel)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(Theme.textSecondary, for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(dismissOverlay), for: .touchUpInside)
        overlay.addSubview(closeBtn)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(contentStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 12),
            closeBtn.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 6),
            closeBtn.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
            closeBtn.widthAnchor.constraint(equalToConstant: 28),
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            contentStack.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
        ])

        for (i, _) in availableTones.enumerated() {
            let isSelected = i == selectedToneIndex
            let card = UIButton(type: .system)
            card.translatesAutoresizingMaskIntoConstraints = false

            let label = i == 0 ? "\(toneEmojis[i])  \(toneLabels[i]) (Recomendado)" : "\(toneEmojis[i])  \(toneLabels[i])"
            card.setTitle(label, for: .normal)
            card.setTitleColor(.white, for: .normal)
            card.contentHorizontalAlignment = .left
            card.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            card.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: isSelected ? .semibold : .regular)
            card.backgroundColor = isSelected ? Theme.selectedBg : Theme.cardBg
            card.layer.cornerRadius = 8
            card.layer.borderWidth = isSelected ? 1 : 0
            card.layer.borderColor = isSelected ? Theme.rose.cgColor : UIColor.clear.cgColor
            card.tag = 400 + i
            card.addTarget(self, action: #selector(toneFromOverlayTapped(_:)), for: .touchUpInside)
            card.heightAnchor.constraint(equalToConstant: 36).isActive = true
            contentStack.addArrangedSubview(card)
        }
    }

    private func makeObjectiveCard(_ obj: Objective, index: Int, isSelected: Bool) -> UIButton {
        let card = UIButton(type: .system)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = isSelected ? Theme.selectedBg : Theme.cardBg
        card.layer.cornerRadius = 10
        card.layer.borderWidth = isSelected ? 1 : 0
        card.layer.borderColor = isSelected ? Theme.rose.cgColor : UIColor.clear.cgColor
        card.tag = 300 + index
        card.addTarget(self, action: #selector(objectiveFromOverlayTapped(_:)), for: .touchUpInside)

        let emoji = UILabel()
        emoji.text = obj.emoji
        emoji.font = UIFont.systemFont(ofSize: 18)
        emoji.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(emoji)

        let title = UILabel()
        title.text = obj.title
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let desc = UILabel()
        desc.text = obj.description
        desc.textColor = Theme.textSecondary
        desc.font = UIFont.systemFont(ofSize: 10)
        desc.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(desc)

        let check = UILabel()
        check.text = isSelected ? "✓" : ""
        check.textColor = Theme.orange
        check.font = UIFont.boldSystemFont(ofSize: 14)
        check.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(check)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 40),
            emoji.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            emoji.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: emoji.trailingAnchor, constant: 8),
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 5),
            desc.leadingAnchor.constraint(equalTo: emoji.trailingAnchor, constant: 8),
            desc.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -5),
            desc.trailingAnchor.constraint(equalTo: check.leadingAnchor, constant: -8),
            check.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            check.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        return card
    }

    // MARK: - Actions

    @objc private func objectivePillTapped() {
        if activeOverlay == .objectiveSelector { dismissOverlay(); return }
        showObjectiveOverlay()
    }

    @objc private func tonePillTapped() {
        if activeOverlay == .toneSelector { dismissOverlay(); return }
        showToneOverlay()
    }

    @objc private func objectiveFromOverlayTapped(_ sender: UIButton) {
        selectedObjectiveIndex = sender.tag - 300
        dismissOverlay()
        renderCurrentState()
    }

    @objc private func toneFromOverlayTapped(_ sender: UIButton) {
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

    @objc private func dismissOverlay() {
        activeOverlay = .none
        containerView.viewWithTag(7777)?.removeFromSuperview()
    }

    @objc private func profileTapped(_ sender: UIButton) {
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

    @objc private func qwertyKeyTapped(_ sender: UIButton) {
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

    @objc private func qwertyBackspaceTapped() {
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

    @objc private func qwertySpaceTapped() {
        if currentState == .writeOwn {
            writeOwnText += " "
            updateWriteOwnDisplay()
        }
    }

    @objc private func qwertyShiftTapped() {
        isShiftActive = !isShiftActive
        renderCurrentState()
    }

    @objc private func qwertyClearTapped() {
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

    private func updateWriteOwnDisplay() {
        guard let displayLabel = containerView.viewWithTag(998) as? UILabel else { return }
        displayLabel.text = writeOwnText.isEmpty ? "Digite sua resposta..." : writeOwnText
        displayLabel.textColor = writeOwnText.isEmpty ? Theme.textSecondary : .white
    }

    @objc private func quickModeTapped() {
        selectedConversation = nil
        saveSelectedConversation(nil)
        suggestions = []
        isSearchActive = false
        currentState = .basicMode
        renderCurrentState()
    }

    @objc private func backTapped() {
        stopClipboardPolling()
        suggestions = []
        searchText = ""
        isSearchActive = false
        multiMessages = ["", ""]
        selectedConversation = nil
        saveSelectedConversation(nil)
        filteredConversations = conversations
        currentState = authToken != nil ? .profileSelector : .basicMode
        renderCurrentState()
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < suggestions.count else { return }
        let text = suggestions[index]
        UIPasteboard.general.string = text
        textDocumentProxy.insertText(text)

        if let conv = selectedConversation, let convId = conv.conversationId {
            sendMessageToServer(conversationId: convId, content: text, wasAiSuggestion: true)
        }

        suggestions = []
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func basicSuggestionTapped(_ sender: UIButton) {
        let index = sender.tag - 100
        guard index >= 0, index < suggestions.count else { return }
        let text = suggestions[index]
        UIPasteboard.general.string = text
        textDocumentProxy.insertText(text)
    }

    @objc private func writeOwnTapped() {
        writeOwnText = ""
        isShiftActive = true
        currentState = .writeOwn
        renderCurrentState()
    }

    @objc private func backToSuggestionsTapped() {
        currentState = .suggestions
        renderCurrentState()
    }

    @objc private func insertOwnTapped() {
        guard !writeOwnText.isEmpty else { return }
        textDocumentProxy.insertText(writeOwnText)

        if let conv = selectedConversation, let convId = conv.conversationId {
            sendMessageToServer(conversationId: convId, content: writeOwnText, wasAiSuggestion: false)
        }

        writeOwnText = ""
        suggestions = []
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func regenerateTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        isLoadingSuggestions = true
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
    }

    @objc private func basicGenerateTapped() {
        guard let clip = getClipboardText() else { return }
        clipboardText = clip
        suggestions = []
        isLoadingSuggestions = true
        currentState = .basicMode
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: nil, objective: currentObjective())
    }

    @objc private func basicRegenTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        isLoadingSuggestions = true
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: nil, objective: currentObjective())
    }

    // MARK: - Helpers

    private func currentTone() -> String { return availableTones[selectedToneIndex] }
    private func currentObjective() -> String { return availableObjectives[selectedObjectiveIndex].id }

    // MARK: - Network

    // MARK: - Persist Selected Conversation

    private func saveSelectedConversation(_ conv: ConversationContext?) {
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

    private func restoreSavedConversation() -> ConversationContext? {
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

    private func fetchConversations(silent: Bool = false) {
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
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error != nil {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Erro de conexão"
                        self?.renderCurrentState()
                    }
                }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Sem resposta do servidor."
                        self?.renderCurrentState()
                    }
                }
                return
            }

            if http.statusCode == 401 || http.statusCode == 403 {
                if !silent {
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Sessão expirada. Abra o app para renovar."
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

    private func analyzeText(_ text: String, tone: String, conversationId: String?, objective: String?) {
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

    private func sendMessageToServer(conversationId: String, content: String, wasAiSuggestion: Bool) {
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

    private var clipboardTimer: Timer?

    private func startClipboardPolling() {
        stopClipboardPolling()
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func stopClipboardPolling() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }

    private func checkClipboard() {
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

    private func getClipboardText() -> String? {
        guard let text = UIPasteboard.general.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }

    private func parseSuggestions(_ text: String) -> [String] {
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
        let quoteRegex = try? NSRegularExpression(pattern: #""([^"]{5,})""#)
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

    // MARK: - UI Component Helpers

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeHeader(_ text: String, showBack: Bool) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        if showBack {
            let backBtn = UIButton(type: .system)
            backBtn.setTitle("←", for: .normal)
            backBtn.setTitleColor(Theme.textSecondary, for: .normal)
            backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            stack.addArrangedSubview(backBtn)
        }

        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(label)

        stack.addArrangedSubview(UIView())
        return stack
    }

    private func makeObjectivePill(compact: Bool = false) -> UIButton {
        let btn = UIButton(type: .system)
        let obj = availableObjectives[selectedObjectiveIndex]
        let title = compact ? "\(obj.emoji) ▾" : "\(obj.emoji) \(obj.title) ▾"
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.cardBg
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = selectedObjectiveIndex != 0 ? 1 : 0.5
        btn.layer.borderColor = selectedObjectiveIndex != 0 ? Theme.rose.cgColor : Theme.textSecondary.withAlphaComponent(0.3).cgColor
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(objectivePillTapped), for: .touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return btn
    }

    private func makeTonePill(compact: Bool = false) -> UIButton {
        let btn = UIButton(type: .system)
        let title = compact ? "\(toneEmojis[selectedToneIndex]) ▾" : "\(toneEmojis[selectedToneIndex]) \(toneLabels[selectedToneIndex]) ▾"
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.cardBg
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = selectedToneIndex != 0 ? 1 : 0.5
        btn.layer.borderColor = selectedToneIndex != 0 ? Theme.orange.cgColor : Theme.textSecondary.withAlphaComponent(0.3).cgColor
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tonePillTapped), for: .touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return btn
    }

    private func makeProfileButton(_ conv: ConversationContext, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 64).isActive = true

        // Circular photo container with gradient border (like stories)
        let photoSize: CGFloat = 48
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0).cgColor,
            UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.18, blue: 0.74, alpha: 1.0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: photoSize + 4, height: photoSize + 4)
        gradientLayer.cornerRadius = (photoSize + 4) / 2
        borderView.layer.addSublayer(gradientLayer)
        container.addSubview(borderView)

        let photoView = UIView()
        photoView.backgroundColor = Theme.cardBg
        photoView.layer.cornerRadius = photoSize / 2
        photoView.clipsToBounds = true
        photoView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(photoView)

        // Decode and show photo if available
        if let base64 = conv.faceImageBase64,
           let data = Data(base64Encoded: base64),
           let image = UIImage(data: data) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.translatesAutoresizingMaskIntoConstraints = false
            photoView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: photoView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: photoView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: photoView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: photoView.bottomAnchor),
            ])
        } else {
            // Placeholder with initials
            let initialsLabel = UILabel()
            initialsLabel.text = String(conv.matchName.prefix(1)).uppercased()
            initialsLabel.textColor = .white
            initialsLabel.font = UIFont.boldSystemFont(ofSize: 18)
            initialsLabel.textAlignment = .center
            initialsLabel.translatesAutoresizingMaskIntoConstraints = false
            photoView.addSubview(initialsLabel)
            NSLayoutConstraint.activate([
                initialsLabel.centerXAnchor.constraint(equalTo: photoView.centerXAnchor),
                initialsLabel.centerYAnchor.constraint(equalTo: photoView.centerYAnchor),
            ])
        }

        // Name label below
        let nameLabel = UILabel()
        nameLabel.text = conv.matchName.count > 8 ? String(conv.matchName.prefix(7)) + "…" : conv.matchName
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 10)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: container.topAnchor),
            borderView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            borderView.widthAnchor.constraint(equalToConstant: photoSize + 4),
            borderView.heightAnchor.constraint(equalToConstant: photoSize + 4),
            photoView.centerXAnchor.constraint(equalTo: borderView.centerXAnchor),
            photoView.centerYAnchor.constraint(equalTo: borderView.centerYAnchor),
            photoView.widthAnchor.constraint(equalToConstant: photoSize),
            photoView.heightAnchor.constraint(equalToConstant: photoSize),
            nameLabel.topAnchor.constraint(equalTo: borderView.bottomAnchor, constant: 2),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            nameLabel.widthAnchor.constraint(equalTo: container.widthAnchor),
        ])

        // Tap gesture
        let tapBtn = UIButton(type: .system)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        tapBtn.tag = tag
        tapBtn.addTarget(self, action: #selector(profileTapped(_:)), for: .touchUpInside)
        container.addSubview(tapBtn)
        NSLayoutConstraint.activate([
            tapBtn.topAnchor.constraint(equalTo: container.topAnchor),
            tapBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tapBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tapBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func makeQWERTYKeyboard(forSearch: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let rows: [[String]] = [
            ["q","w","e","r","t","y","u","i","o","p"],
            ["a","s","d","f","g","h","j","k","l"],
            ["z","x","c","v","b","n","m"]
        ]
        let keyHeight: CGFloat = forSearch ? 26 : 32
        let rowSpacing: CGFloat = 2
        let keySpacing: CGFloat = 3

        var previousRow: UIView?
        var tagIndex = 0

        for (rowIdx, row) in rows.enumerated() {
            let rowView = UIView()
            rowView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(rowView)

            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                rowView.heightAnchor.constraint(equalToConstant: keyHeight),
            ])

            if let prev = previousRow {
                rowView.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: rowSpacing).isActive = true
            } else {
                rowView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            }

            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = keySpacing
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(rowStack)

            // Indent rows 2 and 3
            let indent: CGFloat = rowIdx == 1 ? 14 : (rowIdx == 2 ? 6 : 0)

            // Row 3: add shift button before letters
            if rowIdx == 2 {
                let shiftBtn = UIButton(type: .system)
                shiftBtn.setTitle(isShiftActive ? "⇧" : "⇪", for: .normal)
                shiftBtn.setTitleColor(isShiftActive ? Theme.orange : .white, for: .normal)
                shiftBtn.backgroundColor = isShiftActive ? Theme.rose.withAlphaComponent(0.2) : Theme.suggestionBg
                shiftBtn.layer.cornerRadius = 5
                shiftBtn.titleLabel?.font = UIFont.systemFont(ofSize: forSearch ? 11 : 13, weight: .medium)
                shiftBtn.translatesAutoresizingMaskIntoConstraints = false
                shiftBtn.addTarget(self, action: #selector(qwertyShiftTapped), for: .touchUpInside)
                rowView.addSubview(shiftBtn)
                NSLayoutConstraint.activate([
                    shiftBtn.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
                    shiftBtn.topAnchor.constraint(equalTo: rowView.topAnchor),
                    shiftBtn.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    shiftBtn.widthAnchor.constraint(equalToConstant: forSearch ? 28 : 36),
                ])
            }

            for char in row {
                let btn = UIButton(type: .system)
                let displayChar = isShiftActive ? char.uppercased() : char
                btn.setTitle(displayChar, for: .normal)
                btn.setTitleColor(.white, for: .normal)
                btn.backgroundColor = Theme.suggestionBg
                btn.layer.cornerRadius = 5
                btn.titleLabel?.font = UIFont.systemFont(ofSize: forSearch ? 12 : 14, weight: .medium)
                btn.tag = 700 + tagIndex
                btn.addTarget(self, action: #selector(qwertyKeyTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
                tagIndex += 1
            }

            // Row 3: add backspace after letters
            if rowIdx == 2 {
                let bkspBtn = UIButton(type: .system)
                if #available(iOSApplicationExtension 13.0, *) {
                    let config = UIImage.SymbolConfiguration(pointSize: forSearch ? 11 : 13, weight: .medium)
                    bkspBtn.setImage(UIImage(systemName: "delete.left", withConfiguration: config), for: .normal)
                } else {
                    bkspBtn.setTitle("⌫", for: .normal)
                }
                bkspBtn.tintColor = Theme.orange
                bkspBtn.backgroundColor = Theme.suggestionBg
                bkspBtn.layer.cornerRadius = 5
                bkspBtn.translatesAutoresizingMaskIntoConstraints = false
                bkspBtn.addTarget(self, action: #selector(qwertyBackspaceTapped), for: .touchUpInside)
                rowView.addSubview(bkspBtn)

                // Clear/close button
                let clearBtn = UIButton(type: .system)
                if forSearch {
                    clearBtn.setTitle("Fechar", for: .normal)
                    clearBtn.setTitleColor(.white, for: .normal)
                    clearBtn.backgroundColor = Theme.rose.withAlphaComponent(0.6)
                } else {
                    clearBtn.setTitle("✕", for: .normal)
                    clearBtn.setTitleColor(Theme.errorText, for: .normal)
                    clearBtn.backgroundColor = Theme.suggestionBg
                }
                clearBtn.layer.cornerRadius = 5
                clearBtn.titleLabel?.font = UIFont.systemFont(ofSize: forSearch ? 10 : 13, weight: forSearch ? .semibold : .regular)
                clearBtn.translatesAutoresizingMaskIntoConstraints = false
                clearBtn.addTarget(self, action: #selector(qwertyClearTapped), for: .touchUpInside)
                rowView.addSubview(clearBtn)

                let shiftWidth: CGFloat = forSearch ? 28 : 36
                let clearWidth: CGFloat = forSearch ? 44 : 30
                NSLayoutConstraint.activate([
                    rowStack.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: shiftWidth + keySpacing),
                    rowStack.topAnchor.constraint(equalTo: rowView.topAnchor),
                    rowStack.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    bkspBtn.leadingAnchor.constraint(equalTo: rowStack.trailingAnchor, constant: keySpacing),
                    bkspBtn.topAnchor.constraint(equalTo: rowView.topAnchor),
                    bkspBtn.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    bkspBtn.widthAnchor.constraint(equalToConstant: forSearch ? 28 : 36),
                    clearBtn.leadingAnchor.constraint(equalTo: bkspBtn.trailingAnchor, constant: keySpacing),
                    clearBtn.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
                    clearBtn.topAnchor.constraint(equalTo: rowView.topAnchor),
                    clearBtn.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    clearBtn.widthAnchor.constraint(equalToConstant: clearWidth),
                ])
            } else {
                NSLayoutConstraint.activate([
                    rowStack.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: indent),
                    rowStack.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -indent),
                    rowStack.topAnchor.constraint(equalTo: rowView.topAnchor),
                    rowStack.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                ])
            }

            previousRow = rowView
        }

        // Row 4: space bar (only for writeOwn) or bottom actions
        if !forSearch {
            let bottomRow = UIView()
            bottomRow.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(bottomRow)

            NSLayoutConstraint.activate([
                bottomRow.topAnchor.constraint(equalTo: previousRow!.bottomAnchor, constant: rowSpacing),
                bottomRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                bottomRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                bottomRow.heightAnchor.constraint(equalToConstant: keyHeight),
                bottomRow.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])

            let backBtn = UIButton(type: .system)
            backBtn.setTitle("← Voltar", for: .normal)
            backBtn.setTitleColor(Theme.textSecondary, for: .normal)
            backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            backBtn.backgroundColor = Theme.cardBg
            backBtn.layer.cornerRadius = 5
            backBtn.translatesAutoresizingMaskIntoConstraints = false
            backBtn.addTarget(self, action: #selector(backToSuggestionsTapped), for: .touchUpInside)
            bottomRow.addSubview(backBtn)

            let spaceBtn = UIButton(type: .system)
            spaceBtn.setTitle("espaço", for: .normal)
            spaceBtn.setTitleColor(Theme.textSecondary, for: .normal)
            spaceBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            spaceBtn.backgroundColor = Theme.suggestionBg
            spaceBtn.layer.cornerRadius = 5
            spaceBtn.translatesAutoresizingMaskIntoConstraints = false
            spaceBtn.addTarget(self, action: #selector(qwertySpaceTapped), for: .touchUpInside)
            bottomRow.addSubview(spaceBtn)

            // Insert button with gradient background
            let insertContainer = UIView()
            insertContainer.translatesAutoresizingMaskIntoConstraints = false
            insertContainer.layer.cornerRadius = 5
            insertContainer.clipsToBounds = true

            let gradientBg = GradientView()
            gradientBg.translatesAutoresizingMaskIntoConstraints = false
            insertContainer.addSubview(gradientBg)

            let insertLabel = UILabel()
            insertLabel.text = "Inserir ↗"
            insertLabel.textColor = .white
            insertLabel.font = UIFont.boldSystemFont(ofSize: 12)
            insertLabel.textAlignment = .center
            insertLabel.translatesAutoresizingMaskIntoConstraints = false
            insertContainer.addSubview(insertLabel)

            let insertTap = UITapGestureRecognizer(target: self, action: #selector(insertOwnTapped))
            insertContainer.addGestureRecognizer(insertTap)
            insertContainer.isUserInteractionEnabled = true

            NSLayoutConstraint.activate([
                gradientBg.topAnchor.constraint(equalTo: insertContainer.topAnchor),
                gradientBg.bottomAnchor.constraint(equalTo: insertContainer.bottomAnchor),
                gradientBg.leadingAnchor.constraint(equalTo: insertContainer.leadingAnchor),
                gradientBg.trailingAnchor.constraint(equalTo: insertContainer.trailingAnchor),
                insertLabel.topAnchor.constraint(equalTo: insertContainer.topAnchor),
                insertLabel.bottomAnchor.constraint(equalTo: insertContainer.bottomAnchor),
                insertLabel.leadingAnchor.constraint(equalTo: insertContainer.leadingAnchor),
                insertLabel.trailingAnchor.constraint(equalTo: insertContainer.trailingAnchor),
            ])
            bottomRow.addSubview(insertContainer)

            NSLayoutConstraint.activate([
                backBtn.leadingAnchor.constraint(equalTo: bottomRow.leadingAnchor),
                backBtn.topAnchor.constraint(equalTo: bottomRow.topAnchor),
                backBtn.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
                backBtn.widthAnchor.constraint(equalToConstant: 70),

                spaceBtn.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: keySpacing),
                spaceBtn.topAnchor.constraint(equalTo: bottomRow.topAnchor),
                spaceBtn.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),

                insertContainer.leadingAnchor.constraint(equalTo: spaceBtn.trailingAnchor, constant: keySpacing),
                insertContainer.trailingAnchor.constraint(equalTo: bottomRow.trailingAnchor),
                insertContainer.topAnchor.constraint(equalTo: bottomRow.topAnchor),
                insertContainer.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
                insertContainer.widthAnchor.constraint(equalToConstant: 90),
            ])
        }

        return container
    }

    private func makeKeyboardSwitchButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("🌐", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        btn.widthAnchor.constraint(equalToConstant: 32).isActive = true
        return btn
    }

    private func makeGradientButton(_ title: String, fontSize: CGFloat) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize)
        btn.layer.cornerRadius = 10
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0).cgColor,
            UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.18, blue: 0.74, alpha: 1.0).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = CGRect(x: 0, y: 0, width: 400, height: 50)
        btn.layer.insertSublayer(gradient, at: 0)

        return btn
    }
}

// MARK: - GradientView (auto-sizing gradient for Auto Layout)
private class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let g = layer as? CAGradientLayer else { return }
        g.colors = [
            UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0).cgColor,
            UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.18, blue: 0.74, alpha: 1.0).cgColor,
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
    }

    required init?(coder: NSCoder) { fatalError() }
}
