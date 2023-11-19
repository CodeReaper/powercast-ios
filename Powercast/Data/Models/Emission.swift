import Foundation

struct Emission {
    struct Co2 {
        let amounts: ClosedRange<Double>
        let amountSpan: ClosedRange<Double>
        let zone: Zone
        let duration: ClosedRange<Date>
        let data: [Date: Double]
    }
}

extension Emission.Co2 {
    static func map(_ items: [Co2], at date: Date, in zone: Zone) -> Self? {
        let duration = date...date.addingTimeInterval(.oneHour)
        let item = items.filter { duration.contains($0.timestamp) }

        guard items.isEmpty == false && item.isEmpty == false else { return nil }

        return Emission.Co2(
            amounts: item.map({ $0.amount }).span(),
            amountSpan: items.map({ $0.amount }).span(),
            zone: zone,
            duration: duration,
            data: Dictionary(uniqueKeysWithValues: item.map { ($0.timestamp, $0.amount) })
        )
    }
}
