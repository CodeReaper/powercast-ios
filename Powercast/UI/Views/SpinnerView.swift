import UIKit

class SpinnerView: UIActivityIndicatorView {
    init(color: UIColor = .white) {
        super.init(frame: .zero)
        self.color = color
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() -> Self {
        super.startAnimating()
        return self
    }

    func stopAnimating() -> Self {
        super.stopAnimating()
        return self
    }
}
