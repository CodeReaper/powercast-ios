// swiftlint:disable nesting
import Foundation
import GRDB

struct EnergyPriceSource: AutoCopy {
    let fetched: Bool
    let zone: Zone
    let timestamp: Date
}

extension EnergyPriceSource {
    static func from(model: Database.EnergyPriceSource) -> EnergyPriceSource {
        return EnergyPriceSource(fetched: model.fetched, zone: model.zone, timestamp: model.timestamp)
    }
}

extension Database {
    struct EnergyPriceSource: Codable, FetchableRecord, MutablePersistableRecord {
        let fetched: Bool
        let zone: Zone
        let timestamp: Date

        enum CodingKeys: String, CodingKey {
            case fetched
            case zone
            case timestamp
        }
    }
}

extension Database.EnergyPriceSource {
    static func from(model: EnergyPriceSource) -> Database.EnergyPriceSource {
        return Database.EnergyPriceSource(fetched: model.fetched, zone: model.zone, timestamp: model.timestamp)
    }
}

extension Database.EnergyPriceSource: TableRecord {
    enum Columns {
        static let fetched = Column(CodingKeys.fetched)
        static let zone = Column(CodingKeys.zone)
        static let timestamp = Column(CodingKeys.timestamp)
    }
}
