import UIKit
import SugarKit

class DelaysViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let spinnerView = SpinnerView(color: .spinner)

    private let service: IncidentsService
    private let zone: Zone

    private var sections: [Section]?

    private struct Section {
        let date: String
        let rows: [Row]
    }

    private struct Row {
        let type: String
        let duration: String
        let startDate: String
        let endDate: String
    }

    init(navigation: AppNavigation, service: IncidentsService, zone: Zone) {
        self.service = service
        self.zone = zone

        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // FIXME: translations

        title = "Delays"

        spinnerView.setup(centeredIn: view)

        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
            .registerClass(Cell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }

        show(loading: true)
        fetchData()
    }

    private class Cell: StackviewCell {

        // FIXME: the view?

        func update(with row: Row) -> Self {
            backgroundColor = .tableBackground

            // style: .body, text: name, color: .menuLabel
            views.addArrangedSubview(Label(text: row.type, color: .black))
            views.addArrangedSubview(Label(text: row.duration, color: .black))
            views.addArrangedSubview(Label(text: row.startDate, color: .black))
            views.addArrangedSubview(Label(text: row.endDate, color: .black))

            views.spacing = 8
            _ = views.apply(flexible: .fillEqual)

            return self
        }
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

    private func update(prices: [Delay], and emissions: [Delay]) {
        show(loading: false)
        print("prices: \(prices)")
        print("emissions: \(emissions)")
        sections = [
            Section(date: "202804", rows: [
                Row(type: "TTTTT", duration: "daja ljga kjas", startDate: "safdsf", endDate: "asdfasdf")
            ])
        ]
        tableView.reloadData()
    }

    private func fetchData() {
        Task {
            async let pricesPromise = try? await service.delayedPrices(for: zone)
            async let emissionsPromise = try? await service.delayedEmissions(for: zone)
            async let minimumTime: ()? = try? await Task.sleep(seconds: 1)
            let (prices, emissions, _) = await (pricesPromise, emissionsPromise, minimumTime)
            if let prices = prices, let emissions = emissions {
                DispatchQueue.main.async { [update, prices, emissions] in
                    update(prices, emissions)
                }
            } else {
                DispatchQueue.main.async { [update] in
                    update([], []) // FIXME: empty state
                }
            }
        }
    }
}

extension DelaysViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = self.sections else { return 1 }
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.sections else { return 1 }
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sections = self.sections else { return tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath) }
        return tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath).update(with: sections[indexPath.section].rows[indexPath.row])
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections?[section].date
    }
}
