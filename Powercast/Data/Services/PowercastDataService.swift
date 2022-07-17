import Foundation

struct PowercastDataService {
    func latest(for zone: Zone) async -> Date {
        return Date(timeIntervalSince1970: 1658016000)
    }

    func oldest(for zone: Zone) async -> Date {
        return Date(timeIntervalSince1970: 1658016000)
    }

    func data(for zone: Zone, at date: Date) async -> [EnergyPrice] {
        return [
            EnergyPrice(price: 0, zone: zone, timestamp: Date(timeIntervalSince1970: 1658016000)),
            EnergyPrice(price: 1, zone: zone, timestamp: Date(timeIntervalSince1970: 1658019600)),
            EnergyPrice(price: 2, zone: zone, timestamp: Date(timeIntervalSince1970: 1658023200)),
            EnergyPrice(price: 3, zone: zone, timestamp: Date(timeIntervalSince1970: 1658026800))
        ]
    }
}
