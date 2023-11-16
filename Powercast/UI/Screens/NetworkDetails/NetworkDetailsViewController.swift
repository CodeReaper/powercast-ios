import UIKit
import SugarKit

class NetworkDetailsViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let dateFormatter = DateFormatter.with(dateStyle: .medium, timeStyle: .none)
    private let currencyFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 2)

    private let network: Network
    private let items: [NetworkPrice]

    init(navigation: AppNavigation, network: Network, charges: ChargesRepository) {
        let items = try? charges.networkPrices(by: network.id)
        self.network = network
        self.items = items ?? []
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = network.name

        navigationController?.navigationBar.shadowImage = UIImage()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))

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

    @objc private func didTapEdit() {
        navigate(to: .networkSelection(forceSelection: true))
    }

    private class Cell: UITableViewCell {
        private let dateLabel = Label(color: .black)
        private let labels: [UILabel]
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            labels = (0...23).map { _ in Label(color: .black) }

            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.minimumIntegerDigits = 2

            let stackView = Stack.views(
                on: .vertical,
                inset: NSDirectionalEdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15),
                dateLabel
            ).layout(in: contentView) { (make, its) in
                make(its.topAnchor.constraint(equalTo: contentView.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
                make(its.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: contentView.trailingAnchor))
            }

            for (index, view) in labels.enumerated() {
                stackView.addArrangedSubview(
                    Stack.views(
                        Label(text: "\(formatter.string(from: index as NSNumber)!) - \(formatter.string(from: (index + 1) as NSNumber)!)", color: .black),
                        view
                    )
                )
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            dateLabel.text = nil
        }

        func update(with price: NetworkPrice, using dateFormatter: DateFormatter, and currencyFormatter: NumberFormatter) -> Cell {
            if let validTo = price.validTo {
                dateLabel.text = "\(dateFormatter.string(from: price.validFrom)) - \(dateFormatter.string(from: validTo))"
            } else {
                dateLabel.text = "\(dateFormatter.string(from: price.validFrom)) - present"
            }
            for (index, price) in price.loadTariff.enumerated() {
                labels[index].text = currencyFormatter.string(from: price as NSNumber)
            }
            return self
        }
    }
}

extension NetworkDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(Cell.self, forIndexPath: indexPath).update(with: items[indexPath.row], using: dateFormatter, and: currencyFormatter)
    }
}

extension NetworkDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
