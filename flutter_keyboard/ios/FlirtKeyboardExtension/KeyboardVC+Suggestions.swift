import UIKit

extension KeyboardViewController {

    // MARK: - Estado 3: Suggestions (PRO)

    func renderSuggestions() {
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

    func makeSuggestionCard(index: Int, text: String, isBasicMode: Bool = false) -> UIView {
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
}
