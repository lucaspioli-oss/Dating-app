import UIKit

extension KeyboardViewController {

    // MARK: - Estado 1: Profile Selector

    func renderProfileSelector() {
        // Search bar (tappable — opens QWERTY overlay)
        let searchContainer = UIView()
        searchContainer.backgroundColor = isSearchActive ? Theme.rose.withAlphaComponent(0.15) : Theme.cardBg
        searchContainer.layer.cornerRadius = 8
        if isSearchActive {
            searchContainer.layer.borderWidth = 0.5
            searchContainer.layer.borderColor = Theme.rose.withAlphaComponent(0.5).cgColor
        }
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.isUserInteractionEnabled = true
        let searchTap = UITapGestureRecognizer(target: self, action: #selector(searchBarTapped))
        searchContainer.addGestureRecognizer(searchTap)
        containerView.addSubview(searchContainer)

        let searchLabel = UILabel()
        searchLabel.text = searchText.isEmpty ? "🔍 Buscar perfil..." : "🔍 \(searchText)"
        searchLabel.textColor = searchText.isEmpty ? Theme.textSecondary : .white
        searchLabel.font = UIFont.systemFont(ofSize: 13)
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchLabel)

        if isSearchActive {
            // --- SEARCH MODE: no title, input at top, QWERTY + profiles ---

            // Blinking cursor in search bar
            let cursor = UIView()
            cursor.backgroundColor = Theme.rose
            cursor.translatesAutoresizingMaskIntoConstraints = false
            searchContainer.addSubview(cursor)

            NSLayoutConstraint.activate([
                searchContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                searchContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                searchContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                searchContainer.heightAnchor.constraint(equalToConstant: 32),
                searchLabel.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
                searchLabel.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
                cursor.leadingAnchor.constraint(equalTo: searchLabel.trailingAnchor, constant: 1),
                cursor.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
                cursor.widthAnchor.constraint(equalToConstant: 2),
                cursor.heightAnchor.constraint(equalToConstant: 16),
            ])

            UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
                cursor.alpha = 0
            })

            let qwertyView = makeQWERTYKeyboard(forSearch: true)
            containerView.addSubview(qwertyView)

            NSLayoutConstraint.activate([
                qwertyView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 3),
                qwertyView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
                qwertyView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
                qwertyView.heightAnchor.constraint(equalToConstant: 82),
            ])

            // Filtered profile list below QWERTY
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsHorizontalScrollIndicator = false
            containerView.addSubview(scrollView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: qwertyView.bottomAnchor, constant: 4),
                scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
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

            if filteredConversations.isEmpty && !searchText.isEmpty {
                let l = makeLabel("Nenhum perfil encontrado", size: 12)
                l.textColor = Theme.textSecondary
                stackView.addArrangedSubview(l)
            } else {
                for (index, conv) in filteredConversations.enumerated() {
                    stackView.addArrangedSubview(makeProfileButton(conv, tag: index))
                }
            }

        } else {
            // --- NORMAL MODE: title + search bar + profiles + quick button ---
            let titleLabel = makeLabel("Com quem você está falando?", size: 14, bold: true)
            containerView.addSubview(titleLabel)

            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                searchContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                searchContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                searchContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                searchContainer.heightAnchor.constraint(equalToConstant: 28),
                searchLabel.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
                searchLabel.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -8),
                searchLabel.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            ])
            // --- Normal mode: profiles + quick button visible ---
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsHorizontalScrollIndicator = false
            containerView.addSubview(scrollView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 8),
                scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                scrollView.heightAnchor.constraint(equalToConstant: 80),
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
                let l = makeLabel("Carregando perfis...", size: 12)
                l.textColor = Theme.textSecondary
                stackView.addArrangedSubview(l)
            } else if let error = profilesError {
                let l = makeLabel(error, size: 11)
                l.textColor = Theme.errorText
                l.numberOfLines = 2
                stackView.addArrangedSubview(l)
            } else if conversations.isEmpty {
                let l = makeLabel("Nenhum perfil criado.\nCrie um perfil no app primeiro.", size: 12)
                l.textColor = Theme.textSecondary
                l.numberOfLines = 2
                stackView.addArrangedSubview(l)
            } else {
                for (index, conv) in filteredConversations.enumerated() {
                    stackView.addArrangedSubview(makeProfileButton(conv, tag: index))
                }
            }

            let quickButton = makeGradientButton("⚡ Modo Rápido — sem perfil", fontSize: 13)
            quickButton.addTarget(self, action: #selector(quickModeTapped), for: .touchUpInside)
            containerView.addSubview(quickButton)

            let switchBtn = makeKeyboardSwitchButton()
            containerView.addSubview(switchBtn)

            NSLayoutConstraint.activate([
                quickButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
                quickButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                quickButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -56),
                quickButton.heightAnchor.constraint(equalToConstant: 36),
                switchBtn.centerYAnchor.constraint(equalTo: quickButton.centerYAnchor),
                switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                switchBtn.widthAnchor.constraint(equalToConstant: 32),
            ])
        }
    }

    @objc func searchBarTapped() {
        isSearchActive = !isSearchActive
        if !isSearchActive {
            searchText = ""
            filteredConversations = conversations
        }
        renderCurrentState()
    }
}
