import UIKit

/*
 IMPORTANTE: HABILITANDO FULL ACCESS NO TECLADO CUSTOMIZADO

 Para que este teclado funcione corretamente, você DEVE habilitar "Full Access" (Acesso Total):

 1. Vá em Ajustes > Geral > Teclado > Teclados
 2. Toque no seu teclado customizado na lista
 3. Ative a opção "Permitir Acesso Total" (Allow Full Access)

 Por que é necessário?
 - UIPasteboard requer Full Access para ler a área de transferência
 - URLSession precisa de Full Access para fazer chamadas de rede
 - Sem Full Access, essas funcionalidades retornarão nil ou falharão silenciosamente

 PRIVACIDADE: Informe aos usuários que você usa Full Access apenas para:
 - Ler texto copiado (para análise)
 - Enviar requisições ao seu servidor
 - Não armazena dados pessoais
*/

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private var analyzeButton: UIButton!
    private var toneSelector: UISegmentedControl!
    private let apiBaseURL = "http://localhost:3000"

    // Tons disponíveis
    private let availableTones = ["engraçado", "ousado", "romântico", "casual", "confiante"]
    private var selectedTone: String {
        return availableTones[toneSelector.selectedSegmentIndex]
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Configurar background
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)

        // Criar seletor de tons
        toneSelector = UISegmentedControl(items: ["😄", "🔥", "❤️", "😎", "💪"])
        toneSelector.selectedSegmentIndex = 0
        toneSelector.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toneSelector)

        // Criar botão de análise
        analyzeButton = UIButton(type: .system)
        analyzeButton.setTitle("✨ Sugerir Resposta", for: .normal)
        analyzeButton.backgroundColor = UIColor.systemBlue
        analyzeButton.setTitleColor(.white, for: .normal)
        analyzeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        analyzeButton.layer.cornerRadius = 10
        analyzeButton.translatesAutoresizingMaskIntoConstraints = false
        analyzeButton.addTarget(self, action: #selector(analyzeButtonTapped), for: .touchUpInside)
        view.addSubview(analyzeButton)

        // Constraints
        NSLayoutConstraint.activate([
            toneSelector.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            toneSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            toneSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            toneSelector.heightAnchor.constraint(equalToConstant: 32),

            analyzeButton.topAnchor.constraint(equalTo: toneSelector.bottomAnchor, constant: 8),
            analyzeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            analyzeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            analyzeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Clipboard Functions

    /// Captura o texto da área de transferência (clipboard)
    /// REQUER: Full Access habilitado nas configurações do teclado
    /// - Returns: String com o texto copiado ou nil se não houver texto/acesso
    private func getClipboardText() -> String? {
        // UIPasteboard.general requer Full Access
        guard UIPasteboard.general.hasStrings else {
            showAlert(message: "Nenhum texto copiado encontrado. Copie uma mensagem primeiro!")
            return nil
        }

        let clipboardText = UIPasteboard.general.string

        // Validar se há texto válido
        guard let text = clipboardText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "Texto da área de transferência está vazio.")
            return nil
        }

        return text
    }

    // MARK: - Network Functions

    /// Faz chamada assíncrona para o backend de análise
    /// REQUER: Full Access habilitado para chamadas de rede
    /// - Parameters:
    ///   - text: Texto a ser analisado
    ///   - tone: Tom da resposta (engraçado, ousado, etc)
    ///   - completion: Callback com o resultado ou erro
    private func analyzeText(_ text: String, tone: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Configurar URL
        guard let url = URL(string: "\(apiBaseURL)/analyze") else {
            completion(.failure(NSError(domain: "KeyboardError", code: 1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        // Preparar request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Criar body JSON
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

        // Fazer chamada assíncrona (REQUER Full Access)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Verificar erro de rede
            if let error = error {
                completion(.failure(error))
                return
            }

            // Verificar resposta HTTP
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(domain: "KeyboardError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Erro no servidor"])
                completion(.failure(error))
                return
            }

            // Verificar dados
            guard let data = data else {
                let error = NSError(domain: "KeyboardError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Sem dados na resposta"])
                completion(.failure(error))
                return
            }

            // Parse JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let analysis = json["analysis"] as? String {
                    completion(.success(analysis))
                } else {
                    let error = NSError(domain: "KeyboardError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Formato de resposta inválido"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    // MARK: - Text Insertion Functions

    /// Insere texto no campo de entrada usando textDocumentProxy
    /// Esta é a maneira oficial de inserir texto em um teclado customizado
    /// - Parameter text: Texto a ser inserido
    private func insertTextIntoField(_ text: String) {
        // textDocumentProxy é a interface do iOS para manipular o campo de texto ativo
        // Funciona em qualquer app que aceite entrada de teclado
        textDocumentProxy.insertText(text)
    }

    /// Deleta todo o texto antes do cursor
    private func deleteAllText() {
        // Deletar caractere por caractere até o início
        while textDocumentProxy.documentContextBeforeInput?.isEmpty == false {
            textDocumentProxy.deleteBackward()
        }
    }

    // MARK: - Button Actions

    @objc private func analyzeButtonTapped() {
        // Verificar Full Access
        guard hasFullAccess() else {
            showAlert(message: "⚠️ Habilite 'Acesso Total' nas configurações do teclado para usar esta funcionalidade.")
            return
        }

        // Capturar texto da área de transferência
        guard let clipboardText = getClipboardText() else {
            return
        }

        // Mostrar feedback visual
        analyzeButton.isEnabled = false
        analyzeButton.setTitle("🔄 Analisando...", for: .normal)

        // Fazer análise
        analyzeText(clipboardText, tone: selectedTone) { [weak self] result in
            DispatchQueue.main.async {
                // Restaurar botão
                self?.analyzeButton.isEnabled = true
                self?.analyzeButton.setTitle("✨ Sugerir Resposta", for: .normal)

                switch result {
                case .success(let suggestion):
                    // Inserir sugestão no campo de texto
                    self?.insertTextIntoField(suggestion)

                case .failure(let error):
                    self?.showAlert(message: "Erro: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Helper Functions

    /// Verifica se o teclado tem Full Access habilitado
    /// - Returns: true se Full Access estiver ativo
    private func hasFullAccess() -> Bool {
        // Tenta acessar UIPasteboard - se funcionar, Full Access está ativo
        return UIPasteboard.general.hasStrings || UIPasteboard.general.string != nil
    }

    /// Mostra um alerta visual (limitado em teclados customizados)
    /// Nota: Alertas nativos não funcionam em extensions de teclado
    /// Esta é uma implementação alternativa usando o botão
    private func showAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.analyzeButton.setTitle(message, for: .normal)
            self?.analyzeButton.isEnabled = false

            // Restaurar após 3 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self?.analyzeButton.setTitle("✨ Sugerir Resposta", for: .normal)
                self?.analyzeButton.isEnabled = true
            }
        }
    }
}

// MARK: - INSTRUÇÕES DE INTEGRAÇÃO

/*
 COMO ADICIONAR ESTE TECLADO AO SEU APP:

 1. No Xcode, adicione um novo Target:
    File > New > Target > Custom Keyboard Extension

 2. Substitua o KeyboardViewController.swift gerado por este arquivo

 3. Configure Info.plist do Keyboard Extension:
    - NSExtension > NSExtensionAttributes > RequestsOpenAccess = YES

 4. Configure permissões de rede (se necessário):
    - App Transport Security Settings
    - Allow Arbitrary Loads = YES (para localhost)

 5. Build e instale no dispositivo/simulador

 6. Nas Configurações do iOS:
    - Ajustes > Geral > Teclado > Teclados > Adicionar Novo Teclado
    - Selecione seu teclado customizado
    - IMPORTANTE: Ative "Permitir Acesso Total"

 7. Para testar:
    - Copie uma mensagem qualquer
    - Abra qualquer app com campo de texto (Messages, Notes, etc)
    - Toque no campo de texto
    - Mude para seu teclado customizado (ícone do globo)
    - Selecione o tom desejado
    - Toque em "Sugerir Resposta"

 TROUBLESHOOTING:
 - Se não conseguir acessar clipboard: Verifique Full Access
 - Se chamadas de rede falharem: Verifique Full Access E que o backend está rodando
 - Se localhost não funcionar no dispositivo físico: Use o IP da sua máquina na rede local
*/
