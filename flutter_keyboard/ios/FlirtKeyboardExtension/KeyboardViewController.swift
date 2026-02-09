import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - State Machine

    enum KeyboardState {
        case profileSelector   // Estado 1: Seletor de perfis
        case awaitingClipboard // Estado 2: Aguardando clipboard (PRO)
        case suggestions       // Estado 3: Sugestões (PRO)
        case writeOwn          // Estado 3B: Escrever própria (PRO)
        case basicMode         // Estado 4: Modo rápido (BASIC)
    }

    // MARK: - Properties

    private var currentState: KeyboardState = .profileSelector
    private var containerView: UIView!

    // Profiles data
    private struct ConversationContext {
        let conversationId: String
        let matchName: String
        let platform: String
        let lastMessage: String?
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

    // Tone
    private let availableTones = ["engraçado", "ousado", "romântico", "casual", "confiante"]
    private let toneEmojis = ["😄", "🔥", "❤️", "😎", "💪"]
    private var selectedToneIndex: Int = 3 // casual default

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
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        previousClipboard = UIPasteboard.general.string

        // Load default tone
        if let defaultTone = sharedDefaults?.string(forKey: "defaultTone"),
           let index = availableTones.firstIndex(of: defaultTone) {
            selectedToneIndex = index
        }

        // Determine initial state
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
        // Clear previous UI
        view.subviews.forEach { $0.removeFromSuperview() }

        containerView = UIView()
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
        case .profileSelector:
            renderProfileSelector()
        case .awaitingClipboard:
            renderAwaitingClipboard()
        case .suggestions:
            renderSuggestions()
        case .writeOwn:
            renderWriteOwn()
        case .basicMode:
            renderBasicMode()
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

        // Search field
        let searchField = UITextField()
        searchField.placeholder = "🔍 Buscar perfil..."
        searchField.textColor = .white
        searchField.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        searchField.layer.cornerRadius = 8
        searchField.font = UIFont.systemFont(ofSize: 13)
        searchField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        searchField.leftViewMode = .always
        searchField.autocorrectionType = .no
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.tag = 888
        searchField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
        searchField.text = searchText
        containerView.addSubview(searchField)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            searchField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            searchField.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Horizontal scroll for profiles
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        containerView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            scrollView.heightAnchor.constraint(equalToConstant: 60),
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
            let loadingLabel = makeLabel("Carregando perfis...", size: 12)
            loadingLabel.textColor = .lightGray
            stackView.addArrangedSubview(loadingLabel)
        } else if let error = profilesError {
            let errorLabel = makeLabel(error, size: 11)
            errorLabel.textColor = UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
            errorLabel.numberOfLines = 2
            stackView.addArrangedSubview(errorLabel)
        } else if filteredConversations.isEmpty && !searchText.isEmpty {
            let emptyLabel = makeLabel("Nenhum perfil encontrado", size: 12)
            emptyLabel.textColor = .lightGray
            stackView.addArrangedSubview(emptyLabel)
        } else if conversations.isEmpty {
            let emptyLabel = makeLabel("Nenhum perfil criado.\nCrie um perfil no app primeiro.", size: 12)
            emptyLabel.textColor = .lightGray
            emptyLabel.numberOfLines = 2
            stackView.addArrangedSubview(emptyLabel)
        } else {
            for (index, conv) in filteredConversations.enumerated() {
                let button = makeProfileButton(conv, tag: index)
                stackView.addArrangedSubview(button)
            }
        }

        // Quick mode button
        let quickButton = UIButton(type: .system)
        quickButton.setTitle("⚡ Modo Rápido — sem perfil", for: .normal)
        quickButton.setTitleColor(.white, for: .normal)
        quickButton.backgroundColor = UIColor(white: 0.25, alpha: 1.0)
        quickButton.layer.cornerRadius = 8
        quickButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        quickButton.translatesAutoresizingMaskIntoConstraints = false
        quickButton.addTarget(self, action: #selector(quickModeTapped), for: .touchUpInside)
        containerView.addSubview(quickButton)

        // Keyboard switch button
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

        let instructionLabel = makeLabel("📋 Copie a mensagem dela e volte para o teclado", size: 13)
        instructionLabel.textColor = .lightGray
        instructionLabel.numberOfLines = 2
        containerView.addSubview(instructionLabel)

        // Tone selector
        let toneView = makeToneSelector()
        containerView.addSubview(toneView)

        let switchBtn = makeKeyboardSwitchButton()
        containerView.addSubview(switchBtn)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            instructionLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            toneView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            toneView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            toneView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -56),
            toneView.heightAnchor.constraint(equalToConstant: 32),

            switchBtn.centerYAnchor.constraint(equalTo: toneView.centerYAnchor),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
        ])

        // Start polling clipboard
        startClipboardPolling()
    }

    // MARK: - Estado 3: Suggestions (PRO)

    private func renderSuggestions() {
        guard let conv = selectedConversation else { return }

        let headerLabel = makeLabel("👤 \(conv.matchName)  |  Ela disse:", size: 12, bold: true)
        containerView.addSubview(headerLabel)

        let clipLabel = makeLabel("\"\(clipboardText ?? "")\"", size: 11)
        clipLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        clipLabel.numberOfLines = 2
        containerView.addSubview(clipLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            clipLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 2),
            clipLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            clipLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
        ])

        if suggestions.isEmpty {
            let loadingLabel = makeLabel("🔄 Gerando sugestões...", size: 13)
            loadingLabel.textColor = .lightGray
            containerView.addSubview(loadingLabel)
            NSLayoutConstraint.activate([
                loadingLabel.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 12),
                loadingLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            ])
            return
        }

        // Suggestion buttons
        var lastAnchor = clipLabel.bottomAnchor
        for (index, suggestion) in suggestions.prefix(3).enumerated() {
            let btn = UIButton(type: .system)
            let displayText = suggestion.count > 60 ? String(suggestion.prefix(57)) + "..." : suggestion
            btn.setTitle("\(index + 1). \(displayText)", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            btn.layer.cornerRadius = 6
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            btn.titleLabel?.numberOfLines = 1
            btn.tag = index
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            containerView.addSubview(btn)

            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: lastAnchor, constant: 4),
                btn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                btn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                btn.heightAnchor.constraint(equalToConstant: 30),
            ])
            lastAnchor = btn.bottomAnchor
        }

        // Bottom bar: Write own + Regenerate + Tones
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 8
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bottomStack)

        let writeBtn = UIButton(type: .system)
        writeBtn.setTitle("✏️ Escrever", for: .normal)
        writeBtn.setTitleColor(.white, for: .normal)
        writeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 11)
        writeBtn.addTarget(self, action: #selector(writeOwnTapped), for: .touchUpInside)
        bottomStack.addArrangedSubview(writeBtn)

        let regenBtn = UIButton(type: .system)
        regenBtn.setTitle("🔄", for: .normal)
        regenBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        regenBtn.addTarget(self, action: #selector(regenerateTapped), for: .touchUpInside)
        bottomStack.addArrangedSubview(regenBtn)

        for (i, emoji) in toneEmojis.enumerated() {
            let toneBtn = UIButton(type: .system)
            toneBtn.setTitle(emoji, for: .normal)
            toneBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            toneBtn.tag = i
            toneBtn.alpha = i == selectedToneIndex ? 1.0 : 0.5
            toneBtn.addTarget(self, action: #selector(toneTapped(_:)), for: .touchUpInside)
            bottomStack.addArrangedSubview(toneBtn)
        }

        NSLayoutConstraint.activate([
            bottomStack.topAnchor.constraint(equalTo: lastAnchor, constant: 6),
            bottomStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            bottomStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            bottomStack.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    // MARK: - Estado 3B: Write Own (PRO)

    private func renderWriteOwn() {
        guard let conv = selectedConversation else { return }

        let headerLabel = makeLabel("👤 \(conv.matchName)  |  Ela disse:", size: 12, bold: true)
        containerView.addSubview(headerLabel)

        let clipLabel = makeLabel("\"\(clipboardText ?? "")\"", size: 11)
        clipLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        clipLabel.numberOfLines = 1
        containerView.addSubview(clipLabel)

        let textField = UITextField()
        textField.placeholder = "Digite sua resposta..."
        textField.textColor = .white
        textField.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        textField.layer.cornerRadius = 8
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.tag = 999
        containerView.addSubview(textField)

        let backBtn = UIButton(type: .system)
        backBtn.setTitle("← Voltar", for: .normal)
        backBtn.setTitleColor(.lightGray, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.addTarget(self, action: #selector(backToSuggestionsTapped), for: .touchUpInside)
        containerView.addSubview(backBtn)

        let insertBtn = UIButton(type: .system)
        insertBtn.setTitle("Inserir ↗", for: .normal)
        insertBtn.setTitleColor(.white, for: .normal)
        insertBtn.backgroundColor = UIColor.systemBlue
        insertBtn.layer.cornerRadius = 8
        insertBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        insertBtn.translatesAutoresizingMaskIntoConstraints = false
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
            insertBtn.widthAnchor.constraint(equalToConstant: 100),
            insertBtn.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // MARK: - Estado 4: Basic Mode

    private func renderBasicMode() {
        let headerView = makeHeader("⚡ Modo Rápido", showBack: authToken != nil)
        containerView.addSubview(headerView)

        // Read clipboard
        let clip = getClipboardText()

        if let clip = clip {
            let clipLabel = makeLabel("\"\(clip.count > 80 ? String(clip.prefix(77)) + "..." : clip)\"", size: 11)
            clipLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
            clipLabel.numberOfLines = 2
            containerView.addSubview(clipLabel)

            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

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
                    btn.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                    btn.contentHorizontalAlignment = .left
                    btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
                    btn.layer.cornerRadius = 6
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

                // Regen + tones
                let bottomStack = UIStackView()
                bottomStack.axis = .horizontal
                bottomStack.spacing = 8
                bottomStack.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(bottomStack)

                let regenBtn = UIButton(type: .system)
                regenBtn.setTitle("🔄", for: .normal)
                regenBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
                regenBtn.addTarget(self, action: #selector(basicRegenTapped), for: .touchUpInside)
                bottomStack.addArrangedSubview(regenBtn)

                let spacer = UIView()
                bottomStack.addArrangedSubview(spacer)

                for (i, emoji) in toneEmojis.enumerated() {
                    let toneBtn = UIButton(type: .system)
                    toneBtn.setTitle(emoji, for: .normal)
                    toneBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
                    toneBtn.tag = 200 + i
                    toneBtn.alpha = i == selectedToneIndex ? 1.0 : 0.5
                    toneBtn.addTarget(self, action: #selector(basicToneTapped(_:)), for: .touchUpInside)
                    bottomStack.addArrangedSubview(toneBtn)
                }

                NSLayoutConstraint.activate([
                    bottomStack.topAnchor.constraint(equalTo: lastAnchor, constant: 6),
                    bottomStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    bottomStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                ])
            } else {
                // Show generate button
                let genBtn = makeGenerateButton()
                containerView.addSubview(genBtn)

                let toneView = makeToneSelector()
                containerView.addSubview(toneView)

                let switchBtn = makeKeyboardSwitchButton()
                containerView.addSubview(switchBtn)

                NSLayoutConstraint.activate([
                    toneView.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 12),
                    toneView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    toneView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                    toneView.heightAnchor.constraint(equalToConstant: 32),

                    genBtn.topAnchor.constraint(equalTo: toneView.bottomAnchor, constant: 10),
                    genBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    genBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -56),
                    genBtn.heightAnchor.constraint(equalToConstant: 40),

                    switchBtn.centerYAnchor.constraint(equalTo: genBtn.centerYAnchor),
                    switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                ])
            }
        } else {
            let instructionLabel = makeLabel("📋 Copie uma mensagem primeiro", size: 13)
            instructionLabel.textColor = .lightGray
            containerView.addSubview(instructionLabel)

            let toneView = makeToneSelector()
            containerView.addSubview(toneView)

            let switchBtn = makeKeyboardSwitchButton()
            containerView.addSubview(switchBtn)

            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

                instructionLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
                instructionLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

                toneView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
                toneView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                toneView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -56),
                toneView.heightAnchor.constraint(equalToConstant: 32),

                switchBtn.centerYAnchor.constraint(equalTo: toneView.centerYAnchor),
                switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            ])
        }
    }

    // MARK: - Actions

    @objc private func profileTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < filteredConversations.count else { return }
        selectedConversation = filteredConversations[index]
        clipboardText = nil
        suggestions = []
        searchText = ""
        previousClipboard = UIPasteboard.general.string // Reset clipboard tracking
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func searchTextChanged(_ sender: UITextField) {
        searchText = sender.text ?? ""
        if searchText.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter {
                $0.matchName.localizedCaseInsensitiveContains(searchText)
            }
        }
        // Re-render only the profile list without losing search field focus
        // We rebuild the full UI but restore focus after
        let wasFirstResponder = sender.isFirstResponder
        renderCurrentState()
        if wasFirstResponder, let field = containerView.viewWithTag(888) as? UITextField {
            field.becomeFirstResponder()
        }
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
        if authToken != nil {
            currentState = .profileSelector
        } else {
            currentState = .basicMode
        }
        renderCurrentState()
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < suggestions.count else { return }
        let text = suggestions[index]
        textDocumentProxy.insertText(text)

        // PRO: save to history
        if let conv = selectedConversation {
            sendMessageToServer(
                conversationId: conv.conversationId,
                content: text,
                wasAiSuggestion: true
            )
        }

        // Go back to awaiting clipboard for next message
        suggestions = []
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func basicSuggestionTapped(_ sender: UIButton) {
        let index = sender.tag - 100
        guard index < suggestions.count else { return }
        textDocumentProxy.insertText(suggestions[index])
        // BASIC: don't save anything
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

        // PRO: save to history
        if let conv = selectedConversation {
            sendMessageToServer(
                conversationId: conv.conversationId,
                content: text,
                wasAiSuggestion: false
            )
        }

        suggestions = []
        previousClipboard = UIPasteboard.general.string
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc private func regenerateTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        renderCurrentState() // Show loading
        analyzeText(clip, tone: availableTones[selectedToneIndex], conversationId: selectedConversation?.conversationId)
    }

    @objc private func toneTapped(_ sender: UIButton) {
        selectedToneIndex = sender.tag
        regenerateTapped()
    }

    @objc private func basicGenerateTapped() {
        guard let clip = getClipboardText() else { return }
        clipboardText = clip
        suggestions = []
        currentState = .basicMode
        renderCurrentState()
        analyzeText(clip, tone: availableTones[selectedToneIndex], conversationId: nil)
    }

    @objc private func basicRegenTapped() {
        guard let clip = clipboardText else { return }
        suggestions = []
        renderCurrentState()
        analyzeText(clip, tone: availableTones[selectedToneIndex], conversationId: nil)
    }

    @objc private func basicToneTapped(_ sender: UIButton) {
        selectedToneIndex = sender.tag - 200
        basicRegenTapped()
    }

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

            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
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
                    self?.profilesError = "Sem resposta do servidor."
                    self?.renderCurrentState()
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let convArray = json["conversations"] as? [[String: Any]] {
                    let contexts = convArray.compactMap { dict -> ConversationContext? in
                        guard let id = dict["conversationId"] as? String,
                              let name = dict["matchName"] as? String else { return nil }
                        return ConversationContext(
                            conversationId: id,
                            matchName: name,
                            platform: dict["platform"] as? String ?? "tinder",
                            lastMessage: dict["lastMessage"] as? String
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
                    DispatchQueue.main.async {
                        self?.isLoadingProfiles = false
                        self?.profilesError = "Resposta inesperada do servidor."
                        self?.renderCurrentState()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoadingProfiles = false
                    self?.profilesError = "Erro ao processar dados."
                    self?.renderCurrentState()
                }
            }
        }.resume()
    }

    private func analyzeText(_ text: String, tone: String, conversationId: String?) {
        guard let url = URL(string: "\(backendUrl)/analyze") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Add auth header if available (for PRO mode)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = ["text": text, "tone": tone]
        if let convId = conversationId {
            body["conversationId"] = convId
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch { return }

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
                    // Parse numbered suggestions
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
            "tone": availableTones[selectedToneIndex]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch { return }

        // Fire and forget - don't block UI
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

        // Generate suggestions with context
        analyzeText(current, tone: availableTones[selectedToneIndex], conversationId: selectedConversation?.conversationId)
    }

    // MARK: - Helper Methods

    private func getClipboardText() -> String? {
        guard let text = UIPasteboard.general.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return text
    }

    private func parseSuggestions(_ text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var results: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Match patterns like "1.", "1)", "1:", or just numbered text
            if let range = trimmed.range(of: #"^\d+[\.\)\:]\s*"#, options: .regularExpression) {
                let suggestion = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !suggestion.isEmpty {
                    // Remove surrounding quotes if present
                    let cleaned = suggestion.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    results.append(cleaned)
                }
            }
        }

        return results.isEmpty ? [text] : results
    }

    // MARK: - UI Helpers

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
            backBtn.setTitle("← Voltar", for: .normal)
            backBtn.setTitleColor(.lightGray, for: .normal)
            backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            stack.addArrangedSubview(backBtn)
        }

        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(label)

        let spacer = UIView()
        stack.addArrangedSubview(spacer)

        return stack
    }

    private func makeToneSelector() -> UISegmentedControl {
        let control = UISegmentedControl(items: toneEmojis)
        control.selectedSegmentIndex = selectedToneIndex
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(toneSegmentChanged(_:)), for: .valueChanged)
        return control
    }

    @objc private func toneSegmentChanged(_ sender: UISegmentedControl) {
        selectedToneIndex = sender.selectedSegmentIndex
    }

    private func makeProfileButton(_ conv: ConversationContext, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        let title = "\(conv.matchName)\n\(conv.platform)"
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.numberOfLines = 2
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.tag = tag
        btn.addTarget(self, action: #selector(profileTapped(_:)), for: .touchUpInside)
        btn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        return btn
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

    private func makeGenerateButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("✨ Sugerir Resposta", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.systemBlue
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(basicGenerateTapped), for: .touchUpInside)
        return btn
    }
}
