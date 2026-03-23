import UIKit

// MARK: - GradientView (auto-sizing gradient for Auto Layout)
class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let g = layer as? CAGradientLayer else { return }
        g.colors = [
            UIColor(red: 1.0, green: 0.294, blue: 0.169, alpha: 1.0).cgColor,  // #FF4B2B
            UIColor(red: 1.0, green: 0.565, blue: 0.129, alpha: 1.0).cgColor,  // #FF9021
            UIColor(red: 0.847, green: 0.188, blue: 0.627, alpha: 1.0).cgColor, // #D830A0
            UIColor(red: 0.478, green: 0.161, blue: 0.753, alpha: 1.0).cgColor, // #7A29C0
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
    }

    required init?(coder: NSCoder) { fatalError() }
}
