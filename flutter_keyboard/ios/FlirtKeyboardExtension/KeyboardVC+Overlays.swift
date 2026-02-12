import UIKit

extension KeyboardViewController {

    // MARK: - Overlays

    func showObjectiveOverlay() {
        activeOverlay = .objectiveSelector
        containerView.viewWithTag(7777)?.removeFromSuperview()

        let overlay = UIView()
        overlay.tag = 7777
        overlay.backgroundColor = Theme.overlayBg
        overlay.layer.cornerRadius = 12
        overlay.clipsToBounds = true
        overlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            overlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            overlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            overlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
        ])

        let titleLabel = makeLabel("Escolha um Objetivo", size: 14, bold: true)
        overlay.addSubview(titleLabel)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(Theme.textSecondary, for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(dismissOverlay), for: .touchUpInside)
        overlay.addSubview(closeBtn)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        overlay.addSubview(scrollView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 12),
            closeBtn.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 6),
            closeBtn.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
            closeBtn.widthAnchor.constraint(equalToConstant: 28),
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -4),
        ])

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        for (i, obj) in availableObjectives.enumerated() {
            let card = makeObjectiveCard(obj, index: i, isSelected: i == selectedObjectiveIndex)
            contentStack.addArrangedSubview(card)
        }
    }

    func showToneOverlay() {
        activeOverlay = .toneSelector
        containerView.viewWithTag(7777)?.removeFromSuperview()

        let overlay = UIView()
        overlay.tag = 7777
        overlay.backgroundColor = Theme.overlayBg
        overlay.layer.cornerRadius = 12
        overlay.clipsToBounds = true
        overlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            overlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            overlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            overlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
        ])

        let titleLabel = makeLabel("Escolha o Tom", size: 14, bold: true)
        overlay.addSubview(titleLabel)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(Theme.textSecondary, for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(dismissOverlay), for: .touchUpInside)
        overlay.addSubview(closeBtn)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(contentStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 12),
            closeBtn.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 6),
            closeBtn.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
            closeBtn.widthAnchor.constraint(equalToConstant: 28),
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            contentStack.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
        ])

        for (i, _) in availableTones.enumerated() {
            let isSelected = i == selectedToneIndex
            let card = UIButton(type: .system)
            card.translatesAutoresizingMaskIntoConstraints = false

            let label = i == 0 ? "\(toneEmojis[i])  \(toneLabels[i]) (Recomendado)" : "\(toneEmojis[i])  \(toneLabels[i])"
            card.setTitle(label, for: .normal)
            card.setTitleColor(.white, for: .normal)
            card.contentHorizontalAlignment = .left
            card.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            card.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: isSelected ? .semibold : .regular)
            card.backgroundColor = isSelected ? Theme.selectedBg : Theme.cardBg
            card.layer.cornerRadius = 8
            card.layer.borderWidth = isSelected ? 1 : 0
            card.layer.borderColor = isSelected ? Theme.rose.cgColor : UIColor.clear.cgColor
            card.tag = 400 + i
            card.addTarget(self, action: #selector(toneFromOverlayTapped(_:)), for: .touchUpInside)
            card.heightAnchor.constraint(equalToConstant: 36).isActive = true
            contentStack.addArrangedSubview(card)
        }
    }

    func makeObjectiveCard(_ obj: Objective, index: Int, isSelected: Bool) -> UIButton {
        let card = UIButton(type: .system)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = isSelected ? Theme.selectedBg : Theme.cardBg
        card.layer.cornerRadius = 10
        card.layer.borderWidth = isSelected ? 1 : 0
        card.layer.borderColor = isSelected ? Theme.rose.cgColor : UIColor.clear.cgColor
        card.tag = 300 + index
        card.addTarget(self, action: #selector(objectiveFromOverlayTapped(_:)), for: .touchUpInside)

        let emoji = UILabel()
        emoji.text = obj.emoji
        emoji.font = UIFont.systemFont(ofSize: 18)
        emoji.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(emoji)

        let title = UILabel()
        title.text = obj.title
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let desc = UILabel()
        desc.text = obj.description
        desc.textColor = Theme.textSecondary
        desc.font = UIFont.systemFont(ofSize: 10)
        desc.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(desc)

        let check = UILabel()
        check.text = isSelected ? "✓" : ""
        check.textColor = Theme.orange
        check.font = UIFont.boldSystemFont(ofSize: 14)
        check.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(check)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 40),
            emoji.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            emoji.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: emoji.trailingAnchor, constant: 8),
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 5),
            desc.leadingAnchor.constraint(equalTo: emoji.trailingAnchor, constant: 8),
            desc.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -5),
            desc.trailingAnchor.constraint(equalTo: check.leadingAnchor, constant: -8),
            check.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            check.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        return card
    }
}
