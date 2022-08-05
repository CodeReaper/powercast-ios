import UIKit

class GraphView: UIView {
    private let canvas = UIView()

    private var plots: [CALayer] = []
    private var labels: [UILabel] = []

    private var panningPoint = CGPoint.zero
    private var offset = TimeInterval.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        canvas.clipsToBounds = true
        canvas.layer.masksToBounds = true
        canvas.setup(matching: self, in: self)

        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPanGraph)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - public

    var datasource = GraphView.Datasource.zero

    var delegate: GraphViewDelegate?

    var visibleDuration: TimeInterval = 0

    func center(on date: Date) {
        offset = max(0, datasource.dateInterval.end.timeIntervalSince1970 - date.timeIntervalSince1970 - (visibleDuration * 0.75))
    }

    func reload() {
        render()
    }

    // MARK: - lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        render()
    }

    // MARK: - events

    @objc private func didPanGraph(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panningPoint = gesture.location(in: self)
        case .changed, .ended:
            let point = gesture.location(in: self)
            gesture.setTranslation(.zero, in: self)
            offset = max(0, offset - (time(for: point) - time(for: panningPoint)))
            panningPoint = point
            render()
        default:
            break
        }
    }

    // MARK: - calculations

    private func pointY(for value: Double) -> CGFloat {
        CGFloat(canvas.bounds.height - canvas.bounds.height * ((value - datasource.minimumValue) / (datasource.maximumValue - datasource.minimumValue)))
    }

    private func pointX(for time: TimeInterval) -> CGFloat {
        canvas.bounds.width + CGFloat(time / visibleDuration) * canvas.bounds.width
    }

    private func pointX(for date: Date) -> CGFloat {
        pointX(for: date.timeIntervalSince1970 - (datasource.dateInterval.end.timeIntervalSince1970 - offset))
    }

    private func time(for point: CGPoint) -> TimeInterval {
        visibleDuration * TimeInterval(-point.x / canvas.bounds.width)
    }

    // MARK: - rendering

    private func render() {
        labels.forEach { $0.removeFromSuperview() }
        labels = []

        plots.forEach { $0.removeFromSuperlayer() }
        plots = []

        guard datasource.lineCount > 0 else { return }

        addLinePlots()

        addNowPlots()

        addGridPlots()

        addXLabels()

        addYLabels()

        for plot in plots {
            canvas.layer.addSublayer(plot)
        }

        delegate?.showing(time: datasource.dateInterval.end.timeIntervalSince1970 - offset - visibleDuration, in: datasource.dateInterval)
    }

    // MARK: - render helpers

    private func addYLabels() {
        let calendar = Calendar.current
        var pointer = datasource.dateInterval.start
        repeat {
            if let string = datasource.yLabelFormatter(pointer) {
                let label = Label(attributedString: string, color: .black)
                label.textAlignment = .center
                label.sizeToFit()
                label.layout(in: canvas) { make, its in
                    make(its.topAnchor.constraint(equalTo: canvas.topAnchor))
                    make(its.leadingAnchor.constraint(equalTo: canvas.leadingAnchor, constant: pointX(for: pointer) - (its.bounds.width / 2)))
                }
                labels.append(label)
            }

            pointer = calendar.date(byAdding: .hour, value: 1, to: pointer)!
        } while pointer < datasource.dateInterval.end
    }

    private func addXLabels() {
        for segment in datasource.xSegments {
            if let string = datasource.xLabelFormatter(segment) {
                let label = Label(attributedString: string, color: .black)
                label.sizeToFit()
                label.layout(in: canvas) { make, its in
                    make(its.leadingAnchor.constraint(equalTo: canvas.leadingAnchor, constant: 5))
                    make(its.topAnchor.constraint(equalTo: canvas.topAnchor, constant: pointY(for: segment) - (its.bounds.height / 2)))
                }
                labels.append(label)
            }
        }
    }

    private func addGridPlots() {
        var points: [(CGPoint, CGPoint)] = []

        let calendar = Calendar.current
        var pointer = datasource.dateInterval.start
        repeat {
            points.append((CGPoint(x: pointX(for: pointer), y: pointY(for: datasource.minimumValue)), CGPoint(x: pointX(for: pointer), y: pointY(for: datasource.maximumValue))))
            pointer = calendar.date(byAdding: .hour, value: 1, to: pointer)!
        } while pointer < datasource.dateInterval.end
        if let layer = lines(for: points, with: UIColor.black.withAlphaComponent(0.2)) {
            plots.append(layer)
        }

        points = datasource.xSegments.map {
            (CGPoint(x: pointX(for: datasource.dateInterval.start), y: pointY(for: $0)), CGPoint(x: pointX(for: datasource.dateInterval.end), y: pointY(for: $0)))
        }
        if let layer = lines(for: points, with: UIColor.black.withAlphaComponent(0.2)) {
            plots.append(layer)
        }
    }

    private func addNowPlots() {
        if let layer = lines(for: [(CGPoint(x: pointX(for: datasource.now), y: pointY(for: datasource.minimumValue)), CGPoint(x: pointX(for: datasource.now), y: pointY(for: datasource.maximumValue)))], with: UIColor.black) {
            plots.append(layer)
        }
    }

    private func addLinePlots() {
        for line in 0..<datasource.lineCount {
            let values = datasource.values(for: line)
            let color = datasource.color(for: line)

            let gap = datasource.expectedGap
            var segments: [[Item]] = []
            var segment: [Item] = []
            var last: Item?
            for value in values {
                if let previous = last {
                    if previous.timestamp.timeIntervalSince1970 - value.timestamp.timeIntervalSince1970 > gap {
                        segments.append(segment)
                        segment = [value]
                        last = nil
                    } else {
                        segment.append(value)
                    }
                } else {
                    segment.append(value)
                }
                last = value
            }
            segments.append(segment)

            for segment in segments {
                var datapoints: [CGPoint] = []
                for item in segment {
                    datapoints.append(CGPoint(x: pointX(for: item.timestamp), y: pointY(for: item.value)))
                }

                // MARK: debugging points
//                datapoints.map { point in
//                    let dot = CAShapeLayer()
//                    dot.path = UIBezierPath(rect: CGRect(origin: CGPoint(x: point.x - 2, y: point.y - 2), size: CGSize(width: 4, height: 4))).cgPath
//                    dot.fillColor = UIColor.clear.cgColor
//                    dot.strokeColor = color.cgColor
//                    dot.lineWidth = 1.0
//                    return dot
//                }.forEach { plots.append($0) }

                guard let layer = plot(datapoints, with: color) else { continue }
                plots.append(layer)
            }
        }
    }

    private func lines(for points: [(CGPoint, CGPoint)], with color: UIColor) -> CALayer? {
        let linePath = UIBezierPath()
        for (start, end) in points {
            linePath.move(to: start)
            linePath.addLine(to: end)
        }

        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = color.cgColor
        lineLayer.lineWidth = 1.0
        lineLayer.shadowColor = UIColor.black.cgColor
        lineLayer.shadowOffset = CGSize(width: 0, height: 8)
        lineLayer.shadowOpacity = 0.5
        lineLayer.shadowRadius = 6.0

        return lineLayer
    }

    private func plot(_ points: [CGPoint], with color: UIColor) -> CALayer? {
        guard points.count > 0 else { return nil }
        guard points.count > 1 else {
            guard let point = points.first else { return nil }
            let dot = CAShapeLayer()
            dot.path = UIBezierPath(arcCenter: point, radius: 3, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true).cgPath
            dot.fillColor = color.cgColor
            dot.strokeColor = UIColor.clear.cgColor
            dot.lineWidth = 0.0
            return dot
        }

        let linePath = UIBezierPath()
        linePath.addCurve(through: points.sorted(by: { $0.x < $1.x }))

        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = color.cgColor
        lineLayer.lineWidth = 1.0
        lineLayer.shadowColor = UIColor.black.cgColor
        lineLayer.shadowOffset = CGSize(width: 0, height: 8)
        lineLayer.shadowOpacity = 0.5
        lineLayer.shadowRadius = 6.0

        return lineLayer
    }

    // MARK: - structures

    struct Item {
        let value: Double
        let timestamp: Date
    }

    struct Datasource: GraphViewDatasource {
        let items: [[Item]]
        let colors: [UIColor]
        let expectedGap: TimeInterval
        let dateInterval: DateInterval
        let now: Date
        let minimumValue: Double
        let maximumValue: Double
        let xSegments: [Double]
        let xLabelFormatter: (Double) -> NSAttributedString?
        let yLabelFormatter: (Date) -> NSAttributedString?

        var lineCount: Int { items.count }

        func values(for line: Int) -> [Item] {
            items[line]
        }

        func shouldDraw(line: Int) -> Bool {
            items[line].count > 0
        }

        func color(for line: Int) -> UIColor {
            colors[line]
        }
    }
}

// MARK: -

extension GraphView.Datasource {
    static var zero = GraphView.Datasource(
        items: [],
        colors: [],
        expectedGap: 0,
        dateInterval: DateInterval(
            start: Date(timeIntervalSince1970: 0),
            duration: 0
        ),
        now: Date(timeIntervalSince1970: 0),
        minimumValue: 0,
        maximumValue: 0,
        xSegments: [],
        xLabelFormatter: { _ in nil },
        yLabelFormatter: { _ in nil }
    )
}

// MARK: -

protocol GraphViewDatasource {
    var expectedGap: TimeInterval { get }
    var dateInterval: DateInterval { get }
    var now: Date { get }

    var minimumValue: Double { get }
    var maximumValue: Double { get }
    var xSegments: [Double] { get }

    var xLabelFormatter: (Double) -> NSAttributedString? { get }
    var yLabelFormatter: (Date) -> NSAttributedString? { get }

    var lineCount: Int { get }
    func shouldDraw(line: Int) -> Bool
    func color(for line: Int) -> UIColor
    func values(for line: Int) -> [GraphView.Item]
}

protocol GraphViewDelegate: AnyObject {
    func showing(time: TimeInterval, in interval: DateInterval)
}
