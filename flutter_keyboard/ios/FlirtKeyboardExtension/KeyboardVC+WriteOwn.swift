import UIKit

extension KeyboardViewController {

    // MARK: - Estado 3B: Write Own (PRO)

    func renderWriteOwn() {
        guard let conv = selectedConversation else { return }

        // Text display bar showing what user is typing
        let textDisplay = UIView()
        textDisplay.backgroundColor = Theme.cardBg
        textDisplay.layer.cornerRadius = 8
        textDisplay.layer.borderWidth = 1
        textDisplay.layer.borderColor = Theme.rose.withAlphaComponent(0.4).cgColor
        textDisplay.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textDisplay)

        let displayLabel = UILabel()
        displayLabel.tag = 998
        displayLabel.text = writeOwnText.isEmpty ? "Digite sua resposta..." : writeOwnText
        displayLabel.textColor = writeOwnText.isEmpty ? Theme.textSecondary : .white
        displayLabel.font = UIFont.systemFont(ofSize: 14)
        displayLabel.translatesAutoresizingMaskIntoConstraints = false
        textDisplay.addSubview(displayLabel)

        // Cursor blink indicator
        let cursor = UIView()
        cursor.backgroundColor = Theme.rose
        cursor.translatesAutoresizingMaskIntoConstraints = false
        textDisplay.addSubview(cursor)

        // QWERTY keyboard for typing
        let qwertyView = makeQWERTYKeyboard(forSearch: false)
        containerView.addSubview(qwertyView)

        // Bottom buttons row (inside QWERTY bottom row)
        NSLayoutConstraint.activate([
            textDisplay.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            textDisplay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            textDisplay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            textDisplay.heightAnchor.constraint(equalToConstant: 34),

            displayLabel.leadingAnchor.constraint(equalTo: textDisplay.leadingAnchor, constant: 10),
            displayLabel.trailingAnchor.constraint(equalTo: textDisplay.trailingAnchor, constant: -10),
            displayLabel.centerYAnchor.constraint(equalTo: textDisplay.centerYAnchor),

            qwertyView.topAnchor.constraint(equalTo: textDisplay.bottomAnchor, constant: 4),
            qwertyView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            qwertyView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            qwertyView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
        ])

        NSLayoutConstraint.activate([
            cursor.leadingAnchor.constraint(equalTo: displayLabel.trailingAnchor, constant: 1),
            cursor.centerYAnchor.constraint(equalTo: textDisplay.centerYAnchor),
            cursor.widthAnchor.constraint(equalToConstant: 2),
            cursor.heightAnchor.constraint(equalToConstant: 18),
        ])

        startCursorBlink(cursor)
    }
}
