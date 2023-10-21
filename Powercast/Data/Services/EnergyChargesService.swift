import Foundation
import Flogger

protocol EnergyChargesService {
    func data(for zone: Zone) async throws -> [Charges]
}

class EnergyChargesServiceAPI: EnergyChargesService {
    func data(for zone: Zone) async throws -> [Charges] {
        let url = URL(string: "\(endpoint)/\(zone.rawValue).json")!
        let data = try await fetch(url: url)
        let list = try decoder.decode([Item].self, from: data)

        // FIXME: make charges

        return []
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

        Flog.info("Powercast Service: GET \(url) \(response.statusCode) \(data.count)")

        return data
    }
}

private struct Item: Codable {
    let vat: Double
    let conversionRate: Double
    let electricityNetwork: [Network]
    let networkCompanies: [Company]

    struct Network: Codable {
        let from: TimeInterval
        let to: TimeInterval // swiftlint:disable:this identifier_name
        let transmissionTariff: Double
        let systemTariff: Double
        let electricityCharge: Double
    }

    struct Company: Codable {
        let name: String
        let tariffs: [Tariffs]
    }

    struct Tariffs: Codable {
        let from: TimeInterval
        let to: TimeInterval? // swiftlint:disable:this identifier_name
        let tariffs: [Double]
    }
}
