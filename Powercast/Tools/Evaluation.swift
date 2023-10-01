import Foundation

struct Evaluation {
    static func of(_ prices: [EnergyPrice], after date: Date = .now, using charges: Charges) -> [Result] {
        let evaluables = prices.filter({ $0.timestamp >= date })

        guard evaluables.isEmpty == false else { return [] }

        let evaluableHigh = evaluables.reduce(-Double.infinity, { $0 < $1.price ? $1.price : $0 })
        let evaluableLow = evaluables.reduce(Double.infinity, { $0 > $1.price ? $1.price : $0 })
        let priceHigh = prices.reduce(-Double.infinity, { $0 < $1.price ? $1.price : $0 })
        let priceLow = prices.reduce(Double.infinity, { $0 > $1.price ? $1.price : $0 })
        let priceAverage = max(0, priceLow) + (max(0, priceHigh - priceLow) / 2)
        let evaluableAverage = max(0, evaluableLow) + (max(0, evaluableHigh - evaluableLow) / 2)

        return evaluables.map {
            var properties: [Property] = []

            let fees = charges.fees(at: $0.timestamp)
            if $0.price == evaluableHigh {
                properties.append(.priciestAvailable)
            }
            if $0.price == evaluableLow {
                properties.append(.cheapestAvailable)
            }
            if $0.price < fees / 2 {
                properties.append(.mostlyFees)
            }
            if $0.price + fees < 0 {
                properties.append(.free)
            }
            if $0.price < 0 {
                properties.append(.negativelyPriced)
            }
            if $0.price > priceAverage {
                properties.append(.aboveAverage)
            } else {
                properties.append(.belowAverage)
            }
            if $0.price > evaluableAverage {
                properties.append(.aboveAvailableAverage)
            } else {
                properties.append(.belowAvailableAverage)
            }

            return Result(model: $0, properties: properties)
        }
    }

    struct Result {
        let model: EnergyPrice
        let properties: [Property]
    }

    enum Property {
        case cheapestAvailable
        case priciestAvailable
        case belowAvailableAverage
        case aboveAvailableAverage
        case belowAverage
        case aboveAverage
        case mostlyFees
        case negativelyPriced
        case free
    }
}
