import UIKit
import SugarKit

class MessageView: UIView {
    let spinner: UIActivityIndicatorView?
    let label: UILabel

    init(backgroundColor: UIColor, label: UILabel = Label(style: .subheadline, color: .warningText), spinner: UIActivityIndicatorView? = nil) {
        self.spinner = spinner
        self.label = label

        label.textAlignment = .center

        super.init(frame: .zero)

        self.backgroundColor = backgroundColor

        let stack = Stack.views(spacing: 8, FlexibleSpace())
        if let spinner = spinner {
            stack.addArrangedSubview(spinner)
        }
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(FlexibleSpace())
        addSubview(stack.apply(flexible: .fillEqual))

        stack.layout(in: self) { (make, its) in
            make(its.topAnchor.constraint(equalTo: topAnchor))
            make(its.bottomAnchor.constraint(equalTo: bottomAnchor))
            make(its.leadingAnchor.constraint(equalTo: leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: trailingAnchor))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
