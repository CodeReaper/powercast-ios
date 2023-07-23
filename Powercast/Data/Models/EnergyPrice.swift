// swiftlint:disable nesting
import Foundation
import GRDB

struct EnergyPrice {
    let price: Double
    let zone: Zone
    let timestamp: Date
}

extension EnergyPrice {
    static func from(model: Database.EnergyPrice) -> EnergyPrice {
        return EnergyPrice(price: model.price, zone: model.zone, timestamp: model.timestamp)
    }
}

extension Database {
    struct EnergyPrice: Codable, FetchableRecord, MutablePersistableRecord {
        let price: Double
        let zone: Zone
        let timestamp: Date

        enum CodingKeys: String, CodingKey {
            case price
            case zone
            case timestamp
        }
    }
}

extension Database.EnergyPrice {
    static func from(model: EnergyPrice) -> Database.EnergyPrice {
        return Database.EnergyPrice(price: model.price, zone: model.zone, timestamp: model.timestamp)
    }
}

extension Database.EnergyPrice: TableRecord {
    enum Columns {
        static let price = Column(CodingKeys.price)
        static let zone = Column(CodingKeys.zone)
        static let timestamp = Column(CodingKeys.timestamp)
    }
}
// swiftlint:enable nesting
