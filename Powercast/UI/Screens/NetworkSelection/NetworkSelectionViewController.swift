import UIKit
import SugarKit

class NetworkSelectionViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let helpURL = URL(string: "https://greenpowerdenmark.dk/vejledning-teknik/nettilslutning/find-netselskab")!
    private let zones = [Zone.dk2, .dk1]
    private let items: [[Network]]

    init(navigation: AppNavigation, networks: [Network]) {
        self.items = zones.map { zone in
            networks.filter({ $0.zone == zone }).sorted(by: { $0.name < $1.name })
        }
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: handle error case with zero networks

        title = Translations.NETWORK_SELECTION_TITLE

        navigationController?.navigationBar.shadowImage = UIImage()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: self, action: #selector(didTapHelp))

        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: Color.primary)
            .registerClass(Cell.self)
            .registerClass(Header.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }
    }

    @objc private func didTapHelp() {
        let options = [
            ActionSheetOption.title(text: Translations.NETWORK_SELECTION_HELP_TITLE),
            .message(text: Translations.NETWORK_SELECTION_HELP_MESSAGE),
            .button(text: Translations.NETWORK_SELECTION_HELP_BUTTON_POSITIVE, action: { [helpURL] _ in
                UIApplication.shared.open(helpURL)
            }),
            .cancel(text: Translations.NETWORK_SELECTION_HELP_BUTTON_NEGATIVE, action: nil)
        ]
        navigate(to: .actionSheet(options: options))
    }

    private class Header: UITableViewHeaderFooterView {
        private let label = Label(style: .body, color: .white)
        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = Color.primary

            Stack.views(
                spacing: 10,
                inset: NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10),
                label
            ).setup(in: contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(with zone: Zone) -> Self {
            switch zone {
            case .dk1: label.text = Translations.NETWORK_SELECTION_DK1_ZIP_LIST
            case .dk2: label.text = Translations.NETWORK_SELECTION_DK2_ZIP_LIST
            }
            return self
        }
    }

    private class Cell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(with network: Network) -> Cell {
            textLabel?.text = network.name
            accessoryType = .disclosureIndicator
            return self
        }
    }
}

extension NetworkSelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        zones.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath).update(with: items[indexPath.section][indexPath.row])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableView.dequeueReusableHeaderFooter(Header.self).update(with: zones[section])
    }
}

extension NetworkSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.section][indexPath.row]
        navigation.navigate(to: .loadData(network: item))
    }
}
