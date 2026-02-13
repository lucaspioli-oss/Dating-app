import UIKit

extension KeyboardViewController {

    // MARK: - Screenshot Analysis

    func renderScreenshotAnalysis() {

        let backBtn = UIButton(type: .system)
        backBtn.setTitle("← Back", for: .normal)
        backBtn.setTitleColor(Theme.textSecondary, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.addTarget(self, action: #selector(backFromScreenshotTapped), for: .touchUpInside)
        containerView.addSubview(backBtn)

        let titleLabel = UILabel()
        titleLabel.text = "📸 Screenshot"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        let switchBtn = makeKeyboardSwitchButton()
        containerView.addSubview(switchBtn)

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            backBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            backBtn.heightAnchor.constraint(equalToConstant: 28),
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: switchBtn.leadingAnchor, constant: -6),
            switchBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            switchBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
        ])

        if isAnalyzingScreenshot {
            renderAnalyzingState(below: backBtn)
        } else {
            renderInstructionsState(below: backBtn)
        }
    }
    // MARK: - Instructions State

    private func renderInstructionsState(below headerView: UIView) {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStack)

        let mainLabel = UILabel()
        mainLabel.text = "Copie o print da conversa"
        mainLabel.textColor = .white
        mainLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        mainLabel.textAlignment = .center
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(mainLabel)

        let step1 = makeStepLabel("1. Tire print da conversa")
        let step2 = makeStepLabel("2. Abra Fotos e copie a imagem")
        let step3 = makeStepLabel("3. Volte e toque o botão")
        contentStack.addArrangedSubview(step1)
        contentStack.addArrangedSubview(step2)
        contentStack.addArrangedSubview(step3)

        let errorLabel = UILabel()
        errorLabel.text = ""
        errorLabel.textColor = Theme.errorText
        errorLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.tag = 8500
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(errorLabel)

        let pasteContainer = UIView()
        pasteContainer.translatesAutoresizingMaskIntoConstraints = false
        pasteContainer.layer.cornerRadius = 12
        pasteContainer.clipsToBounds = true
        pasteContainer.isUserInteractionEnabled = true
        containerView.addSubview(pasteContainer)

        let gradientBg = GradientView()
        gradientBg.translatesAutoresizingMaskIntoConstraints = false
        pasteContainer.addSubview(gradientBg)

        let pasteLabel = UILabel()
        pasteLabel.text = "📸 Colar Screenshot"
        pasteLabel.textColor = .white
        pasteLabel.font = UIFont.boldSystemFont(ofSize: 14)
        pasteLabel.textAlignment = .center
        pasteLabel.translatesAutoresizingMaskIntoConstraints = false
        pasteContainer.addSubview(pasteLabel)

        let pasteTap = UITapGestureRecognizer(target: self, action: #selector(pasteScreenshotTapped))
        pasteContainer.addGestureRecognizer(pasteTap)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            pasteContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            pasteContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            pasteContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            pasteContainer.heightAnchor.constraint(equalToConstant: 44),
            gradientBg.topAnchor.constraint(equalTo: pasteContainer.topAnchor),
            gradientBg.bottomAnchor.constraint(equalTo: pasteContainer.bottomAnchor),
            gradientBg.leadingAnchor.constraint(equalTo: pasteContainer.leadingAnchor),
            gradientBg.trailingAnchor.constraint(equalTo: pasteContainer.trailingAnchor),
            pasteLabel.topAnchor.constraint(equalTo: pasteContainer.topAnchor),
            pasteLabel.bottomAnchor.constraint(equalTo: pasteContainer.bottomAnchor),
            pasteLabel.leadingAnchor.constraint(equalTo: pasteContainer.leadingAnchor),
            pasteLabel.trailingAnchor.constraint(equalTo: pasteContainer.trailingAnchor),
        ])
    }
    // MARK: - Analyzing State

    private func renderAnalyzingState(below headerView: UIView) {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStack)

        if let image = screenshotImage {
            let thumbView = UIImageView(image: image)
            thumbView.contentMode = .scaleAspectFill
            thumbView.clipsToBounds = true
            thumbView.layer.cornerRadius = 10
            thumbView.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview(thumbView)

            NSLayoutConstraint.activate([
                thumbView.widthAnchor.constraint(equalToConstant: 60),
                thumbView.heightAnchor.constraint(equalToConstant: 60),
            ])
        }

        let analyzingLabel = UILabel()
        analyzingLabel.text = "Analisando screenshot..."
        analyzingLabel.textColor = .white
        analyzingLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        analyzingLabel.textAlignment = .center
        analyzingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(analyzingLabel)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = Theme.rose
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(spinner)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Extraindo mensagens com IA"
        subtitleLabel.textColor = Theme.textSecondary
        subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])
    }

    // MARK: - Step Label Helper

    private func makeStepLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = Theme.textSecondary
        label.font = UIFont.systemFont(ofSize: 11)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    // MARK: - Paste Screenshot Action

    @objc func pasteScreenshotTapped() {
        guard let image = UIPasteboard.general.image else {
            if let errorLabel = containerView.viewWithTag(8500) as? UILabel {
                errorLabel.text = "Nenhuma imagem copiada. Copie um print primeiro."
            }
            NSLog("[KB] pasteScreenshot: no image in clipboard")
            return
        }
        screenshotImage = image
        isAnalyzingScreenshot = true
        renderCurrentState()

        // Resize to max 1024px, compress JPEG 0.5
        let resized = resizeImage(image, maxDimension: 1024)
        guard let jpegData = resized.jpegData(compressionQuality: 0.5) else { return }
        let base64 = jpegData.base64EncodedString()

        analyzeScreenshot(base64, mediaType: "image/jpeg")
    }

    // MARK: - Resize Image

    func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }
}