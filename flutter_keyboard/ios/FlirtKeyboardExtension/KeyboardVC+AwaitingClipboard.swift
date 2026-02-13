import UIKit

extension KeyboardViewController {

    // MARK: - Estado 2: Awaiting Clipboard (PRO)

    func renderAwaitingClipboard() {
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

    @objc func pasteBoxTapped() {
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

    @objc func multiMessageModeTapped() {
        stopClipboardPolling()
        multiMessages = ["", ""]
        currentState = .multipleMessages
        saveMultiMessageState()
        renderCurrentState()
    }
}
