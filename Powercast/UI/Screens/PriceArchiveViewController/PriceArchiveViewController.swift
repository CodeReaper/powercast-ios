import UIKit
import SugarKit

class PriceArchiveViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let picker = UIDatePicker(frame: .zero)
    private let formatter = DateFormatter.with(dateStyle: .medium, timeStyle: .none)

    private var source = PriceArchiveSource.empty()
    private var interactor: PriceArchiveInteractor!

    init(navigation: AppNavigation, state: StateRepository, prices: EnergyPriceRepository, emission: EmissionRepository) {
        super.init(navigation: navigation)
        interactor = PriceArchiveInteractor(delegate: self, prices: prices, emission: emission)
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
        tableView.allowsSelection = false
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: Color.primary)
            .registerClass(DatePickerCell.self)
            .registerClass(PriceCell.self)
            .registerClass(LoadingCell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        interactor.viewWillAppear()
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
            views.arrangedSubviews.forEach { views.removeArrangedSubview($0) }
        }

        func update(with datePicker: UIDatePicker) -> Self {
            views.addArrangedSubview(datePicker)
            return self
        }
    }

    private class LoadingCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = Color.primary

            let view = UIActivityIndicatorView()
            view.setup(centeredIn: contentView)
            view.color = .white
            view.startAnimating()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension PriceArchiveViewController: PriceArchiveDelegate {
    func show(source: PriceArchiveSource) {
        title = formatter.string(from: source.date)
        self.source = source
        tableView.separatorStyle = source.loading ? .none : .singleLine
        tableView.reloadData()
    }
}

extension PriceArchiveViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : source.itemCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(DatePickerCell.self, forIndexPath: indexPath).update(with: picker)
        } else if source.loading {
            return tableView.dequeueReusableCell(LoadingCell.self, forIndexPath: indexPath)
        } else if source.failed {
            return tableView.dequeueReusableCell(LoadingCell.self, forIndexPath: indexPath) // FIXME: failed?
        } else {
            guard let (price, emission) = source.items(at: indexPath.row) else { return UITableViewCell() }
            return tableView.dequeueReusableCell(PriceCell.self, forIndexPath: indexPath).update(using: price, and: emission, current: false)
        }
    }
}

extension PriceArchiveViewController: UITableViewDelegate { }
