import UIKit
import Combine

class SettingsViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let repository: StateRepository

    private var sections: [Section]!

    private var stateSink: AnyCancellable?

    init(navigation: AppNavigation, repository: StateRepository, sections: [Section]? = nil) {
        self.repository = repository
        super.init(navigation: navigation)
        self.sections = sections ?? buildSettings(state: repository.state)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.SETTINGS_TITLE

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stateSink = repository.publishedState.receive(on: DispatchQueue.main).sink { [weak self, buildSettings] in
            self?.sections = buildSettings($0)
            self?.tableView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stateSink = nil
    }

    struct Section {
        let title: String
        let rows: [Row]
    }

    enum Row {
        case item(label: String, detailLabel: String, onSelection: (() -> Void)?)
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

extension SettingsViewController: UITableViewDataSource {
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
        switch sections[indexPath.section].rows[indexPath.row] {
        case let .item(label, detail, endpoint):
            let cell = tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath)
            cell.textLabel?.text = label
            cell.detailTextLabel?.text = detail
            cell.accessoryType = endpoint == nil ? .none : .disclosureIndicator
            return cell
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section].rows[indexPath.row] {
        case let .item(_, _, onSelection):
            onSelection?()
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }

        view.textLabel?.textColor = .white
    }
}

extension SettingsViewController {
    func buildSettings(state: State) -> [Section] {
        return [
            SettingsViewController.Section(title: Translations.SETTINGS_ZONE_TITLE, rows: [
                .item(label: Translations.SETTINGS_ZONE_ZONE_TITLE, detailLabel: state.selectedZone.name, onSelection: { [navigation] in
                    navigation.navigate(to: .regionSelection(configuration: ZoneSelectionViewController.Configuration(behavior: .pop)))
                })
            ])
        ]
    }
}
