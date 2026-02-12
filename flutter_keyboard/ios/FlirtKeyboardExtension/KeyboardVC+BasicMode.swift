import UIKit

extension KeyboardViewController {

    // MARK: - Estado 4: Basic Mode

    func renderBasicMode() {
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
                // Scrollable suggestions area (same card style as PRO mode)
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
                    let card = makeSuggestionCard(index: index, text: suggestion, isBasicMode: true)
                    contentStack.addArrangedSubview(card)
                }

                let bottomStack = UIStackView()
                bottomStack.axis = .horizontal
                bottomStack.spacing = 6
                bottomStack.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(bottomStack)

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
                regenBtn.widthAnchor.constraint(equalToConstant: 32).isActive = true
                regenBtn.heightAnchor.constraint(equalToConstant: 28).isActive = true
                regenBtn.addTarget(self, action: #selector(basicRegenTapped), for: .touchUpInside)
                bottomStack.addArrangedSubview(regenBtn)

                let spacer = UIView()
                bottomStack.addArrangedSubview(spacer)

                bottomStack.addArrangedSubview(makeObjectivePill(compact: true))
                bottomStack.addArrangedSubview(makeTonePill(compact: true))

                NSLayoutConstraint.activate([
                    scrollView.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 6),
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
            } else if isLoadingSuggestions {
                // Loading indicator
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
                    loadingStack.topAnchor.constraint(equalTo: clipLabel.bottomAnchor, constant: 30),
                    loadingStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
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
}
