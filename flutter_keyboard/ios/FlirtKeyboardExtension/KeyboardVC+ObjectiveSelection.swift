import UIKit

extension KeyboardViewController {

    // MARK: - Estado 2: Objective Selection (2-column grid)

    func renderObjectiveSelection() {

        // ── Header row (28px): "← Back" | title | 🌐 ──

        let backBtn = UIButton(type: .system)
        backBtn.setTitle("← Back", for: .normal)
        backBtn.setTitleColor(Theme.textSecondary, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.addTarget(self, action: #selector(backFromObjectiveTapped), for: .touchUpInside)
        containerView.addSubview(backBtn)

        let titleLabel = makeLabel("Escolha seu Objetivo", size: 13, bold: true)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        let switchBtn = makeKeyboardSwitchButton()
        containerView.addSubview(switchBtn)

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: containerView.topAnchor),
            backBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            backBtn.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: switchBtn.leadingAnchor, constant: -4),

            switchBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
        ])

        // ── ScrollView with 2-column grid (fills remaining 262px) ──

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        containerView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backBtn.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
        ])

        // Content view inside scroll
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        let columnGap: CGFloat = 8
        let rowGap: CGFloat = 8
        let cardHeight: CGFloat = 62
        let rowCount = Int(ceil(Double(availableObjectives.count) / 2.0))

        // Calculate total content height
        let totalHeight = CGFloat(rowCount) * cardHeight + CGFloat(rowCount - 1) * rowGap
        contentView.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true

        // Build cards row by row
        for (index, objective) in availableObjectives.enumerated() {
            let col = index % 2
            let row = index / 2
            let isSelected = index == selectedObjectiveIndex

            let card = UIButton(type: .system)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.backgroundColor = isSelected ? Theme.selectedBg : Theme.cardBg
            card.layer.cornerRadius = 10
            card.clipsToBounds = true
            card.tag = 800 + index
            card.addTarget(self, action: #selector(objectiveCardTapped(_:)), for: .touchUpInside)

            if isSelected {
                card.layer.borderWidth = 1
                card.layer.borderColor = Theme.rose.cgColor
            } else {
                card.layer.borderWidth = 0.5
                card.layer.borderColor = Theme.textSecondary.cgColor
            }

            contentView.addSubview(card)

            // Position card via Auto Layout
            let topOffset = CGFloat(row) * (cardHeight + rowGap)

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topOffset),
                card.heightAnchor.constraint(equalToConstant: cardHeight),
            ])

            if col == 0 {
                // Left column
                NSLayoutConstraint.activate([
                    card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    card.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -(columnGap / 2)),
                ])
            } else {
                // Right column
                NSLayoutConstraint.activate([
                    card.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: columnGap / 2),
                    card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                ])
            }

            // ── Card inner content: centered emoji+title / description ──

            let emojiLabel = UILabel()
            emojiLabel.text = objective.emoji
            emojiLabel.font = UIFont.systemFont(ofSize: 18)
            emojiLabel.isUserInteractionEnabled = false

            let titleLabel = UILabel()
            titleLabel.text = objective.title
            titleLabel.textColor = .white
            titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
            titleLabel.textAlignment = .center
            titleLabel.isUserInteractionEnabled = false

            let topRow = UIStackView(arrangedSubviews: [emojiLabel, titleLabel])
            topRow.axis = .horizontal
            topRow.spacing = 4
            topRow.alignment = .center
            topRow.isUserInteractionEnabled = false

            let descLabel = UILabel()
            descLabel.text = objective.description
            descLabel.textColor = Theme.textSecondary
            descLabel.font = UIFont.systemFont(ofSize: 10)
            descLabel.textAlignment = .center
            descLabel.numberOfLines = 2
            descLabel.lineBreakMode = .byTruncatingTail
            descLabel.isUserInteractionEnabled = false

            let outerStack = UIStackView(arrangedSubviews: [topRow, descLabel])
            outerStack.axis = .vertical
            outerStack.spacing = 2
            outerStack.alignment = .center
            outerStack.translatesAutoresizingMaskIntoConstraints = false
            outerStack.isUserInteractionEnabled = false
            card.addSubview(outerStack)

            NSLayoutConstraint.activate([
                outerStack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                outerStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                outerStack.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 4),
                outerStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -4),
            ])
        }
    }
}
