import UIKit
import SugarKit

class NetworkSelectionViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = UIView()
    private let indicator = UIActivityIndicatorView()
    private let helpURL = URL(string: "https://greenpowerdenmark.dk/vejledning-teknik/nettilslutning/find-netselskab")!

    private let charges: ChargesRepository
    private let cancelable: Bool

    private var zones: [Zone] = []
    private var items: [[Network]] = []

    private var retryButton: UIButton!

    init(navigation: AppNavigation, networks: [Network], charges: ChargesRepository, cancelable: Bool) {
        self.charges = charges
        self.cancelable = cancelable
        super.init(navigation: navigation)
        retryButton = Button(text: Translations.NETWORK_SELECTION_EMPTY_BUTTON, textColor: .buttonText, target: self, action: #selector(didTapRetry))
        show(networks)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.NETWORK_SELECTION_TITLE

        navigationController?.navigationBar.shadowImage = UIImage()

        if cancelable {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: self, action: #selector(didTapHelp))

        view.backgroundColor = .systemGroupedBackground

        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
            .registerClass(Cell.self)
            .registerClass(Header.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }

        emptyView.set(backgroundColor: .tableBackground).setup(matching: view, in: view)

        Stack.views(
            aligned: .center,
            on: .vertical,
            spacing: 5,
            Label(style: .body, text: Translations.NETWORK_SELECTION_EMPTY_TITLE, color: .labelText),
            retryButton.set(height: 44),
            indicator.set(height: 44)
        ).layout(in: emptyView) { (make, its) in
            make(its.centerXAnchor.constraint(equalTo: emptyView.safeAreaLayoutGuide.centerXAnchor))
            make(its.centerYAnchor.constraint(equalTo: emptyView.safeAreaLayoutGuide.centerYAnchor))
            make(its.widthAnchor.constraint(equalTo: emptyView.safeAreaLayoutGuide.widthAnchor))
        }
    }

    private func show(_ networks: [Network]) {
        let zones = Set(networks.map { $0.zone })
        self.zones = [Zone.dk2, .dk1].filter { zones.contains($0) }
        self.items = zones.map { zone in
            networks.filter({ $0.zone == zone }).sorted(by: { $0.name < $1.name })
        }
        emptyView.set(hidden: zones.count != 0)
    }

    @objc private func didTapCancel() {
        navigate(to: .networkSelection(forceSelection: false))
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

    @objc func didTapRetry() {
        retryButton.set(hidden: true)
        indicator.set(hidden: false)
        indicator.startAnimating()

        Task {
            try? await charges.pullNetworks()
            let networks = try? charges.networks()
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
                self.indicator.set(hidden: true)
                self.retryButton!.set(hidden: false)
                self.show(networks ?? [])
            }
        }
    }

    private class Header: UITableViewHeaderFooterView {
        private let label = Label(style: .body, color: .cellHeaderTitle)
        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = .cellHeaderBackground

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

            backgroundColor = .cellBackground
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(with network: Network) -> Cell {
            textLabel?.text = network.name
            textLabel?.textColor = .cellTitle
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
