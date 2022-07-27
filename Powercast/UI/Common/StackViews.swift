import UIKit

struct Stack {
    static func views(aligned alignment: UIStackView.Alignment = .fill, on axis: NSLayoutConstraint.Axis = .horizontal, spacing: CGFloat = 0, inset: NSDirectionalEdgeInsets = .zero, _ arranged: UIView...) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arranged)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = inset
        stackView.distribution = .fill
        stackView.alignment = alignment
        stackView.axis = axis
        stackView.spacing = spacing
        return stackView
    }

    enum Flexible {
        case fillEqual
    }
}

class FlexibleSpace: UIView {
    init() {
        super.init(frame: .zero)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIStackView {
    func apply(flexible: Stack.Flexible) -> Self {
        let spacers = arrangedSubviews.filter { $0 is FlexibleSpace }
        for item in spacers {
            for constraint in spacers {
                if item === constraint { continue }
                item.widthAnchor.constraint(equalTo: constraint.widthAnchor).isActive = true
                item.heightAnchor.constraint(equalTo: constraint.heightAnchor).isActive = true
            }
        }
        return self
    }

    func fill() -> Self {
        switch axis {
        case .vertical:
            for item in arrangedSubviews {
                item.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor).set(priority: .defaultHigh).isActive = true
            }
        case .horizontal:
            for item in arrangedSubviews {
                item.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor).set(priority: .defaultHigh).isActive = true
            }
        @unknown default: break
        }
        return self
    }
}

extension UIView {
    func inset(_ inset: NSDirectionalEdgeInsets) -> UIStackView {
        return Stack.views(inset: inset, self)
    }
}

private extension NSLayoutConstraint {
    func set(priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}
