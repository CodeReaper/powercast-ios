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

class MenuButton: Button {
    init(symbolName: String, text: String, textColor: UIColor = .white, target: Any? = nil, action: Selector? = nil) {
        super.init(text: text, textColor: textColor, target: target, action: action)
        titleLabel?.textAlignment = .left
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
        let image = UIImage(systemName: symbolName)
        for state in [UIControl.State.normal, .highlighted, .selected] {
            setImage(image, for: state)
        }
        tintColor = textColor
        if let action = action {
            addTarget(target, action: action, for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
