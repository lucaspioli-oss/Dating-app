import UIKit

extension KeyboardViewController {

    // MARK: - UI Component Helpers

    func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    func makeHeader(_ text: String, showBack: Bool) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        if showBack {
            let backBtn = UIButton(type: .system)
            backBtn.setTitle("←", for: .normal)
            backBtn.setTitleColor(Theme.textSecondary, for: .normal)
            backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            stack.addArrangedSubview(backBtn)
        }

        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(label)

        stack.addArrangedSubview(UIView())
        return stack
    }

    func makeObjectivePill(compact: Bool = false) -> UIButton {
        let btn = UIButton(type: .system)
        let obj = availableObjectives[selectedObjectiveIndex]
        let title = compact ? "\(obj.emoji) ▾" : "\(obj.emoji) \(obj.title) ▾"
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.cardBg
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = selectedObjectiveIndex != 0 ? 1 : 0.5
        btn.layer.borderColor = selectedObjectiveIndex != 0 ? Theme.rose.cgColor : Theme.textSecondary.withAlphaComponent(0.3).cgColor
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(objectivePillTapped), for: .touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return btn
    }

    func makeTonePill(compact: Bool = false) -> UIButton {
        let btn = UIButton(type: .system)
        let title = compact ? "\(toneEmojis[selectedToneIndex]) ▾" : "\(toneEmojis[selectedToneIndex]) \(toneLabels[selectedToneIndex]) ▾"
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.cardBg
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = selectedToneIndex != 0 ? 1 : 0.5
        btn.layer.borderColor = selectedToneIndex != 0 ? Theme.orange.cgColor : Theme.textSecondary.withAlphaComponent(0.3).cgColor
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tonePillTapped), for: .touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return btn
    }

    func makeProfileButton(_ conv: ConversationContext, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 64).isActive = true

        // Circular photo container with gradient border (like stories)
        let photoSize: CGFloat = 48
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0).cgColor,
            UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.18, blue: 0.74, alpha: 1.0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: photoSize + 4, height: photoSize + 4)
        gradientLayer.cornerRadius = (photoSize + 4) / 2
        borderView.layer.addSublayer(gradientLayer)
        container.addSubview(borderView)

        let photoView = UIView()
        photoView.backgroundColor = Theme.cardBg
        photoView.layer.cornerRadius = photoSize / 2
        photoView.clipsToBounds = true
        photoView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(photoView)

        // Decode and show photo if available
        if let base64 = conv.faceImageBase64,
           let data = Data(base64Encoded: base64),
           let image = UIImage(data: data) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.translatesAutoresizingMaskIntoConstraints = false
            photoView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: photoView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: photoView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: photoView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: photoView.bottomAnchor),
            ])
        } else {
            // Placeholder with initials
            let initialsLabel = UILabel()
            initialsLabel.text = String(conv.matchName.prefix(1)).uppercased()
            initialsLabel.textColor = .white
            initialsLabel.font = UIFont.boldSystemFont(ofSize: 18)
            initialsLabel.textAlignment = .center
            initialsLabel.translatesAutoresizingMaskIntoConstraints = false
            photoView.addSubview(initialsLabel)
            NSLayoutConstraint.activate([
                initialsLabel.centerXAnchor.constraint(equalTo: photoView.centerXAnchor),
                initialsLabel.centerYAnchor.constraint(equalTo: photoView.centerYAnchor),
            ])
        }

        // Name label below
        let nameLabel = UILabel()
        nameLabel.text = conv.matchName.count > 8 ? String(conv.matchName.prefix(7)) + "…" : conv.matchName
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 10)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: container.topAnchor),
            borderView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            borderView.widthAnchor.constraint(equalToConstant: photoSize + 4),
            borderView.heightAnchor.constraint(equalToConstant: photoSize + 4),
            photoView.centerXAnchor.constraint(equalTo: borderView.centerXAnchor),
            photoView.centerYAnchor.constraint(equalTo: borderView.centerYAnchor),
            photoView.widthAnchor.constraint(equalToConstant: photoSize),
            photoView.heightAnchor.constraint(equalToConstant: photoSize),
            nameLabel.topAnchor.constraint(equalTo: borderView.bottomAnchor, constant: 2),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            nameLabel.widthAnchor.constraint(equalTo: container.widthAnchor),
        ])

        // Tap gesture
        let tapBtn = UIButton(type: .system)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        tapBtn.tag = tag
        tapBtn.addTarget(self, action: #selector(profileTapped(_:)), for: .touchUpInside)
        container.addSubview(tapBtn)
        NSLayoutConstraint.activate([
            tapBtn.topAnchor.constraint(equalTo: container.topAnchor),
            tapBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tapBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tapBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    func makeQWERTYKeyboard(forSearch: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let rows: [[String]] = [
            ["q","w","e","r","t","y","u","i","o","p"],
            ["a","s","d","f","g","h","j","k","l"],
            ["z","x","c","v","b","n","m"]
        ]
        let keyHeight: CGFloat = forSearch ? 26 : 32
        let rowSpacing: CGFloat = 2
        let keySpacing: CGFloat = 3

        var previousRow: UIView?
        var tagIndex = 0

        for (rowIdx, row) in rows.enumerated() {
            let rowView = UIView()
            rowView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(rowView)

            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                rowView.heightAnchor.constraint(equalToConstant: keyHeight),
            ])

            if let prev = previousRow {
                rowView.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: rowSpacing).isActive = true
            } else {
                rowView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            }

            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = keySpacing
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(rowStack)

            // Indent rows 2 and 3
            let indent: CGFloat = rowIdx == 1 ? 14 : (rowIdx == 2 ? 6 : 0)

            // Row 3: add shift button before letters
            if rowIdx == 2 {
                let shiftBtn = UIButton(type: .system)
                shiftBtn.setTitle(isShiftActive ? "⇧" : "⇪", for: .normal)
                shiftBtn.setTitleColor(isShiftActive ? Theme.orange : .white, for: .normal)
                shiftBtn.backgroundColor = isShiftActive ? Theme.rose.withAlphaComponent(0.2) : Theme.suggestionBg
                shiftBtn.layer.cornerRadius = 5
                shiftBtn.titleLabel?.font = UIFont.systemFont(ofSize: forSearch ? 11 : 13, weight: .medium)
                shiftBtn.translatesAutoresizingMaskIntoConstraints = false
                shiftBtn.addTarget(self, action: #selector(qwertyShiftTapped), for: .touchUpInside)
                rowView.addSubview(shiftBtn)
                NSLayoutConstraint.activate([
                    shiftBtn.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
                    shiftBtn.topAnchor.constraint(equalTo: rowView.topAnchor),
                    shiftBtn.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    shiftBtn.widthAnchor.constraint(equalToConstant: forSearch ? 28 : 36),
                ])
            }

            for char in row {
                let btn = UIButton(type: .system)
                let displayChar = isShiftActive ? char.uppercased() : char
                btn.setTitle(displayChar, for: .normal)
                btn.setTitleColor(.white, for: .normal)
                btn.backgroundColor = Theme.suggestionBg
                btn.layer.cornerRadius = 5
                btn.titleLabel?.font = UIFont.systemFont(ofSize: forSearch ? 12 : 14, weight: .medium)
                btn.tag = 700 + tagIndex
                btn.addTarget(self, action: #selector(qwertyKeyTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
                tagIndex += 1
            }

            // Row 3: add backspace after letters
            if rowIdx == 2 {
                let bkspBtn = UIButton(type: .system)
                if #available(iOSApplicationExtension 13.0, *) {
                    let config = UIImage.SymbolConfiguration(pointSize: forSearch ? 11 : 13, weight: .medium)
                    bkspBtn.setImage(UIImage(systemName: "delete.left", withConfiguration: config), for: .normal)
                } else {
                    bkspBtn.setTitle("⌫", for: .normal)
                }
                bkspBtn.tintColor = Theme.orange
                bkspBtn.backgroundColor = Theme.suggestionBg
                bkspBtn.layer.cornerRadius = 5
                bkspBtn.translatesAutoresizingMaskIntoConstraints = false
                bkspBtn.addTarget(self, action: #selector(qwertyBackspaceTapped), for: .touchUpInside)
                rowView.addSubview(bkspBtn)

                // Clear/close button
                let clearBtn = UIButton(type: .system)
                if forSearch {
                    clearBtn.setTitle("Fechar", for: .normal)
                    clearBtn.setTitleColor(.white, for: .normal)
                    clearBtn.backgroundColor = Theme.rose.withAlphaComponent(0.6)
                } else {
                    clearBtn.setTitle("✕", for: .normal)
                    clearBtn.setTitleColor(Theme.errorText, for: .normal)
                    clearBtn.backgroundColor = Theme.suggestionBg
                }
                clearBtn.layer.cornerRadius = 5
                clearBtn.titleLabel?.font = UIFont.systemFont(ofSize: forSearch ? 10 : 13, weight: forSearch ? .semibold : .regular)
                clearBtn.translatesAutoresizingMaskIntoConstraints = false
                clearBtn.addTarget(self, action: #selector(qwertyClearTapped), for: .touchUpInside)
                rowView.addSubview(clearBtn)

                let shiftWidth: CGFloat = forSearch ? 28 : 36
                let clearWidth: CGFloat = forSearch ? 44 : 30
                NSLayoutConstraint.activate([
                    rowStack.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: shiftWidth + keySpacing),
                    rowStack.topAnchor.constraint(equalTo: rowView.topAnchor),
                    rowStack.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    bkspBtn.leadingAnchor.constraint(equalTo: rowStack.trailingAnchor, constant: keySpacing),
                    bkspBtn.topAnchor.constraint(equalTo: rowView.topAnchor),
                    bkspBtn.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    bkspBtn.widthAnchor.constraint(equalToConstant: forSearch ? 28 : 36),
                    clearBtn.leadingAnchor.constraint(equalTo: bkspBtn.trailingAnchor, constant: keySpacing),
                    clearBtn.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
                    clearBtn.topAnchor.constraint(equalTo: rowView.topAnchor),
                    clearBtn.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    clearBtn.widthAnchor.constraint(equalToConstant: clearWidth),
                ])
            } else {
                NSLayoutConstraint.activate([
                    rowStack.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: indent),
                    rowStack.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -indent),
                    rowStack.topAnchor.constraint(equalTo: rowView.topAnchor),
                    rowStack.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                ])
            }

            previousRow = rowView
        }

        // Row 4: space bar (only for writeOwn) or bottom actions
        if !forSearch {
            let bottomRow = UIView()
            bottomRow.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(bottomRow)

            NSLayoutConstraint.activate([
                bottomRow.topAnchor.constraint(equalTo: previousRow!.bottomAnchor, constant: rowSpacing),
                bottomRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                bottomRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                bottomRow.heightAnchor.constraint(equalToConstant: keyHeight),
                bottomRow.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])

            let backBtn = UIButton(type: .system)
            backBtn.setTitle("← Voltar", for: .normal)
            backBtn.setTitleColor(Theme.textSecondary, for: .normal)
            backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            backBtn.backgroundColor = Theme.cardBg
            backBtn.layer.cornerRadius = 5
            backBtn.translatesAutoresizingMaskIntoConstraints = false
            backBtn.addTarget(self, action: #selector(backToSuggestionsTapped), for: .touchUpInside)
            bottomRow.addSubview(backBtn)

            let spaceBtn = UIButton(type: .system)
            spaceBtn.setTitle("espaço", for: .normal)
            spaceBtn.setTitleColor(Theme.textSecondary, for: .normal)
            spaceBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            spaceBtn.backgroundColor = Theme.suggestionBg
            spaceBtn.layer.cornerRadius = 5
            spaceBtn.translatesAutoresizingMaskIntoConstraints = false
            spaceBtn.addTarget(self, action: #selector(qwertySpaceTapped), for: .touchUpInside)
            bottomRow.addSubview(spaceBtn)

            // Insert button with gradient background
            let insertContainer = UIView()
            insertContainer.translatesAutoresizingMaskIntoConstraints = false
            insertContainer.layer.cornerRadius = 5
            insertContainer.clipsToBounds = true

            let gradientBg = GradientView()
            gradientBg.translatesAutoresizingMaskIntoConstraints = false
            insertContainer.addSubview(gradientBg)

            let insertLabel = UILabel()
            insertLabel.text = "Inserir ↗"
            insertLabel.textColor = .white
            insertLabel.font = UIFont.boldSystemFont(ofSize: 12)
            insertLabel.textAlignment = .center
            insertLabel.translatesAutoresizingMaskIntoConstraints = false
            insertContainer.addSubview(insertLabel)

            let insertTap = UITapGestureRecognizer(target: self, action: #selector(insertOwnTapped))
            insertContainer.addGestureRecognizer(insertTap)
            insertContainer.isUserInteractionEnabled = true

            NSLayoutConstraint.activate([
                gradientBg.topAnchor.constraint(equalTo: insertContainer.topAnchor),
                gradientBg.bottomAnchor.constraint(equalTo: insertContainer.bottomAnchor),
                gradientBg.leadingAnchor.constraint(equalTo: insertContainer.leadingAnchor),
                gradientBg.trailingAnchor.constraint(equalTo: insertContainer.trailingAnchor),
                insertLabel.topAnchor.constraint(equalTo: insertContainer.topAnchor),
                insertLabel.bottomAnchor.constraint(equalTo: insertContainer.bottomAnchor),
                insertLabel.leadingAnchor.constraint(equalTo: insertContainer.leadingAnchor),
                insertLabel.trailingAnchor.constraint(equalTo: insertContainer.trailingAnchor),
            ])
            bottomRow.addSubview(insertContainer)

            NSLayoutConstraint.activate([
                backBtn.leadingAnchor.constraint(equalTo: bottomRow.leadingAnchor),
                backBtn.topAnchor.constraint(equalTo: bottomRow.topAnchor),
                backBtn.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
                backBtn.widthAnchor.constraint(equalToConstant: 70),

                spaceBtn.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: keySpacing),
                spaceBtn.topAnchor.constraint(equalTo: bottomRow.topAnchor),
                spaceBtn.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),

                insertContainer.leadingAnchor.constraint(equalTo: spaceBtn.trailingAnchor, constant: keySpacing),
                insertContainer.trailingAnchor.constraint(equalTo: bottomRow.trailingAnchor),
                insertContainer.topAnchor.constraint(equalTo: bottomRow.topAnchor),
                insertContainer.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
                insertContainer.widthAnchor.constraint(equalToConstant: 90),
            ])
        }

        return container
    }

    func startCursorBlink(_ cursor: UIView) {
        UIView.animateKeyframes(withDuration: 1.0, delay: 0, options: [.repeat]) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.01) { cursor.alpha = 1 }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.01) { cursor.alpha = 0 }
        }
    }

    func makeKeyboardSwitchButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("🌐", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        btn.widthAnchor.constraint(equalToConstant: 32).isActive = true
        return btn
    }

    func makeGradientButton(_ title: String, fontSize: CGFloat) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize)
        btn.layer.cornerRadius = 10
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0).cgColor,
            UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.18, blue: 0.74, alpha: 1.0).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = CGRect(x: 0, y: 0, width: 400, height: 50)
        btn.layer.insertSublayer(gradient, at: 0)

        return btn
    }
}
