import UIKit

// MARK: - GradientView (auto-sizing gradient for Auto Layout)
class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let g = layer as? CAGradientLayer else { return }
        g.colors = [
            UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0).cgColor,
            UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.18, blue: 0.74, alpha: 1.0).cgColor,
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
    }

    required init?(coder: NSCoder) { fatalError() }
}
