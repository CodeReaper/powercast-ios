import Foundation
import Flogger

protocol ChargesService {
    func grid() async throws -> [GridPrice]
    func networks() async throws -> [Network]
    func network(id: Int) async throws -> [NetworkPrice]
}

class ChargesServiceAPI: ChargesService {
    func networks() async throws -> [Network] {
        let url = URL(string: "\(endpoint)/network/")!
        let data = try await fetch(url: url)
        return try decoder.decode([Network].self, from: data)
    }

    func network(id: Int) async throws -> [NetworkPrice] {
        let url = URL(string: "\(endpoint)/network/\(id)/")!
        let data = try await fetch(url: url)
        let items = try decoder.decode([NetworkItem].self, from: data)
        return items.map { NetworkPrice(validFrom: Date(timeIntervalSince1970: $0.from), validTo: $0.to == nil ? nil : Date(timeIntervalSince1970: $0.to!), loadTariff: $0.tariffs, networkId: id) }
    }

    func grid() async throws -> [GridPrice] {
        let url = URL(string: "\(endpoint)/grid/")!
        let data = try await fetch(url: url)
        let items = try decoder.decode([GridItem].self, from: data)
        return items.compactMap { item in
            guard let zone = Zone(rawValue: item.zone) else { return nil }
            return GridPrice(zone: zone, validFrom: Date(timeIntervalSince1970: item.from), validTo: item.to == nil ? nil : Date(timeIntervalSince1970: item.to!), transmissionTariff: item.transmissionTariff, systemTariff: item.systemTariff, electricityCharge: item.electricityCharge) }
    }

    private let endpoint = "https://codereaper.github.io/powercast-data/api/energy-charges"
    private let decoder = JSONDecoder()
    private let session = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        return URLSession(configuration: configuration)
    }()
    private func fetch(url: URL) async throws -> Data {
        let (data, base) = try await session.data(from: url)
        let response = base as! HTTPURLResponse // swiftlint:disable:this force_cast

        Flog.info("GET \(url) \(response.statusCode) \(data.count)")

        return data
    }
}

private struct GridItem: Codable {
    let zone: String
    let from: TimeInterval
    let to: TimeInterval?
    let transmissionTariff: Double
    let systemTariff: Double
    let electricityCharge: Double
}

private struct NetworkItem: Codable {
    let from: TimeInterval
    let to: TimeInterval?
    let tariffs: [Double]
}
