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

struct PowercastDataServiceFactory {
    enum Mode {
        case ephemeral
        case background
    }

    func build(_ mode: Mode) -> PowercastDataService {
        return PowercastDataServiceAPI(mode: mode)
    }
}

class PowercastDataServiceAPI: NSObject, PowercastDataService {
    private let endpoint = "https://codereaper.github.io/powercast-data/api/energy-price"
    private let decoder = JSONDecoder()
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private let configuration: URLSessionConfiguration
    private lazy var session: URLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

    fileprivate init(mode: PowercastDataServiceFactory.Mode) {
        switch mode {
        case .ephemeral:
            configuration = URLSessionConfiguration.ephemeral
        case .background:
            let configuration = URLSessionConfiguration.background(withIdentifier: BackgroundIdentifiers.energyPrice)
            configuration.isDiscretionary = true
            configuration.timeoutIntervalForRequest = 30
            self.configuration = configuration
        }

        super.init()
    }

    func latest(for zone: Zone) async throws -> Date {
        return try await lookup(.latest, in: zone)
    }

    func oldest(for zone: Zone) async throws -> Date {
        return try await lookup(.oldest, in: zone)
    }

    func data(for zone: Zone, at date: Date) async throws -> [EnergyPrice] {
        let url = URL(string: "\(endpoint)/\(formatter.string(from: date))/\(zone.rawValue).json")!
        let data = try await data(from: url)
        let list = try decoder.decode([Item].self, from: data)
        return list.map {
            EnergyPrice(price: $0.euro, zone: zone, timestamp: Date(timeIntervalSince1970: $0.timestamp))
        }
    }

    private func lookup(_ type: IndexType, in zone: Zone) async throws -> Date {
        let url = URL(string: "\(endpoint)/index.json")!
        let data = try await data(from: url)
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

    private var continuation: CheckedContinuation<Data, Error>?
    private var buffer = Data()
    private func data(from url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.buffer = Data()
            self.continuation = continuation
            self.session.dataTask(with: url).resume()
        }
    }

    private enum IndexType {
        case latest
        case oldest
    }
}

extension PowercastDataServiceAPI: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume(returning: buffer)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(contentsOf: data)
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
