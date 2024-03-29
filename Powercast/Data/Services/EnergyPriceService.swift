import Foundation
import Flogger

protocol EnergyPriceService {
    func data(for zone: Zone, at date: Date) async throws -> [EnergyPrice]
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

    private func fetch(url: URL) async throws -> Data {
        let (data, base) = try await session.data(from: url)
        let response = base as! HTTPURLResponse // swiftlint:disable:this force_cast

        Flog.info("GET \(url) \(response.statusCode) \(data.count)")

        return data
    }
}

private struct Item: Codable {
    let euro: Double
    let timestamp: TimeInterval
}
