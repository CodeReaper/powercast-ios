import Foundation
import GRDB

struct NetworkPrice {
    let zone: Zone
    let id: Int
    let name: String
    let validFrom: Date
    let validTo: Date?
    let loadTariff: [Double]
}

enum NetworkPriceError: Error {
    case nonDecodable(string: String)
}

extension NetworkPrice {
    static func from(model: Database.NetworkPrice) throws -> NetworkPrice {
        guard let data = model.loadTariff.data(using: .utf8) else {
            throw NetworkPriceError.nonDecodable(string: model.loadTariff)
        }
        return NetworkPrice(zone: model.zone, id: model.id, name: model.name, validFrom: model.validFrom, validTo: model.validTo, loadTariff: try JSONDecoder().decode([Double].self, from: data))
    }
}

extension Database {
    struct NetworkPrice: Codable, FetchableRecord, MutablePersistableRecord {
        let zone: Zone
        let id: Int
        let name: String
        let validFrom: Date
        let validTo: Date?
        let loadTariff: String

        enum CodingKeys: String, CodingKey {
            case zone
            case id
            case name
            case validFrom
            case validTo
            case loadTariff
        }
    }
}

extension Database.NetworkPrice {
    static func from(model: NetworkPrice) throws -> Database.NetworkPrice {
        return Database.NetworkPrice(zone: model.zone, id: model.id, name: model.name, validFrom: model.validFrom, validTo: model.validTo, loadTariff: String(data: try JSONEncoder().encode(model.loadTariff), encoding: .utf8)!)
    }
}

extension Database.NetworkPrice: TableRecord {
    enum Columns {
        static let zone = Column(CodingKeys.zone)
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let validFrom = Column(CodingKeys.validFrom)
        static let validTo = Column(CodingKeys.validTo)
        static let loadTariff = Column(CodingKeys.loadTariff)
    }
}
