import UIKit

class Label: UILabel {
    init(style: UIFont.TextStyle = .body, text string: String, color: UIColor = .white) {
        super.init(frame: .zero)
        text = string
        textColor = color
        font = UIFont.preferredFont(forTextStyle: style)
        numberOfLines = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func aligned(to alignment: NSTextAlignment) -> Self {
        textAlignment = alignment
        return self
    }
}
