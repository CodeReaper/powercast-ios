import UIKit
import SugarKit

class SettingsViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let state: StateRepository
    private let notifications: NotificationScheduler

    private var sections: [Section] = []

    init(navigation: AppNavigation, state: StateRepository, notifications: NotificationScheduler) {
        self.state = state
        self.notifications = notifications
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.SETTINGS_TITLE

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.showsVerticalScrollIndicator = false
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
            .registerClass(NavigationCell.self)
            .registerClass(MessageCell.self)
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
        sections = buildSettings()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        state.remove(observer: self)
    }

    private struct Section {
        let title: String
        let rows: [Row]
    }

    private enum Row {
        case navigate(label: String, detailLabel: String?, endpoint: Navigation)
        case notification
        case disabled
    }

    private class NavigationCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(title: String, label: String?) -> Self {
            textLabel?.text = title
            textLabel?.textColor = .cellText
            detailTextLabel?.text = label
            detailTextLabel?.textColor = .cellSecondaryText
            accessoryType = .disclosureIndicator
            return self
        }
    }

    private class MessageCell: StackviewCell {
        func update(with message: String) -> Self {
            views.addArrangedSubview(Label(text: message, color: .cellSecondaryText))
            return self
        }
    }
}

extension SettingsViewController: Observer {
    func updated() {
        DispatchQueue.main.async {
            self.sections = self.buildSettings()
            self.tableView.reloadData()
        }
    }

    private func matches(lhs: Row, rhs: Row) -> Bool {
        switch (lhs, rhs) {
        case (let .navigate(lhsLabel, lhsDetailLabel, _), let .navigate(rhsLabel, rhsDetailLabel, _)):
            return lhsLabel == rhsLabel && lhsDetailLabel == rhsDetailLabel
        case (.notification, .notification): return true
        case (.disabled, .disabled): return true
        default: return false
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
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
        switch sections[indexPath.section].rows[indexPath.row] {
        case let .navigate(label, detail, _):
            return tableView.dequeueReusableCell(NavigationCell.self, forIndexPath: indexPath).update(title: label, label: detail)
        case .notification:
            return tableView.dequeueReusableCell(NavigationCell.self, forIndexPath: indexPath).update(title: Translations.SETTINGS_NOTIFICATIONS_ADD_BUTTON, label: nil)
        case .disabled:
            return tableView.dequeueReusableCell(MessageCell.self, forIndexPath: indexPath).update(with: Translations.SETTINGS_NOTIFICATIONS_SYSTEM_DISABLED)
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section].rows[indexPath.row] {
        case let .navigate(_, _, endpoint):
            navigate(to: endpoint)
        case .notification:
            switch state.notificationStatus {
            case .authorized:
                navigate(to: .notification(notification: nil))
            case .notDetermined:
                notifications.request()
            default: return
            }
        case .disabled:
            return
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }

        view.textLabel?.textColor = .cellHeaderText
    }
}

extension SettingsViewController {
    private func buildSettings() -> [Section] {
        return [buildNetworkSettings(), buildSystemSettings(), buildNotificationSettings()]
    }

    private func buildNetworkSettings() -> Section {
        SettingsViewController.Section(
            title: Translations.SETTINGS_NETWORK_TITLE,
            rows: [
                .navigate(label: state.network.name, detailLabel: nil, endpoint: .networkSelection(forceSelection: true))
            ]
        )
    }

    private func buildSystemSettings() -> Section {
        SettingsViewController.Section(
            title: Translations.SETTINGS_SYSTEM_TITLE,
            rows: [
                .navigate(label: Translations.SETTINGS_SYSTEM_BACKGROUND_REFRESH, detailLabel: state.backgroundRefreshStatus.string, endpoint: .systemSettings),
                .navigate(label: Translations.SETTINGS_SYSTEM_NOTIFICATIONS, detailLabel: state.notificationStatus.string, endpoint: .systemSettings)
            ]
        )
    }

    private func buildNotificationSettings() -> Section {
        switch state.notificationStatus {
        case .authorized:
            let rows = state.notifications.map { notification in
                Row.navigate(label: notification.description, detailLabel: notification.action, endpoint: .notification(notification: notification))
            }
            return SettingsViewController.Section(
                title: Translations.SETTINGS_NOTIFICATIONS_TITLE,
                rows: rows + [.notification]
            )
        default:
            return SettingsViewController.Section(
                title: Translations.SETTINGS_NOTIFICATIONS_TITLE,
                rows: [.disabled]
            )
        }
    }
}

private extension UNAuthorizationStatus {
    var string: String {
        switch self {
        case .notDetermined:
            return Translations.SETTINGS_STATE_UNKNOWN
        case .authorized, .provisional, .ephemeral:
            return Translations.SETTINGS_STATE_ENABLED
        case .denied:
            fallthrough
        @unknown default:
            return Translations.SETTINGS_STATE_DISABLED
        }
    }
}

private extension UIBackgroundRefreshStatus {
    var string: String {
        switch self {
        case .available:
            return Translations.SETTINGS_STATE_ENABLED
        default:
            return Translations.SETTINGS_STATE_DISABLED
        }
    }
}
