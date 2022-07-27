import UIKit

class Button: UIButton {
    init(text: String, textColor: UIColor = .white, target: Any? = nil, action: Selector? = nil) {
        super.init(frame: .zero)
        setTitle(text, for: .normal)
        setTitleColor(textColor, for: .normal)
        if let action = action {
            addTarget(target, action: action, for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RoundedButton: Button {
    init(text: String, textColor: UIColor = .black, backgroundColor: UIColor = .white, target: Any? = nil, action: Selector? = nil) {
        super.init(text: text, textColor: textColor, target: target, action: action)
        self.backgroundColor = backgroundColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.height, bounds.width) / 3.0
    }
}
