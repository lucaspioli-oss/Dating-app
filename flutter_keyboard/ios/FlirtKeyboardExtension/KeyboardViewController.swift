import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - State Machine

    enum KeyboardState {
        case profileSelector
        case awaitingClipboard
        case suggestions
        case writeOwn
        case basicMode
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
            currentState = .profileSelector
            fetchConversations()
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
            containerView.heightAnchor.constraint(equalToConstant: 220)
        ])

        switch currentState {
        case .profileSelector: renderProfileSelector()
        case .awaitingClipboard: renderAwaitingClipboard()
        case .suggestions: renderSuggestions()
        case .writeOwn: renderWriteOwn()
        case .basicMode: renderBasicMode()
        }
    }

    // MARK: - Estado 1: Profile Selector

    private func renderProfileSelector() {
        let titleLabel = makeLabel("Com quem você está falando?", size: 14, bold: true)
        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
        ])

        // Search label (shows current filter text)
        let searchLabel = UILabel()
        searchLabel.text = searchText.isEmpty ? "🔍 Buscar..." : "🔍 \(searchText)"
        searchLabel.textColor = searchText.isEmpty ? Theme.textSecondary : .white
        searchLabel.backgroundColor = Theme.cardBg
        searchLabel.font = UIFont.systemFont(ofSize: 13)
        searchLabel.layer.cornerRadius = 8
        searchLabel.clipsToBounds = true
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(searchLabel)

        // Add padding to label
        let searchContainer = UIView()
        searchContainer.backgroundColor = Theme.cardBg
        searchContainer.layer.cornerRadius = 8
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(searchContainer)
        searchContainer.addSubview(searchLabel)

        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            searchContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            searchContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            searchContainer.heightAnchor.constraint(equalToConstant: 26),
            searchLabel.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
            searchLabel.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -8),
            searchLabel.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
        ])

        // Mini keyboard: scrollable A-Z row + backspace
        let keyboardScroll = UIScrollView()
        keyboardScroll.translatesAutoresizingMaskIntoConstraints = false
        keyboardScroll.showsHorizontalScrollIndicator = false
        containerView.addSubview(keyboardScroll)

        let keyStack = UIStackView()
        keyStack.axis = .horizontal
        keyStack.spacing = 3
        keyStack.translatesAutoresizingMaskIntoConstraints = false
        keyboardScroll.addSubview(keyStack)

        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for (i, char) in letters.enumerated() {
            let keyBtn = UIButton(type: .system)
            keyBtn.setTitle(String(char), for: .normal)
            keyBtn.setTitleColor(.white, for: .normal)
            keyBtn.backgroundColor = Theme.suggestionBg
            keyBtn.layer.cornerRadius = 4
            keyBtn.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            keyBtn.translatesAutoresizingMaskIntoConstraints = false
            keyBtn.tag = 600 + i
            keyBtn.addTarget(self, action: #selector(miniKeyTapped(_:)), for: .touchUpInside)
            keyBtn.widthAnchor.constraint(equalToConstant: 24).isActive = true
            keyBtn.heightAnchor.constraint(equalToConstant: 24).isActive = true
            keyStack.addArrangedSubview(keyBtn)
        }

        // Backspace button
        let bksp = UIButton(type: .system)
        bksp.setTitle("⌫", for: .normal)
        bksp.setTitleColor(Theme.orange, for: .normal)
        bksp.backgroundColor = Theme.suggestionBg
        bksp.layer.cornerRadius = 4
        bksp.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        bksp.translatesAutoresizingMaskIntoConstraints = false
        bksp.tag = 650
        bksp.addTarget(self, action: #selector(miniKeyBackspace), for: .touchUpInside)
        bksp.widthAnchor.constraint(equalToConstant: 32).isActive = true
        bksp.heightAnchor.constraint(equalToConstant: 24).isActive = true
        keyStack.addArrangedSubview(bksp)

        // Clear button
        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("✕", for: .normal)
        clearBtn.setTitleColor(Theme.errorText, for: .normal)
        clearBtn.backgroundColor = Theme.suggestionBg
        clearBtn.layer.cornerRadius = 4
        clearBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false
        clearBtn.tag = 651
        clearBtn.addTarget(self, action: #selector(miniKeyClear), for: .touchUpInside)
        clearBtn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        clearBtn.heightAnchor.constraint(equalToConstant: 24).isActive = true
        keyStack.addArrangedSubview(clearBtn)

        NSLayoutConstraint.activate([
            keyboardScroll.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 3),
            keyboardScroll.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            keyboardScroll.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            keyboardScroll.heightAnchor.constraint(equalToConstant: 26),
            keyStack.topAnchor.constraint(equalTo: keyboardScroll.topAnchor),
            keyStack.leadingAnchor.constraint(equalTo: keyboardScroll.leadingAnchor),
            keyStack.trailingAnchor.constraint(equalTo: keyboardScroll.trailingAnchor),
            keyStack.bottomAnchor.constraint(equalTo: keyboardScroll.bottomAnchor),
            keyStack.heightAnchor.constraint(equalTo: keyboardScroll.heightAnchor),
        ])

        // Profile list
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        containerView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: keyboardScroll.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            scrollView.heightAnchor.constraint(equalToConstant: 56),
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
        } else if filteredConversations.isEmpty && !searchText.isEmpty {
            let l = makeLabel("Nenhum perfil encontrado", size: 12)
            l.textColor = Theme.textSecondary
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
            quickButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            quickButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            quickButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -56),
            quickButton.heightAnchor.constraint(equalToConstant: 34),
            switchBtn.centerYAnchor.constraint(equalTo: quickButton.centerYAnchor),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            switchBtn.widthAnchor.constraint(equalToConstant: 32),
        ])
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
            hintLabel.topAnchor.constraint(equalTo: pasteBox.bottomAnchor, constant: 8),
            hintLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])

        startClipboardPolling()
    }

    @objc private func pasteBoxTapped() {
        if let text = UIPasteboard.general.string, !text.isEmpty, text != previousClipboard {
            clipboardText = text
            previousClipboard = text
            stopClipboardPolling()
            suggestions = []
            currentState = .suggestions
            renderCurrentState()
            analyzeText(text, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
        }
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
            let loadingLabel = makeLabel("Gerando sugestoes...", size: 13)
            loadingLabel.textColor = Theme.textSecondary
            containerView.addSubview(loadingLabel)
            NSLayoutConstraint.activate([
                loadingLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 30),
                loadingLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
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

        // Bottom bar
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 6
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bottomStack)

        let writeBtn = UIButton(type: .system)
        writeBtn.setTitle("✏️", for: .normal)
        writeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        writeBtn.addTarget(self, action: #selector(writeOwnTapped), for: .touchUpInside)
        bottomStack.addArrangedSubview(writeBtn)

        let regenBtn = UIButton(type: .system)
        regenBtn.setTitle("🔄", for: .normal)
        regenBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        regenBtn.addTarget(self, action: #selector(regenerateTapped), for: .touchUpInside)
        bottomStack.addArrangedSubview(regenBtn)

        let spacer = UIView()
        bottomStack.addArrangedSubview(spacer)

        let objPill = makeObjectivePill(compact: true)
        let tonePill = makeTonePill(compact: true)
        bottomStack.addArrangedSubview(objPill)
        bottomStack.addArrangedSubview(tonePill)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
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
    }

    private func makeSuggestionCard(index: Int, text: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = Theme.suggestionBg
        card.layer.cornerRadius = 10
        card.layer.borderWidth = 0.5
        card.layer.borderColor = Theme.rose.withAlphaComponent(0.15).cgColor

        let numberLabel = UILabel()
        numberLabel.text = "\(index + 1)"
        numberLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = Theme.rose.withAlphaComponent(0.6)
        numberLabel.layer.cornerRadius = 9
        numberLabel.layer.masksToBounds = true
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(numberLabel)

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 13)
        textLabel.textColor = .white
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textLabel)

        let copyBtn = UIButton(type: .system)
        copyBtn.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyBtn.tintColor = Theme.rose.withAlphaComponent(0.7)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        copyBtn.tag = index
        copyBtn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        card.addSubview(copyBtn)

        // Make entire card tappable
        let tapBtn = UIButton(type: .system)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        tapBtn.tag = index
        tapBtn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        card.insertSubview(tapBtn, at: 0)

        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            numberLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            numberLabel.widthAnchor.constraint(equalToConstant: 18),
            numberLabel.heightAnchor.constraint(equalToConstant: 18),
            textLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 7),
            textLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: copyBtn.leadingAnchor, constant: -6),
            textLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -7),
            copyBtn.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            copyBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6),
            copyBtn.widthAnchor.constraint(equalToConstant: 28),
            copyBtn.heightAnchor.constraint(equalToConstant: 28),
            tapBtn.topAnchor.constraint(equalTo: card.topAnchor),
            tapBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tapBtn.trailingAnchor.constraint(equalTo: copyBtn.leadingAnchor),
            tapBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        return card
    }

    // MARK: - Estado 3B: Write Own (PRO)

    private func renderWriteOwn() {
        guard let conv = selectedConversation else { return }

        let headerLabel = makeLabel("👤 \(conv.matchName)  |  Ela disse:", size: 12, bold: true)
        containerView.addSubview(headerLabel)

        let clipLabel = makeLabel("\"\(clipboardText ?? "")\"", size: 11)
        clipLabel.textColor = Theme.clipText
        clipLabel.numberOfLines = 1
        containerView.addSubview(clipLabel)

        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "Digite sua resposta...",
            attributes: [.foregroundColor: Theme.textSecondary]
        )
        textField.textColor = .white
        textField.backgroundColor = Theme.cardBg
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = Theme.rose.withAlphaComponent(0.3).cgColor
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.tag = 999
        containerView.addSubview(textField)

        let backBtn = UIButton(type: .system)
        backBtn.setTitle("← Voltar", for: .normal)
        backBtn.setTitleColor(Theme.textSecondary, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.addTarget(self, action: #selector(backToSuggestionsTapped), for: .touchUpInside)
        containerView.addSubview(backBtn)

        let insertBtn = makeGradientButton("Inserir ↗", fontSize: 14)
        insertBtn.addTarget(self, action: #selector(insertOwnTapped), for: .touchUpInside)
        containerView.addSubview(insertBtn)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            clipLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 2),
            clipLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            clipLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 10),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textField.heightAnchor.constraint(equalToConstant: 40),
            backBtn.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            backBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            insertBtn.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            insertBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            insertBtn.widthAnchor.constraint(equalToConstant: 110),
            insertBtn.heightAnchor.constraint(equalToConstant: 36),
        ])
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
                var lastAnchor = clipLabel.bottomAnchor
                for (index, suggestion) in suggestions.prefix(3).enumerated() {
                    let btn = UIButton(type: .system)
                    let displayText = suggestion.count > 60 ? String(suggestion.prefix(57)) + "..." : suggestion
                    btn.setTitle("\(index + 1). \(displayText)", for: .normal)
                    btn.setTitleColor(.white, for: .normal)
                    btn.backgroundColor = Theme.suggestionBg
                    btn.contentHorizontalAlignment = .left
                    btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
                    btn.layer.cornerRadius = 8
                    btn.layer.borderWidth = 0.5
                    btn.layer.borderColor = Theme.rose.withAlphaComponent(0.2).cgColor
                    btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    btn.titleLabel?.numberOfLines = 1
                    btn.tag = 100 + index
                    btn.translatesAutoresizingMaskIntoConstraints = false
                    btn.addTarget(self, action: #selector(basicSuggestionTapped(_:)), for: .touchUpInside)
                    containerView.addSubview(btn)

                    NSLayoutConstraint.activate([
                        btn.topAnchor.constraint(equalTo: lastAnchor, constant: 4),
                        btn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                        btn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                        btn.heightAnchor.constraint(equalToConstant: 30),
                    ])
                    lastAnchor = btn.bottomAnchor
                }

                let bottomStack = UIStackView()
                bottomStack.axis = .horizontal
                bottomStack.spacing = 6
                bottomStack.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(bottomStack)

                let regenBtn = UIButton(type: .system)
                regenBtn.setTitle("🔄", for: .normal)
                regenBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
                regenBtn.addTarget(self, action: #selector(basicRegenTapped), for: .touchUpInside)
                bottomStack.addArrangedSubview(regenBtn)

                let spacer = UIView()
                bottomStack.addArrangedSubview(spacer)

                bottomStack.addArrangedSubview(makeObjectivePill(compact: true))
                bottomStack.addArrangedSubview(makeTonePill(compact: true))

                NSLayoutConstraint.activate([
                    bottomStack.topAnchor.constraint(equalTo: lastAnchor, constant: 6),
                    bottomStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    bottomStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
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
        clipboardText = nil
        suggestions = []
        searchText = ""
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func miniKeyTapped(_ sender: UIButton) {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let index = sender.tag - 600
        guard index >= 0, index < letters.count else { return }
        let char = String(letters[letters.index(letters.startIndex, offsetBy: index)])
        searchText += char.lowercased()
        filteredConversations = conversations.filter {
            $0.matchName.localizedCaseInsensitiveContains(searchText)
        }
        renderCurrentState()
    }

    @objc private func miniKeyBackspace() {
        guard !searchText.isEmpty else { return }
        searchText = String(searchText.dropLast())
        filteredConversations = searchText.isEmpty ? conversations : conversations.filter {
            $0.matchName.localizedCaseInsensitiveContains(searchText)
        }
        renderCurrentState()
    }

    @objc private func miniKeyClear() {
        searchText = ""
        filteredConversations = conversations
        renderCurrentState()
    }

    @objc private func quickModeTapped() {
        selectedConversation = nil
        suggestions = []
        currentState = .basicMode
        renderCurrentState()
    }

    @objc private func backTapped() {
        stopClipboardPolling()
        suggestions = []
        searchText = ""
        filteredConversations = conversations
        currentState = authToken != nil ? .profileSelector : .basicMode
        renderCurrentState()
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < suggestions.count else { return }
        let text = suggestions[index]
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
        guard index < suggestions.count else { return }
        textDocumentProxy.insertText(suggestions[index])
    }

    @objc private func writeOwnTapped() {
        currentState = .writeOwn
        renderCurrentState()
    }

    @objc private func backToSuggestionsTapped() {
        currentState = .suggestions
        renderCurrentState()
    }

    @objc private func insertOwnTapped() {
        guard let textField = containerView.viewWithTag(999) as? UITextField,
              let text = textField.text, !text.isEmpty else { return }
        textDocumentProxy.insertText(text)

        if let conv = selectedConversation, let convId = conv.conversationId {
            sendMessageToServer(conversationId: convId, content: text, wasAiSuggestion: false)
        }

        suggestions = []
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func regenerateTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
    }

    @objc private func basicGenerateTapped() {
        guard let clip = getClipboardText() else { return }
        clipboardText = clip
        suggestions = []
        currentState = .basicMode
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: nil, objective: currentObjective())
    }

    @objc private func basicRegenTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        renderCurrentState()
        analyzeText(clip, tone: currentTone(), conversationId: nil, objective: currentObjective())
    }

    // MARK: - Helpers

    private func currentTone() -> String { return availableTones[selectedToneIndex] }
    private func currentObjective() -> String { return availableObjectives[selectedObjectiveIndex].id }

    // MARK: - Network

    private func fetchConversations() {
        guard let token = authToken,
              let url = URL(string: "\(backendUrl)/keyboard/context") else {
            isLoadingProfiles = false
            profilesError = "Token não encontrado. Abra o app para fazer login."
            renderCurrentState()
            return
        }

        isLoadingProfiles = true
        profilesError = nil
        renderCurrentState()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoadingProfiles = false
                    self?.profilesError = "Erro de conexão: \(error.localizedDescription)"
                    self?.renderCurrentState()
                }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self?.isLoadingProfiles = false
                    self?.profilesError = "Sem resposta do servidor."
                    self?.renderCurrentState()
                }
                return
            }

            if http.statusCode == 401 || http.statusCode == 403 {
                DispatchQueue.main.async {
                    self?.isLoadingProfiles = false
                    self?.profilesError = "Sessão expirada. Abra o app para renovar."
                    self?.renderCurrentState()
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self?.isLoadingProfiles = false
                    self?.profilesError = "Sem dados (HTTP \(http.statusCode))."
                    self?.renderCurrentState()
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
                DispatchQueue.main.async {
                    self?.isLoadingProfiles = false
                    self?.profilesError = errorMsg
                    self?.renderCurrentState()
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
                        self?.renderCurrentState()
                    }
                } else {
                    // Show raw response for debugging
                    let raw = String(data: data, encoding: .utf8) ?? "?"
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Formato inesperado: \(raw.prefix(80))"
                        self?.renderCurrentState()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoadingProfiles = false
                    self?.profilesError = "Erro ao processar: \(error.localizedDescription)"
                    self?.renderCurrentState()
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
                        self?.suggestions = parsed
                        self?.renderCurrentState()
                    }
                }
            } catch {
                DispatchQueue.main.async {
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
        var results: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let range = trimmed.range(of: #"^\d+[\.\)\:]\s*"#, options: .regularExpression) {
                let suggestion = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !suggestion.isEmpty {
                    results.append(suggestion.trimmingCharacters(in: CharacterSet(charactersIn: "\"'")))
                }
            }
        }

        return results.isEmpty ? [text] : results
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
