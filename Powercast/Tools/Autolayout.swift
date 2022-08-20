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

    @discardableResult
    func setup(centeredIn superview: UIView, usingSafeLayout: Bool = true) -> Self {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        if usingSafeLayout {
            safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor).isActive = true
            safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerYAnchor).isActive = true
        } else {
            centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
            centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
        }
        return self
    }

    @discardableResult
    func setup(under view: UIView, in superview: UIView) -> Self {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        safeAreaLayoutGuide.leadingAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.leadingAnchor).isActive = true
        safeAreaLayoutGuide.trailingAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.trailingAnchor).isActive = true
        safeAreaLayoutGuide.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        return self
    }

    @discardableResult
    func setup(matching view: UIView, in superview: UIView, inset: NSDirectionalEdgeInsets = .zero) -> Self {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: inset.top).isActive = true
        safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: inset.leading).isActive = true
        safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -inset.trailing).isActive = true
        safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -inset.bottom).isActive = true
        return self
    }

    @discardableResult
    func set(width: CGFloat) -> Self {
        safeAreaLayoutGuide.widthAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        return self
    }

    @discardableResult
    func set(height: CGFloat) -> Self {
        safeAreaLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        return self
    }

    @discardableResult
    func layout(in superview: UIView, setup: ((NSLayoutConstraint) -> Void, UIView) -> Void) -> Self {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        setup({ $0.isActive = true }, self)
        return self
    }
}

extension NSLayoutConstraint {
    func set(priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}
