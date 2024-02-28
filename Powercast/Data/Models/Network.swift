import Foundation
import GRDB

struct Network: Codable {
    let id: Int
    let name: String
    let zone: Zone
}

extension Network {
    static func from(model: Database.Network) throws -> Network {
        return Network(id: model.id, name: model.name, zone: model.zone)
    }
}

extension Database {
    struct Network: Codable, Identifiable, FetchableRecord, MutablePersistableRecord {
        let id: Int
        let name: String
        let zone: Zone

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case zone
        }
    }
}

extension Database.Network {
    static func from(model: Network) throws -> Database.Network {
        return Database.Network(id: model.id, name: model.name, zone: model.zone)
    }
}

extension Database.Network: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let zone = Column(CodingKeys.zone)
    }
}
