import UIKit

class Label: UILabel {
    init(text string: String, color: UIColor = .black) {
        super.init(frame: .zero)
        text = string
        textColor = color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
