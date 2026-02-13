import UIKit

extension KeyboardViewController {

    // MARK: - Estado 2.5: Multiple Messages

    func renderMultipleMessages() {
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
        backBtn.addTarget(self, action: #selector(backFromMultiMessagesTapped), for: .touchUpInside)
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

    func makeMultiMessageCard(index: Int, text: String) -> UIView {
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

    @objc func backFromMultiMessagesTapped() {
        multiMessages = ["", ""]
        clearMultiMessageState()
        currentState = .awaitingClipboard
        renderCurrentState()
    }

    @objc func multiMessagePasteTapped(_ sender: UIButton) {
        let index = sender.tag - 500
        guard index >= 0 && index < multiMessages.count else { return }
        if let text = UIPasteboard.general.string, !text.isEmpty {
            multiMessages[index] = text
            previousClipboard = text
            saveMultiMessageState()
            renderCurrentState()
        }
    }

    @objc func multiMessageClearTapped(_ sender: UIButton) {
        let index = sender.tag - 600
        guard index >= 0 && index < multiMessages.count else { return }
        multiMessages[index] = ""
        saveMultiMessageState()
        renderCurrentState()
    }

    @objc func addMultiMessageTapped() {
        multiMessages.append("")
        saveMultiMessageState()
        renderCurrentState()
    }

    @objc func multiMessageGenerateTapped() {
        let filledMessages = multiMessages.filter { !$0.isEmpty }
        guard !filledMessages.isEmpty else { return }

        let combinedText = filledMessages.enumerated().map { (i, msg) in
            "Mensagem \(i + 1): \(msg)"
        }.joined(separator: "\n")

        clipboardText = combinedText
        previousClipboard = UIPasteboard.general.string
        stopClipboardPolling()
        clearMultiMessageState()
        suggestions = []
        isLoadingSuggestions = true
        currentState = .suggestions
        renderCurrentState()
        analyzeText(combinedText, tone: currentTone(),
                    conversationId: selectedConversation?.conversationId,
                    objective: currentObjective())
    }
}
