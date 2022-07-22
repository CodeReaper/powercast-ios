import Foundation

protocol PowercastDataService {
    func latest(for zone: Zone) async -> Date

    func oldest(for zone: Zone) async -> Date

    func data(for zone: Zone, at date: Date) async -> [EnergyPrice]
}

struct PowercastDataServiceDemoValues: PowercastDataService {
    func latest(for zone: Zone) async -> Date {
        return Date(timeIntervalSince1970: 1658016000)
    }

    func oldest(for zone: Zone) async -> Date {
        return Date(timeIntervalSince1970: 1658016000)
    }

    func data(for zone: Zone, at date: Date) async -> [EnergyPrice] {
        try? await Task.sleep(seconds: 3)
        return [
            EnergyPrice(price: 0, zone: zone, timestamp: Date(timeIntervalSince1970: 1658016000)),
            EnergyPrice(price: 1, zone: zone, timestamp: Date(timeIntervalSince1970: 1658019600)),
            EnergyPrice(price: 2, zone: zone, timestamp: Date(timeIntervalSince1970: 1658023200)),
            EnergyPrice(price: 3, zone: zone, timestamp: Date(timeIntervalSince1970: 1658026800))
        ]
    }
}

private extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
