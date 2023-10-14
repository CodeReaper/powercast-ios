import Foundation

struct Price {
    let price: Double
    let priceSpan: ClosedRange<Double>
    let rawPrice: Double
    let rawPriceSpan: ClosedRange<Double>
    let fees: Double
    let fixedFees: Double
    let variableFees: Double
    let zone: Zone
    let duration: ClosedRange<Date>

    func isActive(at date: Date) -> Bool {
        duration.contains(date)
    }
}
