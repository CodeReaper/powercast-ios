import UIKit

extension UIView {
    @discardableResult
    func setup(in superview: UIView, usingSafeLayout: Bool = true) -> Self {
        return layout(in: superview) { make, its in
            if usingSafeLayout {
                make(its.widthAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.widthAnchor))
                make(its.heightAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.heightAnchor))
                make(its.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor))
                make(its.centerYAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerYAnchor))
            } else {
                make(its.widthAnchor.constraint(equalTo: superview.widthAnchor))
                make(its.heightAnchor.constraint(equalTo: superview.heightAnchor))
                make(its.centerXAnchor.constraint(equalTo: superview.centerXAnchor))
                make(its.centerYAnchor.constraint(equalTo: superview.centerYAnchor))
            }
        }
    }

    @discardableResult
    func setup(centeredIn superview: UIView, usingSafeLayout: Bool = true) -> Self {
        return layout(in: superview) { make, its in
            if usingSafeLayout {
                make(its.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor))
                make(its.centerYAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerYAnchor))
            } else {
                make(its.centerXAnchor.constraint(equalTo: superview.centerXAnchor))
                make(its.centerYAnchor.constraint(equalTo: superview.centerYAnchor))
            }
        }
    }

    @discardableResult
    func setup(under view: UIView, in superview: UIView) -> Self {
        return layout(in: superview) { make, its in
            make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            make(its.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor))
            make(its.leadingAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.leadingAnchor))
            make(its.trailingAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.trailingAnchor))
            make(its.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor))
        }
    }

    @discardableResult
    func setup(matching view: UIView, in superview: UIView, inset: NSDirectionalEdgeInsets = .zero) -> Self {
        return layout(in: superview) { make, its in
            make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: inset.top))
            make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: inset.leading))
            make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -inset.trailing))
            make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -inset.bottom))
        }
    }

    @discardableResult
    func set(width: CGFloat) -> Self {
        widthAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        return self
    }

    @discardableResult
    func set(height: CGFloat) -> Self {
        heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
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
