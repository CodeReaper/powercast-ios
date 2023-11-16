import Foundation
import Flogger

protocol EmissionService {
    func co2Data(for zone: Zone, at date: Date) async throws -> [Co2]
}

class EmissionServiceAPI: EmissionService {
    private let endpoint = "https://codereaper.github.io/powercast-data/api/emission"
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

    func co2Data(for zone: Zone, at date: Date) async throws -> [Co2] {
        let url = URL(string: "\(endpoint)/co2/\(formatter.string(from: date))/\(zone.rawValue).json")!
        let data = try await fetch(url: url)
        let list = try decoder.decode([Co2Item].self, from: data)
        return list.map {
            Co2(amount: $0.co2, zone: zone, timestamp: Date(timeIntervalSince1970: $0.timestamp))
        }
    }

    private func fetch(url: URL) async throws -> Data {
        let (data, base) = try await session.data(from: url)
        let response = base as! HTTPURLResponse // swiftlint:disable:this force_cast

        Flog.info("GET \(url) \(response.statusCode) \(data.count)")

        return data
    }
}

private struct Co2Item: Codable {
    let co2: Double
    let timestamp: TimeInterval
}
