import UIKit

class ArchivesViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let sections: [Section]

    init(navigation: AppNavigation, state: StateRepository) {
        // FIXME: translations
        sections = [
            Section(title: "Pricingz", rows: [
                Row(name: Translations.NETWORK_DETAILS_TITLE, symbol: "poweroutlet.type.k.fill", endpoint: .networkDetails(network: state.network)),
                Row(name: Translations.GRID_DETAILS_TITLE, symbol: "bolt.fill", endpoint: .gridDetails(zone: state.network.zone)),
                Row(name: Translations.PRICE_ARCHIVE_TITLE, symbol: "archivebox.fill", endpoint: .priceArchive) // FIXME: money symbol
            ]),
            Section(title: "Incidentz", rows: [
                Row(name: "Delays", symbol: "archivebox.fill", endpoint: .delays) // FIXME: some symbol
            ])
        ]

        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // FIXME: translations

        title = "Archivez"

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
    }

    private struct Section {
        let title: String
        let rows: [Row]
    }

    private struct Row {
        let name: String
        let symbol: String
        let endpoint: Navigation
    }

    private class Cell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            backgroundColor = .cellBackground
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(name: String) -> Self {
            textLabel?.text = name
            textLabel?.textColor = .cellText
            textLabel?.numberOfLines = 0
            return self
        }
    }
}

extension ArchivesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath).update(name: sections[indexPath.section].rows[indexPath.row].name)
    }
}

extension ArchivesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = sections[indexPath.section].rows[indexPath.row]
        navigate(to: row.endpoint)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }

        view.textLabel?.textColor = .cellHeaderText
    }
}
