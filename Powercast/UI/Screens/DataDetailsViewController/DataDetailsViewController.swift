import UIKit
import SugarKit

class DataDetailsViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let price: Price
    private let emission: Emission.Co2?

    init(navigation: AppNavigation, price: Price, emission: Emission.Co2?) {
        self.price = price
        self.emission = emission
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = DateFormatter.with(dateStyle: .medium, timeStyle: .short).string(from: price.duration.lowerBound)

        navigationController?.navigationBar.shadowImage = UIImage()

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.allowsSelection = false
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: Color.primary)
            .registerClass(Header.self)
            .registerClass(PriceCell.self)
            .registerClass(EmissionCell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }
    }

    private class Header: UITableViewHeaderFooterView {
        private let label = Label(style: .body, color: .white)

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = Color.primary

            Stack.views(
                on: .horizontal,
                spacing: 10,
                inset: NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10),
                label
            ).setup(in: contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(using title: String) -> Self {
            label.text = title
            return self
        }
    }

    private class PriceCell: UITableViewCell {
        private let priceLabel = Label(color: .black).aligned(to: .right)
        private let rawLabel = Label(color: .black).aligned(to: .right)
        private let variableFeesLabel = Label(color: .black).aligned(to: .right)
        private let fixedFeesLabel = Label(color: .black).aligned(to: .right)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

            Stack.views(
                on: .vertical,
                spacing: 10,
                inset: NSDirectionalEdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15),
                Stack.views(on: .horizontal, Label(text: Translations.DATA_DETAILS_PRICE_LABEL, color: .black), Label(), Stack.views(on: .horizontal, spacing: 5, priceLabel, Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .black).updateContentCompressionResistancePriority(.required, for: .vertical))),
                Stack.views(on: .horizontal, Label(text: Translations.DATA_DETAILS_RAW_PRICE_LABEL, color: .black), Label(text: Translations.DATA_DETAILS_PERCENTAGE("0"), color: .black), Stack.views(on: .horizontal, spacing: 5, rawLabel, Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .black).updateContentCompressionResistancePriority(.required, for: .vertical))),
                Stack.views(on: .horizontal, Label(text: Translations.DATA_DETAILS_FIXED_FEES_LABEL, color: .black), Label(text: Translations.DATA_DETAILS_PERCENTAGE("0"), color: .black), Stack.views(on: .horizontal, spacing: 5, fixedFeesLabel, Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .black).updateContentCompressionResistancePriority(.required, for: .vertical))),
                Stack.views(on: .horizontal, Label(text: Translations.DATA_DETAILS_VARIABLE_FEES_LABEL, color: .black), Label(text: Translations.DATA_DETAILS_PERCENTAGE("0"), color: .black), Stack.views(on: .horizontal, spacing: 5, variableFeesLabel, Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .black).updateContentCompressionResistancePriority(.required, for: .vertical)))
            ).layout(in: contentView) { (make, its) in
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
            for item in [rawLabel, fixedFeesLabel, variableFeesLabel] {
                item.text = nil
            }
        }

        func update(with price: Price) -> Self {
            let formatter = NumberFormatter.with(style: .decimal, fractionDigits: 2)
            // FIXME: percentages
            priceLabel.text = formatter.string(from: price.price as NSNumber)
            rawLabel.text = formatter.string(from: price.rawPrice as NSNumber)
            variableFeesLabel.text = formatter.string(from: price.variableFees as NSNumber)
            fixedFeesLabel.text = formatter.string(from: price.fixedFees as NSNumber)
            return self
        }
    }

    private class EmissionCell: UITableViewCell {
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

        func update(with emission: Emission.Co2) -> Self {
            let dateFormatter = DateFormatter.with(format: "HH:mm")
            let formatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)
            for date in emission.data.keys.sorted() {
                views.addArrangedSubview(
                    Stack.views(
                        inset: NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10),
                        Label(text: Translations.DATA_DETAILS_EMISSION_CO2_SPAN(dateFormatter.string(from: date), dateFormatter.string(from: date.addingTimeInterval(.fiveMinutes))), color: .black),
                        Stack.views(
                            spacing: 5,
                            Label(text: formatter.string(from: emission.data[date]! as NSNumber)!, color: .black).aligned(to: .right),
                            Label(text: Translations.DATA_DETAILS_EMISSION_CO2_UNIT, color: .black)
                        )
                    )
                )
            }
            return self
        }
    }
}

extension DataDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        emission == nil ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return tableView.dequeueReusableCell(PriceCell.self, forIndexPath: indexPath).update(with: price)
        case 1:
            return tableView.dequeueReusableCell(EmissionCell.self, forIndexPath: indexPath).update(with: emission!)
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return tableView.dequeueReusableHeaderFooter(Header.self).update(using: Translations.DATA_DETAILS_TITLE_PRICE)
        case 1:
            return tableView.dequeueReusableHeaderFooter(Header.self).update(using: Translations.DATA_DETAILS_TITLE_EMISSION)
        default:
            return nil
        }
    }
}

extension DataDetailsViewController: UITableViewDelegate { }
