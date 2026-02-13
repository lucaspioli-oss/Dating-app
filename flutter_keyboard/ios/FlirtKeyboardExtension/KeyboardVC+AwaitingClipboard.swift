import UIKit

extension KeyboardViewController {

    // MARK: - Hub: Awaiting Clipboard

    func renderAwaitingClipboard() {
        guard let conv = selectedConversation else { return }

        // ── Header row (28px): ← | 👤 MatchName (platform) | 🌐 ──
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerStack)

        let backBtn = UIButton(type: .system)
        backBtn.setTitle("← Voltar", for: .normal)
        backBtn.setTitleColor(Theme.textSecondary, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        backBtn.addTarget(self, action: #selector(backFromAwaitingTapped), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.setContentHuggingPriority(.required, for: .horizontal)
        headerStack.addArrangedSubview(backBtn)

        let profileLabel = UILabel()
        profileLabel.text = "👤 \(conv.matchName) (\(conv.platform))"
        profileLabel.textColor = .white
        profileLabel.font = UIFont.boldSystemFont(ofSize: 12)
        profileLabel.lineBreakMode = .byTruncatingTail
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        profileLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        profileLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(profileLabel)

        let headerSpacer = UIView()
        headerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(headerSpacer)

        let switchBtn = makeKeyboardSwitchButton()
        headerStack.addArrangedSubview(switchBtn)

        // ── Pills row (28px): 🎯 Objetivo ▾  |  🤖 Tom ▾ ──
        let pillsStack = UIStackView()
        pillsStack.axis = .horizontal
        pillsStack.spacing = 8
        pillsStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(pillsStack)

        let objPill = makeObjectivePill(compact: false)
        let tonePill = makeTonePill(compact: false)
        pillsStack.addArrangedSubview(objPill)
        pillsStack.addArrangedSubview(tonePill)
        let pillSpacer = UIView()
        pillsStack.addArrangedSubview(pillSpacer)

        // ── Paste box (48px) ──
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

        // ── Hint ──
        let hintLabel = makeLabel("Copie a mensagem no app de conversa e toque aqui", size: 11)
        hintLabel.textColor = Theme.textSecondary
        hintLabel.textAlignment = .center
        containerView.addSubview(hintLabel)

        // ── Secondary links: 📸 Screenshot · 📋 Várias ──
        let linksStack = UIStackView()
        linksStack.axis = .horizontal
        linksStack.spacing = 4
        linksStack.alignment = .center
        linksStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(linksStack)

        let linksSpacer1 = UIView()
        linksSpacer1.setContentHuggingPriority(.defaultLow, for: .horizontal)
        linksStack.addArrangedSubview(linksSpacer1)

        let screenshotBtn = UIButton(type: .system)
        screenshotBtn.setTitle("📸 Screenshot", for: .normal)
        screenshotBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        screenshotBtn.setTitleColor(Theme.rose.withAlphaComponent(0.8), for: .normal)
        screenshotBtn.addTarget(self, action: #selector(hubScreenshotTapped), for: .touchUpInside)
        screenshotBtn.translatesAutoresizingMaskIntoConstraints = false
        linksStack.addArrangedSubview(screenshotBtn)

        let dotLabel = UILabel()
        dotLabel.text = "·"
        dotLabel.textColor = Theme.textSecondary
        dotLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        dotLabel.translatesAutoresizingMaskIntoConstraints = false
        linksStack.addArrangedSubview(dotLabel)

        let multiBtn = UIButton(type: .system)
        multiBtn.setTitle("📋 Várias msgs", for: .normal)
        multiBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        multiBtn.setTitleColor(Theme.rose.withAlphaComponent(0.8), for: .normal)
        multiBtn.addTarget(self, action: #selector(hubMultipleTapped), for: .touchUpInside)
        multiBtn.translatesAutoresizingMaskIntoConstraints = false
        linksStack.addArrangedSubview(multiBtn)

        let linksSpacer2 = UIView()
        linksSpacer2.setContentHuggingPriority(.defaultLow, for: .horizontal)
        linksStack.addArrangedSubview(linksSpacer2)

        // ── Divider "ou" ──
        let dividerStack = UIStackView()
        dividerStack.axis = .horizontal
        dividerStack.spacing = 8
        dividerStack.alignment = .center
        dividerStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dividerStack)

        let line1 = UIView()
        line1.backgroundColor = Theme.textSecondary.withAlphaComponent(0.3)
        line1.translatesAutoresizingMaskIntoConstraints = false
        line1.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let ouLabel = UILabel()
        ouLabel.text = "ou"
        ouLabel.textColor = Theme.textSecondary
        ouLabel.font = UIFont.systemFont(ofSize: 11)
        ouLabel.translatesAutoresizingMaskIntoConstraints = false
        ouLabel.setContentHuggingPriority(.required, for: .horizontal)

        let line2 = UIView()
        line2.backgroundColor = Theme.textSecondary.withAlphaComponent(0.3)
        line2.translatesAutoresizingMaskIntoConstraints = false
        line2.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        dividerStack.addArrangedSubview(line1)
        dividerStack.addArrangedSubview(ouLabel)
        dividerStack.addArrangedSubview(line2)

        // ── Start Conversation gradient button (44px) ──
        let startContainer = UIView()
        startContainer.translatesAutoresizingMaskIntoConstraints = false
        startContainer.layer.cornerRadius = 12
        startContainer.clipsToBounds = true
        startContainer.isUserInteractionEnabled = true
        containerView.addSubview(startContainer)

        let gradientBg = GradientView()
        gradientBg.translatesAutoresizingMaskIntoConstraints = false
        startContainer.addSubview(gradientBg)

        let startLabel = UILabel()
        startLabel.text = "🚀 Gerar Abertura Criativa"
        startLabel.textColor = .white
        startLabel.font = UIFont.boldSystemFont(ofSize: 14)
        startLabel.textAlignment = .center
        startLabel.translatesAutoresizingMaskIntoConstraints = false
        startContainer.addSubview(startLabel)

        let startTap = UITapGestureRecognizer(target: self, action: #selector(startConversationTapped))
        startContainer.addGestureRecognizer(startTap)

        // ── Layout ──
        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            headerStack.heightAnchor.constraint(equalToConstant: 28),

            // Pills
            pillsStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 6),
            pillsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            pillsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            pillsStack.heightAnchor.constraint(equalToConstant: 28),

            // Paste box
            pasteBox.topAnchor.constraint(equalTo: pillsStack.bottomAnchor, constant: 10),
            pasteBox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            pasteBox.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            pasteBox.heightAnchor.constraint(equalToConstant: 48),

            pasteIcon.leadingAnchor.constraint(equalTo: pasteBox.leadingAnchor, constant: 14),
            pasteIcon.centerYAnchor.constraint(equalTo: pasteBox.centerYAnchor),
            pasteIcon.widthAnchor.constraint(equalToConstant: 20),
            pasteIcon.heightAnchor.constraint(equalToConstant: 20),

            pasteLabel.leadingAnchor.constraint(equalTo: pasteIcon.trailingAnchor, constant: 10),
            pasteLabel.centerYAnchor.constraint(equalTo: pasteBox.centerYAnchor),

            // Hint
            hintLabel.topAnchor.constraint(equalTo: pasteBox.bottomAnchor, constant: 4),
            hintLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            // Links
            linksStack.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 6),
            linksStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            linksStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Divider
            dividerStack.topAnchor.constraint(equalTo: linksStack.bottomAnchor, constant: 8),
            dividerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            dividerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Start button
            startContainer.topAnchor.constraint(equalTo: dividerStack.bottomAnchor, constant: 8),
            startContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            startContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            startContainer.heightAnchor.constraint(equalToConstant: 44),

            gradientBg.topAnchor.constraint(equalTo: startContainer.topAnchor),
            gradientBg.bottomAnchor.constraint(equalTo: startContainer.bottomAnchor),
            gradientBg.leadingAnchor.constraint(equalTo: startContainer.leadingAnchor),
            gradientBg.trailingAnchor.constraint(equalTo: startContainer.trailingAnchor),

            startLabel.topAnchor.constraint(equalTo: startContainer.topAnchor),
            startLabel.bottomAnchor.constraint(equalTo: startContainer.bottomAnchor),
            startLabel.leadingAnchor.constraint(equalTo: startContainer.leadingAnchor),
            startLabel.trailingAnchor.constraint(equalTo: startContainer.trailingAnchor),
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
            previousState = .awaitingClipboard
            currentState = .suggestions
            renderCurrentState()
            analyzeText(text, tone: currentTone(), conversationId: selectedConversation?.conversationId, objective: currentObjective())
        }
    }
}
