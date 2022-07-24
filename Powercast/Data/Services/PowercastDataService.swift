import Foundation

protocol PowercastDataService {
    func latest(for zone: Zone) async throws -> Date

    func oldest(for zone: Zone) async throws -> Date

    func data(for zone: Zone, at date: Date) async throws -> [EnergyPrice]
}

enum PowercastDataServiceError: Error {
    case unknownZone(givenZone: String)
    case unresolvableDate(givenZone: String, type: String)
}

struct PowercastDataServiceDemoValues: PowercastDataService {
    func latest(for zone: Zone) async throws -> Date {
        return Date(timeIntervalSince1970: 1658016000)
    }

    func oldest(for zone: Zone) async throws -> Date {
        return Date(timeIntervalSince1970: 1658016000)
    }

    func data(for zone: Zone, at date: Date) async throws -> [EnergyPrice] {
        try? await Task.sleep(seconds: 3)
        return [
            EnergyPrice(price: 0, zone: zone, timestamp: Date(timeIntervalSince1970: 1658016000)),
            EnergyPrice(price: 1, zone: zone, timestamp: Date(timeIntervalSince1970: 1658019600)),
            EnergyPrice(price: 2, zone: zone, timestamp: Date(timeIntervalSince1970: 1658023200)),
            EnergyPrice(price: 3, zone: zone, timestamp: Date(timeIntervalSince1970: 1658026800))
        ]
    }
}

struct PowercastDataServiceAPI: PowercastDataService {
    private let endpoint = "https://codereaper.github.io/powercast-data/api/energy-price"
    private let decoder = JSONDecoder()
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        return session
    }()

    func latest(for zone: Zone) async throws -> Date {
        return try await lookup(.latest, in: zone)
    }

    func oldest(for zone: Zone) async throws -> Date {
        return try await lookup(.oldest, in: zone)
    }

    func data(for zone: Zone, at date: Date) async throws -> [EnergyPrice] {
        let url = URL(string: "\(endpoint)/\(formatter.string(from: date))/\(zone.rawValue).json")!
        let (data, _) = try await session.data(from: url)
        let list = try decoder.decode([Item].self, from: data)
        return list.map {
            EnergyPrice(price: $0.euro, zone: zone, timestamp: Date(timeIntervalSince1970: $0.timestamp))
        }
    }

    private func lookup(_ type: IndexType, in zone: Zone) async throws -> Date {
        let url = URL(string: "\(endpoint)/index.json")!
        let (data, _) = try await session.data(from: url)
        let list = try decoder.decode([Index].self, from: data)
        guard let item = list.first(where: { $0.zone.lowercased() == zone.rawValue.lowercased() }) else {
            throw PowercastDataServiceError.unknownZone(givenZone: zone.rawValue)
        }

        let pathUrl: String
        switch type {
        case .latest:
            pathUrl = item.latest
        case .oldest:
            pathUrl = item.oldest
        }
        guard let date = date(from: pathUrl) else {
            throw PowercastDataServiceError.unresolvableDate(givenZone: zone.rawValue, type: "latest")
        }
        return date
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

    private enum IndexType {
        case latest
        case oldest
    }
}

private extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

private extension URLSession {
    @available(iOS, deprecated: 15.0, message: "This extension is no longer necessary. Use API built into SDK")
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    return continuation.resume(throwing: error ?? URLError(.badServerResponse))
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
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
