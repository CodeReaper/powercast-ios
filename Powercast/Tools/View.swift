import UIKit

extension UIView {
    @discardableResult
    func set(backgroundColor color: UIColor) -> Self {
        backgroundColor = color
        return self
    }

    @discardableResult
    func set(hidden: Bool) -> Self {
        isHidden = hidden
        return self
    }
}
