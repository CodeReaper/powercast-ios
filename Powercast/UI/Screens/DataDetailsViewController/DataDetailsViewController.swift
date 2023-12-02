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

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.allowsSelection = false
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
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
        private let label = Label(style: .body, color: .cellHeaderText)

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)

            contentView.backgroundColor = .cellHeaderBackground

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
        private let priceLabel = Label(color: .cellText).aligned(to: .right)
        private let rawLabel = Label(color: .cellText).aligned(to: .right)
        private let variableFeesLabel = Label(color: .cellText).aligned(to: .right)
        private let fixedFeesLabel = Label(color: .cellText).aligned(to: .right)
        private let rawPercentageLabel = Label(color: .cellSecondaryText).aligned(to: .right)
        private let variablePercentageFeesLabel = Label(color: .cellSecondaryText).aligned(to: .right)
        private let fixedPercentageFeesLabel = Label(color: .cellSecondaryText).aligned(to: .right)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

            Stack.views(
                on: .vertical,
                spacing: 10,
                inset: NSDirectionalEdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15),
                Stack.views(
                    on: .horizontal,
                    spacing: 5,
                    Label(text: Translations.DATA_DETAILS_PRICE_LABEL, color: .cellSecondaryText).updateContentCompressionResistancePriority(.required, for: .horizontal),
                    Label(),
                    priceLabel,
                    Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .cellSecondaryText)
                ),
                Stack.views(
                    on: .horizontal,
                    spacing: 5,
                    Label(text: Translations.DATA_DETAILS_RAW_PRICE_LABEL, color: .cellSecondaryText).updateContentCompressionResistancePriority(.required, for: .horizontal),
                    rawPercentageLabel,
                    rawLabel,
                    Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .cellSecondaryText)
                ),
                Stack.views(
                    on: .horizontal,
                    spacing: 5,
                    Label(text: Translations.DATA_DETAILS_FIXED_FEES_LABEL, color: .cellSecondaryText).updateContentCompressionResistancePriority(.required, for: .horizontal),
                    fixedPercentageFeesLabel,
                    fixedFeesLabel,
                    Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .cellSecondaryText)
                ),
                Stack.views(
                    on: .horizontal,
                    spacing: 5,
                    Label(text: Translations.DATA_DETAILS_VARIABLE_FEES_LABEL, color: .cellSecondaryText).updateContentCompressionResistancePriority(.required, for: .horizontal),
                    variablePercentageFeesLabel,
                    variableFeesLabel,
                    Label(text: Translations.DATA_DETAILS_PRICE_UNIT, color: .cellSecondaryText)
                )
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
            var formatter = NumberFormatter.with(style: .decimal, fractionDigits: 2)
            priceLabel.text = formatter.string(with: price.price)
            rawLabel.text = formatter.string(with: price.rawPrice)
            variableFeesLabel.text = formatter.string(with: price.variableFees)
            fixedFeesLabel.text = formatter.string(with: price.fixedFees)

            formatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)
            rawPercentageLabel.text = Translations.DATA_DETAILS_PERCENTAGE(formatter.string(with: 100 * (price.rawPrice / price.price)))
            variablePercentageFeesLabel.text = Translations.DATA_DETAILS_PERCENTAGE(formatter.string(with: 100 * (price.variableFees / price.price)))
            fixedPercentageFeesLabel.text = Translations.DATA_DETAILS_PERCENTAGE(formatter.string(with: 100 * (price.fixedFees / price.price)))

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
            views.arrangedSubviews.forEach {
                views.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }

        func update(with emission: Emission.Co2) -> Self {
            let dateFormatter = DateFormatter.with(format: "HH:mm") // TODO: handle fixed date format
            let formatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)
            for date in emission.data.keys.sorted() {
                views.addArrangedSubview(
                    Stack.views(
                        inset: NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10),
                        Label(text: Translations.DATA_DETAILS_EMISSION_CO2_SPAN(dateFormatter.string(from: date), dateFormatter.string(from: date.addingTimeInterval(.fiveMinutes))), color: .cellSecondaryText),
                        Stack.views(
                            spacing: 5,
                            Label(text: formatter.string(with: emission.data[date]!), color: .cellText).aligned(to: .right),
                            Label(text: Translations.DATA_DETAILS_EMISSION_CO2_UNIT, color: .cellSecondaryText)
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
}

extension DataDetailsViewController: UITableViewDelegate {
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
