import Foundation
import Flogger

protocol IncidentsService {
    func delayedPrices(for zone: Zone) async throws -> [Delay]
    func delayedEmissions(for zone: Zone) async throws -> [Delay]
}

class IncidentsServiceAPI: IncidentsService {
    private let endpoint = "https://codereaper.github.io/powercast-data/api/incidents"
    private let decoder = JSONDecoder()

    private let session = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        return URLSession(configuration: configuration)
    }()

    func delayedPrices(for zone: Zone) async throws -> [Delay] {
        let url = URL(string: "\(endpoint)/energy-price/\(zone.rawValue).json")!
        let data = try await fetch(url: url)
        let list = try decoder.decode([Item].self, from: data)
        return list.compactMap {
            guard $0.type == "delay" else { return nil }
            return Delay(from: Date(timeIntervalSince1970: $0.from), to: $0.to == nil ? nil : Date(timeIntervalSince1970: $0.to!))
        }
    }

    func delayedEmissions(for zone: Zone) async throws -> [Delay] {
        let url = URL(string: "\(endpoint)/emission/co2/\(zone.rawValue).json")!
        let data = try await fetch(url: url)
        let list = try decoder.decode([Item].self, from: data)
        return list.compactMap {
            guard $0.type == "delay" else { return nil }
            return Delay(from: Date(timeIntervalSince1970: $0.from), to: $0.to == nil ? nil : Date(timeIntervalSince1970: $0.to!))
        }
    }

    private func fetch(url: URL) async throws -> Data {
        let (data, base) = try await session.data(from: url)
        let response = base as! HTTPURLResponse // swiftlint:disable:this force_cast

        Flog.info("GET \(url) \(response.statusCode) \(data.count)")

        return data
    }
}

private struct Item: Codable {
    let from: TimeInterval
    let to: TimeInterval?
    let type: String
}
