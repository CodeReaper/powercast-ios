import UIKit
import SugarKit

class PriceHeaderView: UITableViewHeaderFooterView {
    private static let dateFormatter = DateFormatter.with(dateStyle: .medium, timeStyle: .none)
    private static let numberFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)

    private let dateLabel = Label(style: .body, color: .cellHeaderText)
    private let pricesLabel = Label(style: .body, color: .cellHeaderText).aligned(to: .right)
    private let rawLabel = Label(style: .body, color: .cellHeaderText).aligned(to: .right)
    private let emissionLabel = Label(style: .body, color: .cellHeaderText).aligned(to: .right)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .cellHeaderBackground

        Stack.views(
            spacing: 10,
            inset: NSDirectionalEdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10),
            Stack.views(
                on: .vertical,
                spacing: 5,
                dateLabel,
                Label(style: .body, text: Translations.DASHBOARD_RAW_PRICE_VARIATION, color: .secondaryLabelText),
                Label(style: .body, text: Translations.DASHBOARD_CO2_VARIATION, color: .secondaryLabelText)
            ),
            Stack.views(
                on: .vertical,
                spacing: 5,
                Stack.views(spacing: 3, pricesLabel, Label(style: .body, text: Translations.COST_UNIT, color: .secondaryLabelText)),
                Stack.views(spacing: 3, rawLabel, Label(style: .body, text: Translations.COST_UNIT, color: .secondaryLabelText)),
                Stack.views(spacing: 3, emissionLabel, Label(style: .body, text: Translations.CO2_UNIT, color: .secondaryLabelText))
            )
        ).setup(in: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(using price: Price, and emission: Emission.Co2?, current: Bool) -> Self {
        dateLabel.text = Self.dateFormatter.string(from: price.duration.lowerBound)
        pricesLabel.text = Translations.SPAN(Self.numberFormatter.string(with: price.priceSpan.lowerBound), Self.numberFormatter.string(with: price.priceSpan.upperBound))
        rawLabel.text = Self.numberFormatter.string(with: price.rawPriceSpan.upperBound - price.rawPriceSpan.lowerBound)
        emissionLabel.text = Translations.SPAN(Self.numberFormatter.string(with: emission?.amountSpan.lowerBound ?? 0), Self.numberFormatter.string(with: emission?.amountSpan.upperBound ?? 0))
        emissionLabel.set(hidden: emission == nil)
        return self
    }
}
