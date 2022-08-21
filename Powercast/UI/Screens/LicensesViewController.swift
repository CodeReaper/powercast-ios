import UIKit

class LicensesViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var sections: [Section]!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.LICENSES_TITLE

        sections = [
            build(title: Translations.LICENSES_ASSETS_TITLE, urls: Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "assets") ?? []),
            build(title: Translations.LICENSES_PACKAGES_TITLE, urls: Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "packages") ?? [])
        ]

        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: Color.primary)
            .registerClass(Cell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }
    }

    private func build(title: String, urls: [URL]) -> Section {
        Section(
            title: title,
            rows: urls.compactMap { url in
                try? JSONDecoder().decode(Row.self, from: Data(contentsOf: url))
            }.sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
        )
    }

    private struct Section {
        let title: String
        let rows: [Row]
    }

    private struct Row: Codable {
        let name: String
        let content: String
    }

    private class Cell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension LicensesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath)
        cell.textLabel?.text = row.name
        return cell
    }
}

extension LicensesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = sections[indexPath.section].rows[indexPath.row]
        navigation.navigate(to: .license(title: row.name, content: row.content))
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }

        view.textLabel?.textColor = .white
    }
}
