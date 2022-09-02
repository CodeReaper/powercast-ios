import Foundation

struct Price {
    let price: Double
    let priceSpan: ClosedRange<Double>
    let zone: Zone
    let duration: ClosedRange<Date>

    func isActive(at date: Date) -> Bool {
        duration.contains(date)
    }
}
