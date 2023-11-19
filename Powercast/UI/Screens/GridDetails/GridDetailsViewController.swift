import UIKit
import SugarKit

class GridDetailsViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let now = Date()
    private let formatter = NumberFormatter.with(style: .decimal, fractionDigits: 2)

    private let zone: Zone
    private let items: [GridPrice]

    init(navigation: AppNavigation, zone: Zone, charges: ChargesRepository) {
        let items = try? charges.gridPrices(by: zone)
        self.zone = zone
        self.items = items ?? []
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = zone.name

        navigationController?.navigationBar.shadowImage = UIImage()

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.allowsSelection = false
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: Color.primary)
            .registerClass(Header.self)
            .registerClass(Cell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }
    }

    private class Header: UITableViewHeaderFooterView {
        private static let dateFormatter = DateFormatter.with(dateStyle: .medium, timeStyle: .none)

        private let validFromLabel = Label(style: .body, color: .white).aligned(to: .left)
        private let validToLabel = Label(style: .body, color: .white).aligned(to: .right)

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = Color.primary

            Stack.views(
                on: .horizontal,
                spacing: 10,
                inset: NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10),
                validFromLabel,
                validToLabel
            ).setup(in: contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(using price: GridPrice) -> Self {
            validFromLabel.text = Self.dateFormatter.string(from: price.validFrom)
            if let validTo = price.validTo {
                validToLabel.text = Self.dateFormatter.string(from: validTo)
            } else {
                validToLabel.text = Translations.NETWORK_DETAILS_UNSPECIFICED_END
            }
            return self
        }
    }

    private class Cell: UITableViewCell {
        private let selectionIndicator = UIView()
        private let systemLabel = Label(color: .black).aligned(to: .right)
        private let chargeLabel = Label(color: .black).aligned(to: .right)
        private let transmissionLabel = Label(color: .black).aligned(to: .right)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

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
                spacing: 6,
                inset: NSDirectionalEdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15),
                Stack.views(on: .horizontal, Label(text: Translations.GRID_DETAILS_SYSTEM_LABEL, color: .black), Stack.views(on: .horizontal, spacing: 5, systemLabel, Label(text: Translations.GRID_DETAILS_UNIT, color: .black))),
                Stack.views(on: .horizontal, Label(text: Translations.GRID_DETAILS_TRANSMISSION_LABEL, color: .black), Stack.views(on: .horizontal, spacing: 5, transmissionLabel, Label(text: Translations.GRID_DETAILS_UNIT, color: .black))),
                Stack.views(on: .horizontal, Label(text: Translations.GRID_DETAILS_CHARGE_LABEL, color: .black), Stack.views(on: .horizontal, spacing: 5, chargeLabel, Label(text: Translations.GRID_DETAILS_UNIT, color: .black)))
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
            for item in [systemLabel, transmissionLabel, chargeLabel] {
                item.text = nil
            }
        }

        func update(with price: GridPrice, and formatter: NumberFormatter, current: Bool) -> Self {
            contentView.backgroundColor = current ? .white : Color.offWhite
            selectionIndicator.set(hidden: !current)
            systemLabel.text = formatter.string(with: price.systemTariff)
            transmissionLabel.text = formatter.string(with: price.transmissionTariff)
            chargeLabel.text = formatter.string(with: price.electricityCharge)
            return self
        }
    }
}

extension GridDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section]
        let interval = DateInterval(start: item.validFrom, end: item.validTo ?? Date.distantFuture)
        return tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath).update(with: item, and: formatter, current: interval.contains(now))
    }
}

extension GridDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard items.count > section else { return nil }
        return tableView.dequeueReusableHeaderFooter(Header.self).update(using: items[section])
    }
}
