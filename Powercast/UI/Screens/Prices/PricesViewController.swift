import UIKit

class PricesViewController: ViewController {
    private let spinnerView = SpinnerView(color: Color.primary)
    private let backgroundView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private var source = EmptyPriceTableDatasource() as PriceTableDatasource
    private var now = Date()

    private var interactor: PricesInteractor!

    init(navigation: AppNavigation, energyPriceRepository: EnergyPriceRepository, stateRepository: StateRepository) {
        super.init(navigation: navigation)

        interactor = PricesInteractor(delegate: self, energyPriceRepository: energyPriceRepository, stateRepository: stateRepository)
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

        spinnerView.setup(centeredIn: view)

        backgroundView.backgroundColor = .white
        backgroundView.setup(matching: view, in: view)
        view.sendSubviewToBack(backgroundView)

        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: Color.primary)
            .registerClass(Header.self)
            .registerClass(Cell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: bar.bottomAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }

        tableView.backgroundView = refreshControl
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        refreshControl.tintColor = .white
        refreshControl.attributedTitle = NSAttributedString(string: Translations.PRICES_REFRESH_CONTROL_MESSAGE, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)

        interactor.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        interactor.viewWillAppear()
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [interactor] _ in
            interactor?.viewWillAppear()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        interactor.viewWillDisappear()
    }

    @objc private func didTapMenu() {
        navigation.navigate(to: .menu)
    }

    @objc func didPullToRefresh() {
        interactor.refreshData()
    }

    private class Header: UITableViewHeaderFooterView {
        private static let dateFormatter = DateFormatter.with(dateStyle: .medium, timeStyle: .none)
        private static let numberFormatter = NumberFormatter.with(style: .decimal)

        private let dateLabel = Label(style: .body, color: .white)
        private let pricesLabel = Label(style: .body, color: .white)

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = Color.primary

            Stack.views(
                spacing: 10,
                inset: NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10),
                dateLabel,
                pricesLabel
            ).setup(in: contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(using model: Price) {
            dateLabel.text = Self.dateFormatter.string(from: model.duration.lowerBound)
            pricesLabel.text = Translations.PRICES_DAY_PRICE_SPAN(Self.numberFormatter.string(from: model.priceSpan.lowerBound as NSNumber)!, Self.numberFormatter.string(from: model.priceSpan.upperBound as NSNumber)!)
        }
    }

    private class Cell: UITableViewCell {
        private static let dateFormatter = DateFormatter.with(format: "HH")
        private static let numberFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 2)

        private let selectionIndicator = UIView()
        private let dateLabel = Label(color: .black)
        private let priceLabel = Label(color: .black)
        private let gaugeView = UIProgressView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = .white

            selectionIndicator
                .set(hidden: true)
                .set(backgroundColor: .black.withAlphaComponent(0.6))
                .layout(in: contentView) { (make, its) in
                    make(its.topAnchor.constraint(equalTo: contentView.topAnchor))
                    make(its.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
                    make(its.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
                    make(its.widthAnchor.constraint(equalToConstant: 4))
                }

            Stack.views(
                on: .vertical,
                inset: NSDirectionalEdgeInsets(top: 7, leading: 15, bottom: 5, trailing: 15),
                Stack.views(on: .horizontal, dateLabel, priceLabel),
                Stack.views(inset: NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0), gaugeView)
            ).layout(in: contentView) { (make, its) in
                make(its.topAnchor.constraint(equalTo: contentView.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
                make(its.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: contentView.trailingAnchor))
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            selectionIndicator.set(hidden: true)
            gaugeView.setProgress(0, animated: false)
            dateLabel.text = nil
            priceLabel.text = nil
        }

        func update(using model: Price, current: Bool) {
            contentView.backgroundColor = current ? .white : .black.withAlphaComponent(0.03)
            selectionIndicator.set(hidden: !current)

            let ratio = Float(model.price / model.priceSpan.upperBound)
            gaugeView.setProgress(ratio, animated: false)

            switch ratio {
            case 0..<0.99:
                gaugeView.tintColor = Color.primary
            default:
                gaugeView.tintColor = .red
            }

            dateLabel.text = Translations.PRICES_HOUR_TIME(Self.dateFormatter.string(from: model.duration.lowerBound), Self.dateFormatter.string(from: model.duration.upperBound))
            priceLabel.text = Translations.PRICES_HOUR_COST(Self.numberFormatter.string(from: model.price as NSNumber)!)
        }
    }
}

extension PricesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return source.sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let item = source.item(at: IndexPath(item: 0, section: section)) else { return nil }

        let view = tableView.dequeueReusableHeaderFooter(Header.self)
        view.update(using: item)
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath)

        guard let item = source.item(at: indexPath) else { return cell }

        cell.update(using: item, current: item.isActive(at: now))
        return cell
    }
}

extension PricesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PricesViewController: PricesDelegate {
    func show(data: PriceTableDatasource) {
        let applyOffset = data.isUpdated(comparedTo: source)
        now = Date()
        source = data
        tableView.reloadData()
        if let indexPath = source.activeIndexPath(at: now), applyOffset {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        }
    }

    func showNoData() {
        source = EmptyPriceTableDatasource()
        tableView.reloadData()
    }

    func showRefreshFailed() {
        // TODO: show refresh failure indicator
    }

    func show(loading: Bool) {
        if loading {
            spinnerView.startAnimating().isHidden = false
            tableView.isHidden = true
        } else {
            spinnerView.stopAnimating().isHidden = true
            tableView.isHidden = false
        }
    }

    func endRefreshing() {
        refreshControl.endRefreshing()
    }
}

extension PricesViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

private extension PriceTableDatasource {
    func isUpdated(comparedTo source: PriceTableDatasource) -> Bool {
        guard sectionCount == source.sectionCount else { return true }

        let section = sectionCount - 1
        guard section >= 0 else { return false }

        return numberOfRows(in: section) != source.numberOfRows(in: section)
    }
}
