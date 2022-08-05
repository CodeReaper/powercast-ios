import UIKit

class DashboardViewController: ViewController {
    private let graphView = GraphView()
    private let spinnerView = SpinnerView(color: Color.primary)
    private let backgroundView = UIView()

    private var data: [Zone: [Date: EnergyPrice]] = [:]
    private var hasCentered = false

    private var interactor: DashboardInteractor!

    init(navigation: AppNavigation, repository: EnergyPriceRepository) {
        super.init(navigation: navigation)
        interactor = DashboardInteractor(delegate: self, repository: repository)
        graphView.delegate = self
        for zone in Zone.allCases {
            data[zone] = [:]
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.DASHBOARD_TITLE

        let item = UINavigationItem(title: Translations.DASHBOARD_TITLE)
        item.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.trailing"), style: .plain, target: self, action: #selector(didTapMenu))

        let bar = UINavigationBar()
        bar.isTranslucent = false
        bar.barTintColor = view.backgroundColor
        bar.shadowImage = UIImage()
        bar.delegate = self
        bar.items = [item]
        bar.layout(in: view) { make, its in
            make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            make(its.leadingAnchor.constraint(equalTo: view.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        }

        graphView.layout(in: view) { make, its in
            make(its.topAnchor.constraint(equalTo: bar.bottomAnchor))
            make(its.leadingAnchor.constraint(equalTo: view.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: view.trailingAnchor))
            make(its.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        }

        spinnerView.setup(centeredIn: view)

        backgroundView.backgroundColor = .white
        backgroundView.setup(matching: graphView, in: view)
        view.sendSubviewToBack(backgroundView)

        interactor.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        interactor.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        interactor.viewWillDisappear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configure(using: traitCollection)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        configure(using: newCollection)
    }

    @objc private func didTapMenu() {
        navigation.navigate(to: .menu)
    }

    private func configure(using collection: UITraitCollection) {
        switch (collection.userInterfaceIdiom, collection.horizontalSizeClass, collection.verticalSizeClass) {
        case (.phone, .compact, .regular):
            graphView.visibleDuration = .sixHours
        case (.phone, .regular, .compact):
            graphView.visibleDuration = .twelveHours
        case (.pad, _, _):
            if view.bounds.height > view.bounds.width {
                graphView.visibleDuration = .twelveHours
            } else {
                graphView.visibleDuration = .oneDay
            }
        default:
            graphView.visibleDuration = .sixHours
        }
    }
}

extension DashboardViewController: DashboardDelegate {
    func show(loading: Bool) {
        if loading {
            spinnerView.startAnimating().isHidden = false
            graphView.isHidden = true
        } else {
            spinnerView.stopAnimating().isHidden = true
            graphView.isHidden = false
        }
    }

    // swiftlint:disable:next function_body_length
    func show(items: [EnergyPrice]) {
        for item in items {
            data[item.zone]?[item.timestamp] = item
        }

        var startDate = Date.distantFuture
        var endDate = Date.distantPast
        var maximumValue = -Double.infinity
        var minimumValue = Double.infinity
        for zone in data.keys {
            for item in data[zone]!.values {
                startDate = min(startDate, item.timestamp)
                endDate = max(endDate, item.timestamp)
                maximumValue = max(item.price, maximumValue)
                minimumValue = min(item.price, minimumValue)
            }
        }

        let digits = floor(log(maximumValue - minimumValue) / log(10.0)) + 1
        let segmentSize = Double(pow(10, digits - 1))

        minimumValue -= segmentSize * 0.33
        maximumValue += segmentSize * 0.33

        let xSegments = stride(from: floor(minimumValue), to: ceil(maximumValue), by: 1).filter({ $0.truncatingRemainder(dividingBy: segmentSize) == 0 })

        let zones = data.keys.sorted(by: { $0.rawValue < $1.rawValue })

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.dateFormat = "HH"

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium

        let calendar = Calendar.current
        graphView.datasource = GraphView.Datasource(
            items: zones.map { data[$0]!.values.map { GraphView.Item(value: $0.price, timestamp: $0.timestamp) }.sorted(by: { $0.timestamp < $1.timestamp }) },
            colors: zones.map { $0.color },
            expectedGap: .oneHour,
            dateInterval: DateInterval(start: startDate, end: endDate),
            now: Date(),
            minimumValue: minimumValue,
            maximumValue: maximumValue,
            xSegments: xSegments,
            xLabelFormatter: { NSAttributedString(string: String(format: Translations.DASHBOARD_GRAPH_LABEL_FORMAT, $0), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: nil)]) },
            yLabelFormatter: { date in
                let midnight = calendar.component(.hour, from: calendar.startOfDay(for: date))
                let current = calendar.component(.hour, from: date)

                let string = NSMutableAttributedString()
                string.append(
                    NSAttributedString(string: timeFormatter.string(from: date), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: nil)])
                )
                if midnight == current {
                    string.append(
                        NSAttributedString(string: "\n")
                    )
                    string.append(
                        NSAttributedString(string: dateFormatter.string(from: date), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: nil)])
                    )
                }
                return string
            }
        )
        if !hasCentered {
            hasCentered = true
            graphView.center(on: graphView.datasource.now)
        }
        graphView.reload()
    }
}

extension DashboardViewController: GraphViewDelegate {
    func showing(time: TimeInterval, in interval: DateInterval) {
        interactor.showing(time: time, in: interval)
    }
}

extension DashboardViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
