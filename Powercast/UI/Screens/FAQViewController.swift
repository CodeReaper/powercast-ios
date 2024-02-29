import UIKit

class FAQViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var sections: [Section]!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.FAQ_TITLE

        sections = [
            Section(title: Translations.FAQ_SECTION_APP_TITLE, rows: [
                Row(name: Translations.FAQ_SECTION_APP_REPORT_QUESTION, content: Translations.FAQ_SECTION_APP_REPORT_ANSWER),
                Row(name: Translations.FAQ_SECTION_APP_SUGGESTION_QUESTION, content: Translations.FAQ_SECTION_APP_SUGGESTION_ANSWER),
                Row(name: Translations.FAQ_SECTION_APP_ANDROID_QUESTION, content: Translations.FAQ_SECTION_APP_ANDROID_ANSWER)
            ]),
            Section(title: Translations.FAQ_SECTION_DATA_TITLE, rows: [
                Row(name: Translations.FAQ_SECTION_DATA_SOURCE_QUESTION, content: Translations.FAQ_SECTION_DATA_SOURCE_ANSWER),
                Row(name: Translations.FAQ_SECTION_DATA_CALCULATION_QUESTION, content: Translations.FAQ_SECTION_DATA_CALCULATION_ANSWER),
                Row(name: Translations.FAQ_SECTION_DATA_UPDATE_QUESTION, content: Translations.FAQ_SECTION_DATA_UPDATE_ANSWER)
            ])
        ]

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

    private struct Row: Codable {
        let name: String
        let content: String
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

extension FAQViewController: UITableViewDataSource {
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

extension FAQViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = sections[indexPath.section].rows[indexPath.row]
        navigate(to: .show(title: row.name, content: row.content))
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }

        view.textLabel?.textColor = .cellHeaderText
    }
}
