import UIKit
import SugarKit

class MenuViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let menuWidth: CGFloat
    private let rows: [Row]

    private enum Row {
        case title
        case item(name: String, symbol: String, endpoint: Navigation)
        case version
    }

    init(navigation: AppNavigation, state: StateRepository) {
        self.rows = [
            Row.title,
            .item(name: Translations.DASHBOARD_TITLE, symbol: "square.3.stack.3d.middle.filled", endpoint: .dashboard),
            .item(name: Translations.NETWORK_DETAILS_TITLE, symbol: "poweroutlet.type.k.fill", endpoint: .networkDetails(network: state.network)),
            .item(name: Translations.GRID_DETAILS_TITLE, symbol: "bolt.fill", endpoint: .gridDetails(zone: state.network.zone)),
            .item(name: Translations.PRICE_ARCHIVE_TITLE, symbol: "archivebox.fill", endpoint: .priceArchive),
            .item(name: Translations.SETTINGS_TITLE, symbol: "gearshape", endpoint: .settings),
            .item(name: Translations.LICENSES_TITLE, symbol: "paragraphsign", endpoint: .licenses),
            .version
        ]

        if let font = ItemCell.label(with: "").font {
            menuWidth = rows.compactMap { row in
                switch row {
                case .title, .version: return nil
                case let .item(name, _, _): return name
                }
            }.map { (name: String) in
                return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: font]).size().width
            }.max() ?? CGFloat.greatestFiniteMagnitude
        } else {
            menuWidth = CGFloat.greatestFiniteMagnitude
        }

        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
            .registerClass(TitleCell.self)
            .registerClass(ItemCell.self)
            .registerClass(VersionCell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let inset = max((tableView.frame.height - tableView.contentSize.height) / 2.0, 0)
        tableView.contentInset = UIEdgeInsets(top: inset, left: 0.0, bottom: 0.0, right: 0.0)
    }

    private class TitleCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            backgroundColor = .tableBackground
            selectionStyle = .none

            ImageView(image: UIImage.powercastSplash, mode: .center).layout(in: contentView) { (make, its) in
                make(its.leadingAnchor.constraint(lessThanOrEqualTo: contentView.leadingAnchor))
                make(its.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: contentView.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20))
                make(its.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private class VersionCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            backgroundColor = .tableBackground
            selectionStyle = .none

            let versionLabel = Label(
                style: .body,
                attributedString: NSAttributedString(
                    string: Translations.VERSION_LABEL(Bundle.shortVersion, Bundle.version),
                    attributes: [NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 16, weight: .medium)]
                ),
                color: .secondaryLabel
            ).aligned(to: .center)

            let commitLabel = Label(
                style: .body,
                attributedString: NSAttributedString(
                    string: Translations.COMMIT_LABEL(Bundle.commit),
                    attributes: [NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 12, weight: .thin)]
                ),
                color: .secondaryLabel
            ).aligned(to: .center)

            Stack.views(
                on: .vertical,
                spacing: 4,
                versionLabel,
                commitLabel
            ).layout(in: contentView) { (make, its) in
                make(its.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: contentView.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20))
                make(its.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private class ItemCell: StackviewCell {
        func update(name: String, symbol: String, width: CGFloat) -> Self {
            backgroundColor = .tableBackground
            guard let image = UIImage(systemName: symbol) else { return self }

            let imageView = ImageView(image: image, mode: .center).set(width: 20).set(height: 20).updateContentHuggingPriority(.required, for: .horizontal)
            imageView.tintColor = .cellText

            views.spacing = 8
            views.addArrangedSubview(FlexibleSpace())
            views.addArrangedSubview(imageView)
            views.addArrangedSubview(Self.label(with: name).set(width: ceil(width)))
            views.addArrangedSubview(FlexibleSpace())
            _ = views.apply(flexible: .fillEqual)

            return self
        }

        static func label(with name: String) -> UILabel {
            Label(style: .body, text: name, color: .cellText)
        }
    }
}

extension MenuViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .title:
            return tableView.dequeueReusableCell(TitleCell.self, forIndexPath: indexPath)
        case .version:
            return tableView.dequeueReusableCell(VersionCell.self, forIndexPath: indexPath)
        case let .item(name, symbol, _):
            return tableView.dequeueReusableCell(ItemCell.self, forIndexPath: indexPath).update(name: name, symbol: symbol, width: menuWidth)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .title, .version: break
        case let .item(_, _, endpoint):
            navigate(to: endpoint)
        }
    }
}
