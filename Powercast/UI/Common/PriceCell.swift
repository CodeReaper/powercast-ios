import UIKit
import SugarKit

class PriceCell: UITableViewCell {
    private static let dateFormatter = DateFormatter.with(format: "HH")
    private static let numberFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)

    private let selectionIndicator = UIView()
    private let dateLabel = Label(style: .body, color: .cellTitle)
    private let priceLabel = Label(style: .headline, color: .cellTitle).aligned(to: .right)
    private let co2Label = Label(style: .subheadline, text: Translations.DASHBOARD_CO2_LABEL, color: .cellSubtitle)
    private let emissionLabel = Label(style: .subheadline, color: .cellSubtitle).aligned(to: .right)
    private let priceUnitLabel = Label(style: .subheadline, text: Translations.DASHBOARD_COST_UNIT, color: .cellSubtitle)
    private let emissionUnitLabel = Label(style: .subheadline, text: Translations.DASHBOARD_CO2_UNIT, color: .cellSubtitle)
    private let priceGaugeView = MultiColorGaugeView()
    private let emissionGaugeView = MultiColorGaugeView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .cellBackground

        selectionIndicator
            .set(hidden: true)
            .set(backgroundColor: .cellActiveIndicator)
            .layout(in: contentView) { (make, its) in
                make(its.topAnchor.constraint(equalTo: contentView.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
                make(its.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
                make(its.widthAnchor.constraint(equalToConstant: 4))
            }

        for view in [priceGaugeView, emissionGaugeView] {
            view.set(height: 5)
            view.layer.cornerRadius = 2.5
            view.clipsToBounds = true
            view.tintColor = .gaugeTint
        }
        Stack.views(
            on: .vertical,
            inset: NSDirectionalEdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15),
            Stack.views(on: .horizontal, spacing: 3, inset: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0), dateLabel, priceLabel, priceUnitLabel),
            priceGaugeView,
            Stack.views(on: .horizontal, spacing: 3, inset: NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0), co2Label, emissionLabel, emissionUnitLabel),
            emissionGaugeView
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
        selectionIndicator.set(hidden: true)
        priceGaugeView.values = []
        emissionGaugeView.values = []
        dateLabel.text = nil
        priceLabel.text = nil
        emissionLabel.text = nil
    }

    func update(using price: Price, and emission: Emission.Co2?, current: Bool) -> Self {
        backgroundColor = current ? .cellActiveBackground : .cellBackground
        accessoryType = .disclosureIndicator
        selectionIndicator.set(hidden: !current)

        let ratio = (price.price - price.fees) / price.priceSpan.upperBound
        priceGaugeView.values = [
            (price.fixedFees / price.priceSpan.upperBound, .gaugeFixedFees),
            (price.variableFees / price.priceSpan.upperBound, .gaugeVariableFees),
            (ratio, .gaugePrice.withAlphaComponent(ratio > 0 ? 1 : 0))
        ]

        if let emission = emission {
            let amounts = emission.amounts.upperBound == emission.amounts.lowerBound ? (emission.amounts.lowerBound - 0.5)...(emission.amounts.upperBound + 0.5) : emission.amounts
            let space = amounts.lowerBound / emission.amountSpan.upperBound
            emissionGaugeView.values = [
                (space, emissionGaugeView.tintColor),
                ((amounts.upperBound / emission.amountSpan.upperBound) - space, .gaugeEmission)
            ]
            emissionLabel.text = Translations.DASHBOARD_CO2_SPAN(Self.numberFormatter.string(with: emission.amounts.lowerBound), Self.numberFormatter.string(with: emission.amounts.upperBound))
        } else {
            emissionLabel.text = "-"
        }

        dateLabel.text = Translations.DASHBOARD_HOUR_TIME(Self.dateFormatter.string(from: price.duration.lowerBound), Self.dateFormatter.string(from: price.duration.upperBound))
        priceLabel.text = Self.numberFormatter.string(with: price.price)

        return self
    }
}