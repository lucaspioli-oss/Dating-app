import UIKit

extension KeyboardViewController {

    // MARK: - Start Conversation

    func renderStartConversation() {
        guard let conv = selectedConversation else { return }

        // Header row: back + title + pills + globe
        let backBtn = UIButton(type: .system)
        backBtn.setTitle("← Back", for: .normal)
        backBtn.setTitleColor(Theme.textSecondary, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.addTarget(self, action: #selector(backFromStartConvTapped), for: .touchUpInside)
        containerView.addSubview(backBtn)

        let titleLabel = UILabel()
        titleLabel.text = "🚀 \(conv.matchName)"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        let objPillHeader = makeObjectivePill(compact: true)
        containerView.addSubview(objPillHeader)

        let tonePillHeader = makeTonePill(compact: true)
        containerView.addSubview(tonePillHeader)

        let switchBtn = makeKeyboardSwitchButton()
        containerView.addSubview(switchBtn)

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            backBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            backBtn.heightAnchor.constraint(equalToConstant: 28),
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 4),
            objPillHeader.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            objPillHeader.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 6),
            tonePillHeader.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            tonePillHeader.leadingAnchor.constraint(equalTo: objPillHeader.trailingAnchor, constant: 4),
            switchBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            tonePillHeader.trailingAnchor.constraint(lessThanOrEqualTo: switchBtn.leadingAnchor, constant: -4),
        ])

        // Content area
        if isLoadingSuggestions && suggestions.isEmpty {
            renderStartConvLoading(below: backBtn)
        } else if !suggestions.isEmpty {
            renderStartConvSuggestions(below: backBtn)
        }
    }

    // MARK: - Loading State

    private func renderStartConvLoading(below headerView: UIView) {
        let loadingStack = UIStackView()
        loadingStack.axis = .vertical
        loadingStack.spacing = 12
        loadingStack.alignment = .center
        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(loadingStack)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        loadingStack.addArrangedSubview(spinner)

        let loadLabel = UILabel()
        loadLabel.text = "Gerando aberturas..."
        loadLabel.textColor = Theme.textSecondary
        loadLabel.font = UIFont.systemFont(ofSize: 13)
        loadLabel.textAlignment = .center
        loadLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingStack.addArrangedSubview(loadLabel)

        NSLayoutConstraint.activate([
            loadingStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 10),
        ])
    }
    // MARK: - Suggestions State

    private func renderStartConvSuggestions(below headerView: UIView) {

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
            let card = makeStartConvCard(index: index, text: suggestion)
            contentStack.addArrangedSubview(card)
        }

        // Bottom bar (30px)
        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bottomBar)

        // Write button
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
        writeLabel.text = "Escrever"
        writeLabel.textColor = Theme.textSecondary
        writeLabel.font = UIFont.systemFont(ofSize: 11)
        writeLabel.translatesAutoresizingMaskIntoConstraints = false
        writeBar.addSubview(writeLabel)

        // Regenerate button
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
        regenBtn.addTarget(self, action: #selector(startConversationTapped), for: .touchUpInside)
        bottomBar.addSubview(regenBtn)

        // Compact pills
        let objPill = makeObjectivePill(compact: true)
        let tonePill = makeTonePill(compact: true)
        bottomBar.addSubview(objPill)
        bottomBar.addSubview(tonePill)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 6),
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
            writeLabel.trailingAnchor.constraint(equalTo: writeBar.trailingAnchor, constant: -8),
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
    }
    // MARK: - Suggestion Card for Start Conversation

    private func makeStartConvCard(index: Int, text: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = Theme.suggestionBg
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 0.5
        card.layer.borderColor = Theme.rose.withAlphaComponent(0.2).cgColor

        let numberLabel = UILabel()
        numberLabel.text = "\(index + 1)."
        numberLabel.textColor = Theme.rose
        numberLabel.font = UIFont.boldSystemFont(ofSize: 13)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)
        card.addSubview(numberLabel)

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = .white
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textLabel)

        // Send button
        let sendBtn = UIButton(type: .system)
        if #available(iOSApplicationExtension 13.0, *) {
            sendBtn.setImage(UIImage(systemName: "arrow.up.right.circle.fill"), for: .normal)
        } else {
            sendBtn.setTitle("↗", for: .normal)
        }
        sendBtn.tintColor = Theme.rose
        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        sendBtn.tag = index
        sendBtn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        card.addSubview(sendBtn)

        // Make entire card tappable
        let tapBtn = UIButton(type: .system)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        tapBtn.tag = index
        tapBtn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        card.insertSubview(tapBtn, at: 0)

        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            numberLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            textLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            textLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 6),
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