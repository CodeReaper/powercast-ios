import UIKit

class ImageView: UIImageView {
    init(image: UIImage, mode: ContentMode? = nil) {
        super.init(frame: .zero)
        self.image = image
        if let mode = mode {
            contentMode = mode
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
