import Foundation
@testable import Powercast

struct EnergyPrices {
    static func make(_ count: Int, startingAt date: Date, costing price: Double = 100, in zone: Zone = .dk1) -> [EnergyPrice] {
        guard count > 0 else { return [] }

        return (0..<count).map { index in
            EnergyPrice(price: price, zone: zone, timestamp: date.date(byAdding: .hour, value: index))
        }
    }
}
