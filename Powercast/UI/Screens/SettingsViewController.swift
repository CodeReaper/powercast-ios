import UIKit
import SugarKit
import Combine

class SettingsViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let state: StateRepository

    private var sections: [Section]!

    init(navigation: AppNavigation, repository: StateRepository, sections: [Section]? = nil) {
        self.state = repository
        super.init(navigation: navigation)
        self.sections = sections ?? buildSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.SETTINGS_TITLE
        navigationController?.navigationBar.shadowImage = UIImage()

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
        state.add(observer: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        state.remove(observer: self)
        super.viewWillDisappear(animated)
    }

    struct Section {
        let title: String
        let rows: [Row]
    }

    enum Row {
        case item(label: String, detailLabel: String?, onSelection: (() -> Void)?)
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

extension SettingsViewController: Observer {
    func updated() {
        DispatchQueue.main.async {
            self.sections = self.buildSettings()
            self.tableView.reloadData()
        }
    }
}

extension SettingsViewController {
    func buildSettings() -> [Section] {
        return [buildNetworkSettings(), buildSystemSettings(), buildNotificationSettings()]
    }

    private func buildNetworkSettings() -> Section {
        SettingsViewController.Section(
            title: Translations.SETTINGS_NETWORK_TITLE,
            rows: [
                .item(label: state.network.name, detailLabel: nil, onSelection: { [navigation] in
                    navigation.navigate(to: .networkSelection)
                })
            ]
        )
    }

    private func buildSystemSettings() -> Section { // FIXME: translations
        SettingsViewController.Section(
            title: "System Settings",
            rows: [
                .item(label: "Background Refresh", detailLabel: state.backgroundRefreshStatus.string, onSelection: {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }),
                .item(label: "Notifications", detailLabel: state.notificationStatus.string, onSelection: {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                })
            ]
        )
    }

    private func buildNotificationSettings() -> Section { // FIXME: translations
        SettingsViewController.Section(
            title: "Notifications",
            rows: Message.Kind.allCases.map { kind in
                return Row.item(label: kind.string, detailLabel: state.notifications(for: kind) ? "Enabled" : "Disabled", onSelection: { [state] in
                    state.notifications(enabled: !state.notifications(for: kind), for: kind)
                })
            }
        )
    }
}

private extension UNAuthorizationStatus {
    var string: String {
        switch self {
        case .notDetermined:
            return "Unknown"
        case .authorized, .provisional, .ephemeral:
            return "Enabled"
        case .denied:
            fallthrough
        @unknown default:
            return "Disabled"
        }
    }
}

private extension UIBackgroundRefreshStatus {
    var string: String {
        switch self {
        case .available:
            return "Enabled"
        default:
            return "Disabled"
        }
    }
}

private extension Message.Kind {
    var string: String {
        switch self {
        case .night:
            return "0 - 6"
        case .morning:
            return "6 - 12"
        case .afternoon:
            return "12 - 18"
        case .evening:
            return "18 - 24"
        case .free:
            return "Free"
        case .lessThanFees:
            return "Less than fees"
        }
    }
}
