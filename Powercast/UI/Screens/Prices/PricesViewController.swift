import UIKit
import SugarKit

class PricesViewController: ViewController {
    private let spinnerView = SpinnerView(color: Color.primary)
    private let updateFailedLabel = Label(style: .subheadline, text: Translations.PRICES_REFRESH_FAILED_MESSAGE, color: .white)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let formatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)

    private var priceSource = EmptyPriceTableDatasource() as PriceTableDatasource
    private var emissionSource = EmptyEmissionTableDataSource() as EmissionTableDataSource
    private var now = Date()

    private var interactor: PricesInteractor!

    init(navigation: AppNavigation, prices: EnergyPriceRepository, emission: EmissionRepository, notifications: NotificationRepository, state: StateRepository) {
        super.init(navigation: navigation)
        interactor = PricesInteractor(delegate: self, prices: prices, emission: emission, notifications: notifications, state: state)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.PRICES_TITLE

        let item = UINavigationItem(title: Translations.PRICES_TITLE)
        item.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.trailing"), style: .plain, target: self, action: #selector(didTapMenu))

        let bar = UINavigationBar()
        bar.isTranslucent = false
        bar.barTintColor = view.backgroundColor
        bar.shadowImage = UIImage()
        bar.delegate = self
        bar.items = [item]

        updateFailedLabel.textAlignment = .center
        updateFailedLabel
            .set(backgroundColor: Color.pastelRed)
            .set(hidden: true)

        tableView
            .registerClass(Header.self)
            .registerClass(Cell.self)
            .set(datasource: self, delegate: self)
            .set(backgroundColor: Color.primary)
        tableView.refreshControl = refreshControl
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        refreshControl.tintColor = .white
        refreshControl.attributedTitle = NSAttributedString(string: Translations.PRICES_REFRESH_CONTROL_MESSAGE, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)

        layout(with: bar)

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

    private func layout(with bar: UINavigationBar) {
        bar.layout(in: view) { make, its in
            make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            make(its.leadingAnchor.constraint(equalTo: view.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        }

        spinnerView.setup(centeredIn: view)

        updateFailedLabel.set(height: 33)

        Stack
            .views(on: .vertical, tableView, updateFailedLabel)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: bar.bottomAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }
    }

    @objc private func didTapMenu() {
        navigate(to: .menu)
    }

    @objc func didPullToRefresh() {
        interactor.refreshData()
    }

    private class Header: UITableViewHeaderFooterView {
        private static let dateFormatter = DateFormatter.with(dateStyle: .medium, timeStyle: .none)

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

        func update(using price: Price, with formatter: NumberFormatter) {
            dateLabel.text = Self.dateFormatter.string(from: price.duration.lowerBound)
            pricesLabel.text = Translations.PRICES_DAY_PRICE_SPAN(formatter.string(with: price.priceSpan.lowerBound), formatter.string(with: price.priceSpan.upperBound))
        }
    }

    private class Cell: UITableViewCell {
        private static let dateFormatter = DateFormatter.with(format: "HH")

        private let selectionIndicator = UIView()
        private let dateLabel = Label(color: .black)
        private let priceLabel = Label(color: .black)
        private let emissionLabel = Label(color: .black)
        private let priceTitleLabel = Label(text: "Price", color: .darkGray)
        private let emissionTitleLabel = Label(text: "Co2", color: .darkGray)
        private let priceGaugeView = MultiColorGaugeView()
        private let emissionGaugeView = MultiColorGaugeView()

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

            for view in [priceGaugeView, emissionGaugeView] {
                view.set(height: 5)
                view.layer.cornerRadius = 2.5
                view.clipsToBounds = true
            }
            Stack.views(
                on: .vertical,
                inset: NSDirectionalEdgeInsets(top: 7, leading: 15, bottom: 5, trailing: 15),
                dateLabel,
                Stack.views(
                    on: .vertical,
                    spacing: 5,
                    inset: NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0),
                    Stack.views(on: .horizontal, priceTitleLabel, priceLabel),
                    priceGaugeView
                ),
                Stack.views(
                    on: .vertical,
                    spacing: 5,
                    inset: NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0),
                    Stack.views(on: .horizontal, emissionTitleLabel, emissionLabel),
                    emissionGaugeView
                )
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
            priceGaugeView.values = []
            emissionGaugeView.values = []
            dateLabel.text = nil
            priceLabel.text = nil
            emissionLabel.text = nil
        }

        func update(using price: Price, and emission: Emission.Co2, with formatter: NumberFormatter, current: Bool) {
            contentView.backgroundColor = current ? .white : .black.withAlphaComponent(0.03)
            selectionIndicator.set(hidden: !current)

            let ratio = (price.price - price.fees) / price.priceSpan.upperBound
            priceGaugeView.values = [
                (price.fixedFees / price.priceSpan.upperBound, Color.fixedFeeColor),
                (price.variableFees / price.priceSpan.upperBound, Color.variableFeeColor),
                (ratio, Color.priceColor.withAlphaComponent(ratio > 0 ? 1 : 0))
            ]

            let space = emission.amount.lowerBound / emission.amountSpan.upperBound
            emissionGaugeView.values = [
                (space, emissionGaugeView.tintColor),
                ((emission.amount.upperBound / emission.amountSpan.upperBound) - space, Color.emissionColor)
            ]

            dateLabel.text = Translations.PRICES_HOUR_TIME(Self.dateFormatter.string(from: price.duration.lowerBound), Self.dateFormatter.string(from: price.duration.upperBound))
            priceLabel.text = Translations.PRICES_HOUR_COST(formatter.string(with: price.price))
            emissionLabel.text = "\(formatter.string(with: emission.amount.lowerBound)) - \(formatter.string(with: emission.amount.upperBound)) g/kWh" // FIXME: t
        }
    }
}

extension PricesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return priceSource.sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priceSource.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard
            let price = priceSource.item(at: IndexPath(item: 0, section: section))
        else { return nil }

        let view = tableView.dequeueReusableHeaderFooter(Header.self)
        view.update(using: price, with: formatter)
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath)

        guard let price = priceSource.item(at: indexPath) else { return cell }
        guard let emission = emissionSource.item(at: indexPath) else { return cell }

        cell.update(using: price, and: emission, with: formatter, current: price.isActive(at: now))
        return cell
    }
}

extension PricesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PricesViewController: PricesDelegate {
    func show(priceData: PriceTableDatasource, emissionData: EmissionTableDataSource) {
        updateFailedLabel.set(hidden: true)
        let applyOffset = priceData.isUpdated(comparedTo: priceSource)
        now = Date()
        priceSource = priceData
        emissionSource = emissionData
        tableView.reloadData()
        if let indexPath = priceSource.activeIndexPath(at: now), applyOffset {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        }
    }

    func showNoData() {
        updateFailedLabel.set(hidden: true)
        priceSource = EmptyPriceTableDatasource()
        emissionSource = EmptyEmissionTableDataSource()
        tableView.reloadData()
    }

    func showRefreshFailed() {
        updateFailedLabel.set(hidden: false)
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

private extension NumberFormatter {
    func string(with value: Double) -> String {
        return string(from: value as NSNumber)!
    }
}
