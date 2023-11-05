import Foundation

struct Evaluation {
    let model: EnergyPrice
    let charges: Charges
    let precentile: Int
    let precentileAvailable: Int
    let cheapestAvailable: Bool
    let priciestAvailable: Bool
    let belowAvailableAverage: Bool
    let belowAverage: Bool
    let mostlyFees: Bool
    let negativelyPriced: Bool
    let free: Bool

    var aboveAvailableAverage: Bool { !belowAvailableAverage }
    var aboveAverage: Bool { !belowAverage }
}

extension Evaluation {
    static func of(_ prices: [EnergyPrice], after date: Date = .now, using repository: ChargesRepository, and network: Network) -> [Evaluation] {
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
            guard let charges = try? repository.charges(for: network, at: model.timestamp) else { return nil }

            let fees = charges.convertedFees(at: model.timestamp)
            return Evaluation(
                model: model,
                charges: charges,
                precentile: bins.filter { $0.1 ?? Double.infinity < model.price }.sorted(by: { $0.0 > $1.0 }).first?.0 ?? 0,
                precentileAvailable: availableBins.filter { $0.1 ?? Double.infinity < model.price }.sorted(by: { $0.0 > $1.0 }).first?.0 ?? 0,
                cheapestAvailable: model.price == evaluableLow,
                priciestAvailable: model.price == evaluableHigh,
                belowAvailableAverage: model.price <= evaluableAverage,
                belowAverage: model.price <= priceAverage,
                mostlyFees: model.price < fees / 2,
                negativelyPriced: model.price < 0,
                free: model.price + fees < 0
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
