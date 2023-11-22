import UIKit
import SugarKit

class PriceArchiveViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let picker = UIDatePicker(frame: .zero)
    private let formatter = DateFormatter.with(dateStyle: .medium, timeStyle: .none)

    private var source = PriceArchiveSource.empty()
    private var interactor: PriceArchiveInteractor!

    init(navigation: AppNavigation, state: StateRepository, prices: EnergyPriceRepository, emission: EmissionRepository, lookup: ChargesLookup) {
        super.init(navigation: navigation)
        interactor = PriceArchiveInteractor(delegate: self, network: state.network, prices: prices, emission: emission, lookup: lookup)
        picker.date = .now
        picker.maximumDate = picker.date
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.addTarget(self, action: #selector(didChangeDate), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
            .registerClass(DatePickerCell.self)
            .registerClass(PriceCell.self)
            .registerClass(LoadingCell.self)
            .registerClass(FailureCell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }

        interactor.viewDidLoad()
    }

    @objc private func didChangeDate() {
        interactor.select(date: picker.date)
    }

    private class DatePickerCell: UITableViewCell {
        private let views = Stack.views(on: .vertical, inset: NSDirectionalEdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

            views.layout(in: contentView) { (make, its) in
                make(its.topAnchor.constraint(equalTo: contentView.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
                make(its.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: contentView.trailingAnchor))
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

        func update(with datePicker: UIDatePicker) -> Self {
            views.addArrangedSubview(datePicker)
            return self
        }
    }

    private class LoadingCell: UITableViewCell {
        private let spinner = UIActivityIndicatorView()
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            contentView.backgroundColor = .tableBackground
            spinner.setup(centeredIn: contentView)
            spinner.color = .spinner
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update() -> Self {
            spinner.startAnimating()
            return self
        }
    }

    private class FailureCell: UITableViewCell {
        private let label = Label(style: .subheadline, text: Translations.PRICE_ARCHIVE_FAILURE_MESSAGE, color: .cellSecondaryText)
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            contentView.backgroundColor = .tableBackground
            label.setup(centeredIn: contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension PriceArchiveViewController: PriceArchiveDelegate {
    func configure(with interval: DateInterval) {
        picker.minimumDate = interval.start
    }

    func show(source: PriceArchiveSource) {
        self.source = source
        title = formatter.string(from: source.date)
        tableView.separatorStyle = source.loading || source.failed ? .none : .singleLine
        tableView.reloadData()
    }
}

extension PriceArchiveViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || source.loading || source.failed {
            return 1
        } else {
            return source.itemCount
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(DatePickerCell.self, forIndexPath: indexPath).update(with: picker)
        } else if source.loading {
            return tableView.dequeueReusableCell(LoadingCell.self, forIndexPath: indexPath).update()
        } else if source.failed {
            return tableView.dequeueReusableCell(FailureCell.self, forIndexPath: indexPath)
        } else {
            guard let (price, emission) = source.items(at: indexPath.row) else { return UITableViewCell() }
            return tableView.dequeueReusableCell(PriceCell.self, forIndexPath: indexPath).update(using: price, and: emission, current: false, emissionRange: source.emissionRange)
        }
    }
}

extension PriceArchiveViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let (price, emission) = source.items(at: indexPath.row) else { return }

        navigate(to: .dataDetails(price: price, emission: emission))
    }
}
