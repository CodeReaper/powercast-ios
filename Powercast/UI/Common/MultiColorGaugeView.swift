import UIKit

class MultiColorGaugeView: UIView {
    var values: [(value: CGFloat, color: UIColor)] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let height = rect.height

        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: height))
        context.setFillColor(tintColor.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()

        var startX: CGFloat = 0
        for (widthPercentage, color) in values {
            let width = rect.width * widthPercentage
            let path = UIBezierPath(rect: CGRect(x: startX, y: 0, width: width, height: height))

            context.setFillColor(color.cgColor)
            context.addPath(path.cgPath)
            context.fillPath()

            startX += width
        }
    }
}
