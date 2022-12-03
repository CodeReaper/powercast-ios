import Foundation

struct PriceFormatter {
    private let formatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)

    private let conversionRate: Double

    init(conversionRate: Double = 750) {
        self.conversionRate = conversionRate
    }

    func format(_ value: Double) -> String {
        return formatter.string(from: (value / 1000 * conversionRate) as NSNumber)!
    }
}
