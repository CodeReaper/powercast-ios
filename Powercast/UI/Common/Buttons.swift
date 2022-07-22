import UIKit

class Button: UIButton {
    init(text: String, target: Any? = nil, action: Selector? = nil) {
        super.init(frame: .zero)
        setTitle(text, for: .normal)
        setTitleColor(.black, for: .normal)
        if let action = action {
            addTarget(target, action: action, for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
