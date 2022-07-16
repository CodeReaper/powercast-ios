import UIKit

extension UIView {
    @discardableResult
    func setup(in superview: UIView, usingSafeLayout: Bool = true) -> Self {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        if usingSafeLayout {
            safeAreaLayoutGuide.widthAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.widthAnchor).isActive = true
            safeAreaLayoutGuide.heightAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.heightAnchor).isActive = true
            safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor).isActive = true
            safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerYAnchor).isActive = true
        } else {
            widthAnchor.constraint(equalTo: superview.widthAnchor).isActive = true
            heightAnchor.constraint(equalTo: superview.heightAnchor).isActive = true
            centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
            centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
        }
        return self
    }

    func setContentHugging(priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
        setContentHuggingPriority(priority, for: axis)
        return self
    }

    func setContentCompressionResistance(priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
        setContentCompressionResistancePriority(priority, for: axis)
        return self
    }
}
