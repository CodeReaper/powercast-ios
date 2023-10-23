import Foundation
import Flogger

protocol ChargesService {
    func data(for zone: Zone) async throws -> ([GridPrice], [NetworkPrice])
}

class ChargesServiceAPI: ChargesService {
    func data(for zone: Zone) async throws -> ([GridPrice], [NetworkPrice]) {
        let url = URL(string: "\(endpoint)/\(zone.rawValue).json")!
        let data = try await fetch(url: url)
        let source = try decoder.decode(Item.self, from: data)

        let gridPrices = source.grid.map { item in
            GridPrice(zone: zone, validFrom: Date(timeIntervalSince1970: item.from), validTo: item.to == nil ? nil : Date(timeIntervalSince1970: item.to!), exchangeRate: source.exchangeRate, vat: source.vat, transmissionTariff: item.transmissionTariff, systemTariff: item.systemTariff, electricityCharge: item.electricityCharge)
        }

        let networkPrices = source.network.flatMap { company in
            company.tariffs.map { item in
                NetworkPrice(zone: zone, id: company.id, name: company.name, validFrom: Date(timeIntervalSince1970: item.from), validTo: item.to == nil ? nil : Date(timeIntervalSince1970: item.to!), loadTariff: item.tariffs)
            }
        }

        return (gridPrices, networkPrices)
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
    let exchangeRate: Double
    let grid: [Grid]
    let network: [Network]

    struct Grid: Codable {
        let from: TimeInterval
        let to: TimeInterval? // swiftlint:disable:this identifier_name
        let transmissionTariff: Double
        let systemTariff: Double
        let electricityCharge: Double
    }

    struct Network: Codable {
        let id: Int
        let name: String
        let tariffs: [Tariffs]
    }

    struct Tariffs: Codable {
        let from: TimeInterval
        let to: TimeInterval? // swiftlint:disable:this identifier_name
        let tariffs: [Double]
    }
}
