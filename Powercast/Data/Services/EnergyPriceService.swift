import Foundation
import Flogger

protocol EnergyPriceService {
    func interval(for zone: Zone) async throws -> DateInterval
    func data(for zone: Zone, at date: Date) async throws -> [EnergyPrice]
}

enum EnergyPriceServiceError: Error {
    case unknownZone(givenZone: String)
    case unresolvableDate(givenZone: String, type: String)
}

class EnergyPriceServiceAPI: EnergyPriceService {
    private let endpoint = "https://codereaper.github.io/powercast-data/api/energy-price"
    private let decoder = JSONDecoder()
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private let session = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        return URLSession(configuration: configuration)
    }()

    func data(for zone: Zone, at date: Date) async throws -> [EnergyPrice] {
        let url = URL(string: "\(endpoint)/\(formatter.string(from: date))/\(zone.rawValue).json")!
        let data = try await fetch(url: url)
        let list = try decoder.decode([Item].self, from: data)
        return list.map {
            EnergyPrice(price: $0.euro, zone: zone, timestamp: Date(timeIntervalSince1970: $0.timestamp))
        }
    }

    func interval(for zone: Zone) async throws -> DateInterval {
        let url = URL(string: "\(endpoint)/index.json")!
        let data = try await fetch(url: url)
        let list = try decoder.decode([Index].self, from: data)
        guard let item = list.first(where: { $0.zone.lowercased() == zone.rawValue.lowercased() }) else {
            throw EnergyPriceServiceError.unknownZone(givenZone: zone.rawValue)
        }
        guard let latest = date(from: item.latest) else {
            throw EnergyPriceServiceError.unresolvableDate(givenZone: zone.rawValue, type: "latest")
        }
        guard let oldest = date(from: item.oldest) else {
            throw EnergyPriceServiceError.unresolvableDate(givenZone: zone.rawValue, type: "oldest")
        }
        return DateInterval(start: oldest, end: latest)
    }

    private func date(from urlPath: String) -> Date? {
        let parts = urlPath.split(separator: "/")
        guard parts.count == 6 else { return nil }

        var components = DateComponents()
        components.calendar = .current
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = Int(parts[2])
        components.month = Int(parts[3])
        components.day = Int(parts[4])
        return components.date
    }

    private func fetch(url: URL) async throws -> Data {
        let (data, base) = try await session.data(from: url)
        let response = base as! HTTPURLResponse // swiftlint:disable:this force_cast

        Flog.info("GET \(url) \(response.statusCode) \(data.count)")

        return data
    }
}

private struct Index: Codable {
    let latest: String
    let oldest: String
    let zone: String
}

private struct Item: Codable {
    let euro: Double
    let timestamp: TimeInterval
}
