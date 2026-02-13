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

    struct Theme {
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

    // MARK: - Tone Data (with Auto)

    let availableTones = ["automatico", "engraçado", "ousado", "romântico", "casual", "confiante"]
    let toneEmojis = ["🤖", "😄", "🔥", "❤️", "😎", "💪"]
    let toneLabels = ["Auto", "Engraçado", "Ousado", "Romântico", "Casual", "Confiante"]

    // MARK: - Properties

    var currentState: KeyboardState = .profileSelector
    var activeOverlay: OverlayType = .none
    var containerView: UIView!

    struct ConversationContext {
        let conversationId: String?
        let profileId: String?
        let matchName: String
        let platform: String
        let lastMessage: String?
        let faceImageBase64: String?
    }

    var conversations: [ConversationContext] = []
    var filteredConversations: [ConversationContext] = []
    var selectedConversation: ConversationContext?
    var clipboardText: String?
    var suggestions: [String] = []
    var previousClipboard: String?
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

    // Shared config
    var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.desenrolaai.app.shared")
    }

    var backendUrl: String {
        return sharedDefaults?.string(forKey: "backendUrl") ?? "https://dating-app-production-ac43.up.railway.app"
    }

    var authToken: String? {
        return sharedDefaults?.string(forKey: "authToken")
    }

    var userId: String? {
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
                // Restore multi-message state if user was in that mode
                if let savedMessages = restoreMultiMessageState() {
                    multiMessages = savedMessages
                    currentState = .multipleMessages
                } else {
                    currentState = .awaitingClipboard
                }
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
}
