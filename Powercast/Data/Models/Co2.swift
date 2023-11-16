// swiftlint:disable nesting
import Foundation
import GRDB

struct Co2 {
    /// CO2 in gram per kWh
    let amount: Double
    let zone: Zone
    let timestamp: Date
}

extension Co2 {
    static func from(model: Database.Co2) -> Co2 {
        return Co2(amount: model.amount, zone: model.zone, timestamp: model.timestamp)
    }
}

extension Database {
    struct Co2: Codable, FetchableRecord, MutablePersistableRecord {
        /// CO2 in gram per kWh
        let amount: Double
        let zone: Zone
        let timestamp: Date

        enum CodingKeys: String, CodingKey {
            case amount
            case zone
            case timestamp
        }
    }
}

extension Database.Co2 {
    static func from(model: Co2) -> Database.Co2 {
        return Database.Co2(amount: model.amount, zone: model.zone, timestamp: model.timestamp)
    }
}

extension Database.Co2: TableRecord {
    enum Columns {
        static let amount = Column(CodingKeys.amount)
        static let zone = Column(CodingKeys.zone)
        static let timestamp = Column(CodingKeys.timestamp)
    }
}
// swiftlint:enable nesting
