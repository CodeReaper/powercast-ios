import Foundation

struct Price {
    let price: Double
    let priceSpan: ClosedRange<Double>
    let rawPrice: Double
    let rawPriceSpan: ClosedRange<Double>
    let charges: Charges
    let zone: Zone
    let duration: ClosedRange<Date>

    func isActive(at date: Date) -> Bool {
        duration.contains(date)
    }

    func isHighLoad() -> Bool {
        charges.isHighLoad(at: duration.lowerBound)
    }
}
