import Foundation
import GRDB

struct NetworkPrice {
    let validFrom: Date
    let validTo: Date?
    let loadTariff: [Double]
    let networkId: Int
}

enum NetworkPriceError: Error {
    case nonDecodable(string: String)
}

extension NetworkPrice {
    static func from(model: Database.NetworkPrice) throws -> NetworkPrice {
        guard let data = model.loadTariff.data(using: .utf8) else {
            throw NetworkPriceError.nonDecodable(string: model.loadTariff)
        }
        return NetworkPrice(validFrom: model.validFrom, validTo: model.validTo, loadTariff: try JSONDecoder().decode([Double].self, from: data), networkId: model.networkId)
    }
}

extension Database {
    struct NetworkPrice: Codable, FetchableRecord, MutablePersistableRecord {
        let validFrom: Date
        let validTo: Date?
        let loadTariff: String
        let networkId: Int

        enum CodingKeys: String, CodingKey {
            case validFrom
            case validTo
            case loadTariff
            case networkId
        }
    }
}

extension Database.NetworkPrice {
    static func from(model: NetworkPrice) throws -> Database.NetworkPrice {
        return Database.NetworkPrice(validFrom: model.validFrom, validTo: model.validTo, loadTariff: String(data: try JSONEncoder().encode(model.loadTariff), encoding: .utf8)!, networkId: model.networkId)
    }
}

extension Database.NetworkPrice: TableRecord {
    enum Columns {
        static let validFrom = Column(CodingKeys.validFrom)
        static let validTo = Column(CodingKeys.validTo)
        static let loadTariff = Column(CodingKeys.loadTariff)
        static let networkId = Column(CodingKeys.networkId)
    }
}
