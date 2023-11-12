import Foundation

struct Evaluation {
    let model: EnergyPrice
    let fees: Double
    let charges: Charges
    let precentile: Int
    let precentileAvailable: Int
    let cheapestAvailable: Bool
    let priciestAvailable: Bool
    let belowAvailableAverage: Bool
    let belowAverage: Bool

    var aboveAvailableAverage: Bool { !belowAvailableAverage }
    var aboveAverage: Bool { !belowAverage }
    var mostlyFees: Bool { model.price < fees / 2 }
    var negativelyPriced: Bool { model.price < 0 }
    var free: Bool { model.price + fees < 0 }
}

extension Evaluation {
    static func of(_ prices: [EnergyPrice], after date: Date = .now, using lookup: ChargesLookup, and network: Network) -> [Evaluation] {
        let evaluables = prices.filter({ $0.timestamp >= date })

        guard evaluables.isEmpty == false else { return [] }

        let evaluableHigh = evaluables.reduce(-Double.infinity, { $0 < $1.price ? $1.price : $0 })
        let evaluableLow = evaluables.reduce(Double.infinity, { $0 > $1.price ? $1.price : $0 })
        let priceHigh = prices.reduce(-Double.infinity, { $0 < $1.price ? $1.price : $0 })
        let priceLow = prices.reduce(Double.infinity, { $0 > $1.price ? $1.price : $0 })
        let priceAverage = priceLow + (priceHigh - priceLow) / 2
        let evaluableAverage = evaluableLow + (evaluableHigh - evaluableLow) / 2

        let allPrices = prices.map { $0.price }
        let bins = stride(from: 10, to: 100, by: 10).map { bin in
            return (Int(bin), percentile(nth: bin, of: allPrices))
        }

        let availablePrices = evaluables.map { $0.price }
        let availableBins = stride(from: 10, to: 100, by: 10).map { bin in
            return (Int(bin), percentile(nth: bin, of: availablePrices))
        }

        return evaluables.compactMap { model in
            guard let charges = try? lookup.charges(for: network, at: model.timestamp) else { return nil }

            return Evaluation(
                model: model,
                fees: charges.convertedFees(at: model.timestamp),
                charges: charges,
                precentile: bins.filter { $0.1 ?? Double.infinity < model.price }.sorted(by: { $0.0 > $1.0 }).first?.0 ?? 0,
                precentileAvailable: availableBins.filter { $0.1 ?? Double.infinity < model.price }.sorted(by: { $0.0 > $1.0 }).first?.0 ?? 0,
                cheapestAvailable: model.price == evaluableLow,
                priciestAvailable: model.price == evaluableHigh,
                belowAvailableAverage: model.price <= evaluableAverage,
                belowAverage: model.price <= priceAverage
            )
        }
    }

    private static func percentile(nth percentile: Double, of data: [Double]) -> Double? {
        guard data.count > 0 else { return nil }

        let sorted = data.sorted()
        let percentileIndex = percentile / 100.0 * Double(sorted.count - 1)
        let index = Int(percentileIndex)

        if index >= 0 && index < sorted.count - 1 {
            let factor = percentileIndex - Double(index)
            return (1.0 - factor) * sorted[index] + factor * sorted[index + 1]
        } else {
            return sorted[index]
        }
    }
}
