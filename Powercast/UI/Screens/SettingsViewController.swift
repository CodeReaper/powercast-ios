import UIKit
import SugarKit
import Combine

class SettingsViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let state: StateRepository

//    private var toggles: [Message.Kind: UISwitch] = [:]

    private var sections: [Section] = []

    init(navigation: AppNavigation, state: StateRepository, sections: [Section]? = nil) {
        self.state = state
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.SETTINGS_TITLE
        navigationController?.navigationBar.shadowImage = UIImage()

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.showsVerticalScrollIndicator = false
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
            .registerClass(NavigationCell.self)
            .registerClass(ToggleCell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }

//        for kind in Message.Kind.allCases {
//            let view = UISwitch(frame: .zero)
//            view.onTintColor = .toggleTint
//            view.isOn = state.notifications(for: kind)
//            toggles[kind] = view
//        }
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

    struct Section {
        let title: String
        let rows: [Row]
    }

    enum Row {
        case navigate(label: String, detailLabel: String?, endpoint: Navigation)
//        case toggle(kind: Message.Kind)
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

    private class ToggleCell: UITableViewCell {
        private let views = Stack.views(on: .horizontal, inset: NSDirectionalEdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            views.layout(in: contentView) { make, its in
                make(its.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor))
                make(its.heightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.heightAnchor))
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            views.arrangedSubviews.forEach {
                views.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }

        func update(title: String, with view: UISwitch) -> Self {
            views.addArrangedSubview(Stack.views(on: .vertical, spacing: 3, Label(style: .body, text: title, color: .cellText)))
            views.addArrangedSubview(Stack.views(on: .vertical, view, FlexibleSpace()))
            return self
        }
    }
}

extension SettingsViewController: Observer {
    func updated() {
        DispatchQueue.main.async {
            let sections = self.buildSettings()
            let changes: [IndexPath] = zip(sections, self.sections).enumerated().flatMap { (section: Int, sections: (Section, Section)) -> [IndexPath] in
                return zip(sections.0.rows, sections.1.rows).enumerated().compactMap { (row: Int, rows: (Row, Row)) -> IndexPath? in
                    if self.matches(lhs: rows.0, rhs: rows.1) {
                        return nil
                    } else {
                        return IndexPath(row: row, section: section)
                    }
                }
            }
            self.sections = sections
            self.tableView.reloadRows(at: changes, with: .automatic)
        }
    }

    private func matches(lhs: Row, rhs: Row) -> Bool {
        switch (lhs, rhs) {
        case (let .navigate(lhsLabel, lhsDetailLabel, _), let .navigate(rhsLabel, rhsDetailLabel, _)):
            return lhsLabel == rhsLabel && lhsDetailLabel == rhsDetailLabel
//        case (let .toggle(lhsKind), let .toggle(rhsKind)):
//            return lhsKind == rhsKind
        default:
            return false
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
//        case let .toggle(kind):
//            return tableView.dequeueReusableCell(ToggleCell.self, forIndexPath: indexPath).update(title: kind.string, with: toggles[kind]!)
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section].rows[indexPath.row] {
        case let .navigate(_, _, endpoint):
            navigate(to: endpoint)
//        case let .toggle(kind):
//            state.notifications(enabled: !state.notifications(for: kind), for: kind)
//            toggles[kind]?.setOn(state.notifications(for: kind), animated: true)
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }

        view.textLabel?.textColor = .cellHeaderText
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
        SettingsViewController.Section(
            title: Translations.SETTINGS_NOTIFICATIONS_TITLE,
            rows: [] // Message.Kind.allCases.map { Row.toggle(kind: $0) }
        )
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

//private extension Message.Kind {
//    var string: String {
//        switch self {
//        case .night:
//            return Translations.SETTINGS_NOTIFICATIONS_ITEM_NIGHT
//        case .morning:
//            return Translations.SETTINGS_NOTIFICATIONS_ITEM_MORNING
//        case .afternoon:
//            return Translations.SETTINGS_NOTIFICATIONS_ITEM_AFTERNOON
//        case .evening:
//            return Translations.SETTINGS_NOTIFICATIONS_ITEM_EVENING
//        case .free:
//            return Translations.SETTINGS_NOTIFICATIONS_ITEM_FREE
//        }
//    }
//}
