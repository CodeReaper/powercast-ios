import UIKit
import SugarKit

class DashboardViewController: ViewController {
    private let spinnerView = SpinnerView(color: Color.primary)
    private let updateFailedLabel = Label(style: .subheadline, text: Translations.DASHBOARD_REFRESH_FAILED_MESSAGE, color: .white)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private var priceSource = EmptyPriceTableDatasource() as PriceTableDatasource
    private var emissionSource = EmptyEmissionTableDataSource() as EmissionTableDataSource
    private var now = Date()

    private var interactor: DashboardInteractor!

    init(navigation: AppNavigation, prices: EnergyPriceRepository, emission: EmissionRepository, notifications: NotificationRepository, state: StateRepository) {
        super.init(navigation: navigation)
        interactor = DashboardInteractor(delegate: self, prices: prices, emission: emission, notifications: notifications, state: state)
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

        updateFailedLabel.textAlignment = .center
        updateFailedLabel
            .set(backgroundColor: Color.pastelRed)
            .set(hidden: true)

        tableView
            .registerClass(Header.self)
            .registerClass(PriceCell.self)
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
        refreshControl.attributedTitle = NSAttributedString(string: Translations.DASHBOARD_REFRESH_CONTROL_MESSAGE, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
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
        private static let numberFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)

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

        func update(using price: Price) {
            dateLabel.text = Self.dateFormatter.string(from: price.duration.lowerBound)
            pricesLabel.text = Translations.DASHBOARD_DAY_PRICE_SPAN(Self.numberFormatter.string(with: price.priceSpan.lowerBound), Self.numberFormatter.string(with: price.priceSpan.upperBound))
        }
    }
}

extension DashboardViewController: UITableViewDataSource {
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
        view.update(using: price)
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(PriceCell.self, forIndexPath: indexPath)

        guard let price = priceSource.item(at: indexPath) else { return cell }

        return cell.update(using: price, and: emissionSource.item(at: indexPath), current: price.duration.contains(now))
    }
}

extension DashboardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let price = priceSource.item(at: indexPath) else { return }
        let emission = emissionSource.item(at: indexPath)

        navigate(to: .dataDetails(price: price, emission: emission))
    }
}

extension DashboardViewController: DashboardDelegate {
    func show(priceData: PriceTableDatasource, emissionData: EmissionTableDataSource) {
        updateFailedLabel.set(hidden: true)
        let applyOffset = priceData.isUpdated(comparedTo: priceSource)
        now = Date()
        priceSource = priceData
        emissionSource = emissionData
        tableView.reloadData()
        if let indexPath = priceSource.activeIndexPath(at: now), applyOffset {
            DispatchQueue.main.async { [tableView] in
                tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
            }
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

extension DashboardViewController: UINavigationBarDelegate {
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
