import UIKit
import SugarKit

class DashboardViewController: ViewController {
    private let spinnerView = SpinnerView(color: .spinner)
    private let spinnerMessage = MessageView(backgroundColor: .viewBackground, spinner: SpinnerView(color: .spinner))
    private let warningMessage = MessageView(backgroundColor: .warningBackground)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private var priceSource = EmptyPriceTableDatasource() as PriceTableDatasource
    private var emissionSource = EmptyEmissionTableDataSource() as EmissionTableDataSource
    private var now = Date()

    private var interactor: DashboardInteractor!

    init(navigation: AppNavigation, prices: EnergyPriceRepository, emission: EmissionRepository, notifications: NotificationScheduler, state: StateRepository) {
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

        spinnerMessage.set(hidden: true)
        warningMessage.set(hidden: true)

        tableView
            .registerClass(PriceHeaderView.self)
            .registerClass(PriceCell.self)
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
        tableView.refreshControl = refreshControl
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 100
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        refreshControl.tintColor = .tableRefreshControl
        refreshControl.attributedTitle = NSAttributedString(string: Translations.DASHBOARD_REFRESH_CONTROL_MESSAGE, attributes: [NSAttributedString.Key.foregroundColor: UIColor.tableRefreshControl])
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

        spinnerMessage.set(height: 33)
        warningMessage.set(height: 33)

        Stack
            .views(on: .vertical, tableView, spinnerMessage, warningMessage)
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
        refreshControl.endRefreshing()
    }
}

extension DashboardViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        priceSource.sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        priceSource.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let indexPath = IndexPath(item: 0, section: section)
        guard
            let price = priceSource.item(at: indexPath),
            let emission = emissionSource.item(at: indexPath)
        else { return nil }

        return tableView.dequeueReusableHeaderFooter(PriceHeaderView.self).update(using: price, and: emission, current: price.duration.contains(now))
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(PriceCell.self, forIndexPath: indexPath)

        guard
            let price = priceSource.item(at: indexPath),
            let emission = emissionSource.item(at: indexPath)
        else { return cell }

        return cell.update(using: price, and: emission, current: price.duration.contains(now), emissionRange: emissionSource.range)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let price = priceSource.item(at: indexPath) else { return }
        let emission = emissionSource.item(at: indexPath)

        navigate(to: .dataDetails(price: price, emission: emission))
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard let indexPath = priceSource.activeIndexPath(at: now) else { return true }

        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        return false
    }
}

extension DashboardViewController: DashboardDelegate {
    func show(priceData: PriceTableDatasource, emissionData: EmissionTableDataSource, updateOffset: Bool) {
        now = Date()
        priceSource = priceData
        emissionSource = emissionData
        tableView.reloadData()

        if let indexPath = priceSource.activeIndexPath(at: now), updateOffset {
            DispatchQueue.main.async { [tableView] in
                tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
            }
        }
    }

    func show(message: DashboardMessage) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .beginFromCurrentState, animations: { [warningMessage, spinnerMessage] in
            switch message {
            case .hidden:
                warningMessage.alpha = 0
                spinnerMessage.alpha = 0
            case .spinner(let message):
                warningMessage.alpha = 0
                spinnerMessage.alpha = 1
                spinnerMessage.label.text = message
                spinnerMessage.spinner?.startAnimating()
            case .warning(let message):
                spinnerMessage.alpha = 0
                warningMessage.alpha = 1
                warningMessage.label.text = message
            }
        }, completion: { [warningMessage, spinnerMessage] _ in
            switch message {
            case .hidden:
                warningMessage.isHidden = true
                spinnerMessage.isHidden = true
                spinnerMessage.spinner?.stopAnimating()
            case .spinner:
                warningMessage.isHidden = true
                spinnerMessage.isHidden = false
            case .warning:
                spinnerMessage.isHidden = true
                warningMessage.isHidden = false
            }
        })
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
}

extension DashboardViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
