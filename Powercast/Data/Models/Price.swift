import Foundation

struct Price {
    let price: Double
    let priceSpan: ClosedRange<Double>
    let rawPrice: Double
    let fees: Double
    let fixedFees: Double
    let variableFees: Double
    let zone: Zone
    let duration: ClosedRange<Date>
}

extension Price {
    static func map(_ items: [EnergyPrice], at date: Date, in network: Network, using lookup: ChargesLookup) -> Self? {
        guard
            let model = items.first(where: { $0.timestamp == date }),
            let charges = try? lookup.charges(for: network, at: model.timestamp)
        else { return nil }

        return Price(
            price: charges.format(model.price, at: model.timestamp),
            priceSpan: items.map({ charges.format($0.price, at: $0.timestamp) }).span(),
            rawPrice: charges.convert(model.price, at: model.timestamp),
            fees: charges.fees(at: model.timestamp),
            fixedFees: charges.fixedFees(at: model.timestamp),
            variableFees: charges.variableFees(at: model.timestamp),
            zone: model.zone,
            duration: model.timestamp...model.timestamp.addingTimeInterval(.oneHour)
        )
    }
}
