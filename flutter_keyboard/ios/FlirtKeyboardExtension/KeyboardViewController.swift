import UIKit

/*
 IMPORTANTE: CONFIGURAÇÃO DO KEYBOARD EXTENSION

 Este arquivo deve estar em um Target separado chamado "FlirtKeyboardExtension"

 Para criar o Keyboard Extension no Xcode:
 1. File > New > Target > Custom Keyboard Extension
 2. Nome: FlirtKeyboardExtension
 3. Substitua o KeyboardViewController.swift gerado por este arquivo

 CONFIGURAÇÕES NECESSÁRIAS:
 - App Groups: Compartilhar dados entre app e keyboard
 - Full Access: Habilitado no Info.plist do Extension
*/

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private var suggestionButton: UIButton!
    private var toneSelector: UISegmentedControl!
    private var statusLabel: UILabel!

    private let availableTones = ["engraçado", "ousado", "romântico", "casual", "confiante"]
    private var selectedTone: String {
        return availableTones[toneSelector.selectedSegmentIndex]
    }

    // Configurações compartilhadas com o app principal via App Groups
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.flirtkeyboard.shared")
    }

    private var backendUrl: String {
        return sharedDefaults?.string(forKey: "backendUrl") ?? "http://localhost:3000"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDefaultTone()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)

        // Criar container
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Status Label
        statusLabel = UILabel()
        statusLabel.text = "Copie uma mensagem primeiro"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)

        // Seletor de Tons
        toneSelector = UISegmentedControl(items: ["😄", "🔥", "❤️", "😎", "💪"])
        toneSelector.selectedSegmentIndex = 3 // Casual por padrão
        toneSelector.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(toneSelector)

        // Botão de Sugestão
        suggestionButton = UIButton(type: .system)
        suggestionButton.setTitle("✨ Sugerir Resposta", for: .normal)
        suggestionButton.backgroundColor = UIColor.systemBlue
        suggestionButton.setTitleColor(.white, for: .normal)
        suggestionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        suggestionButton.layer.cornerRadius = 10
        suggestionButton.translatesAutoresizingMaskIntoConstraints = false
        suggestionButton.addTarget(self, action: #selector(suggestionButtonTapped), for: .touchUpInside)
        containerView.addSubview(suggestionButton)

        // Botão de Trocar Teclado
        let nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        containerView.addSubview(nextKeyboardButton)

        // Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            toneSelector.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            toneSelector.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            toneSelector.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            toneSelector.heightAnchor.constraint(equalToConstant: 32),

            suggestionButton.topAnchor.constraint(equalTo: toneSelector.bottomAnchor, constant: 12),
            suggestionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            suggestionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -56),
            suggestionButton.heightAnchor.constraint(equalToConstant: 44),

            nextKeyboardButton.centerYAnchor.constraint(equalTo: suggestionButton.centerYAnchor),
            nextKeyboardButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 32),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            containerView.heightAnchor.constraint(equalToConstant: 130)
        ])
    }

    // MARK: - Settings

    private func loadDefaultTone() {
        if let defaultTone = sharedDefaults?.string(forKey: "defaultTone"),
           let index = availableTones.firstIndex(of: defaultTone) {
            toneSelector.selectedSegmentIndex = index
        }
    }

    // MARK: - Clipboard

    private func getClipboardText() -> String? {
        guard UIPasteboard.general.hasStrings else {
            updateStatus("Nenhum texto copiado encontrado")
            return nil
        }

        guard let text = UIPasteboard.general.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            updateStatus("Texto vazio no clipboard")
            return nil
        }

        return text
    }

    // MARK: - Network

    private func analyzeText(_ text: String, tone: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(backendUrl)/analyze") else {
            completion(.failure(NSError(domain: "KeyboardError", code: 1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let requestBody: [String: Any] = [
            "text": text,
            "tone": tone
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(domain: "KeyboardError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Erro no servidor"])
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NSError(domain: "KeyboardError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Sem dados"])
                completion(.failure(error))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let analysis = json["analysis"] as? String {
                    completion(.success(analysis))
                } else {
                    let error = NSError(domain: "KeyboardError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    // MARK: - Text Insertion

    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    // MARK: - Actions

    @objc private func suggestionButtonTapped() {
        guard hasFullAccess() else {
            updateStatus("⚠️ Habilite Acesso Total nas Configurações")
            return
        }

        guard let clipboardText = getClipboardText() else {
            return
        }

        setButtonLoading(true)
        updateStatus("Analisando...")

        analyzeText(clipboardText, tone: selectedTone) { [weak self] result in
            DispatchQueue.main.async {
                self?.setButtonLoading(false)

                switch result {
                case .success(let suggestion):
                    self?.insertText(suggestion)
                    self?.updateStatus("Sugestão inserida! ✅")

                case .failure(let error):
                    self?.updateStatus("Erro: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func hasFullAccess() -> Bool {
        return UIPasteboard.general.hasStrings || UIPasteboard.general.string != nil
    }

    private func setButtonLoading(_ isLoading: Bool) {
        suggestionButton.isEnabled = !isLoading
        suggestionButton.setTitle(isLoading ? "🔄 Analisando..." : "✨ Sugerir Resposta", for: .normal)
        suggestionButton.alpha = isLoading ? 0.6 : 1.0
    }

    private func updateStatus(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = message
        }
    }
}
