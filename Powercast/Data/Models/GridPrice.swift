import Foundation
import GRDB

struct GridPrice {
    let zone: Zone
    let validFrom: Date
    let validTo: Date?
    let exchangeRate: Double
    let vat: Double
    let transmissionTariff: Double
    let systemTariff: Double
    let electricityCharge: Double
}

extension GridPrice {
    static func from(model: Database.GridPrice) throws -> GridPrice {
        return GridPrice(zone: model.zone, validFrom: model.validFrom, validTo: model.validTo, exchangeRate: model.exchangeRate, vat: model.vat, transmissionTariff: model.transmissionTariff, systemTariff: model.systemTariff, electricityCharge: model.electricityCharge)
    }
}

extension Database {
    struct GridPrice: Codable, FetchableRecord, MutablePersistableRecord {
        let zone: Zone
        let validFrom: Date
        let validTo: Date?
        let exchangeRate: Double
        let vat: Double
        let transmissionTariff: Double
        let systemTariff: Double
        let electricityCharge: Double

        enum CodingKeys: String, CodingKey {
            case zone
            case validFrom
            case validTo
            case exchangeRate
            case vat
            case transmissionTariff
            case systemTariff
            case electricityCharge
        }
    }
}

extension Database.GridPrice {
    static func from(model: GridPrice) throws -> Database.GridPrice {
        return Database.GridPrice(zone: model.zone, validFrom: model.validFrom, validTo: model.validTo, exchangeRate: model.exchangeRate, vat: model.vat, transmissionTariff: model.transmissionTariff, systemTariff: model.systemTariff, electricityCharge: model.electricityCharge)
    }
}

extension Database.GridPrice: TableRecord {
    enum Columns {
        static let zone = Column(CodingKeys.zone)
        static let validFrom = Column(CodingKeys.validFrom)
        static let validTo = Column(CodingKeys.validTo)
        static let exchangeRate = Column(CodingKeys.exchangeRate)
        static let vat = Column(CodingKeys.vat)
        static let transmissionTariff = Column(CodingKeys.transmissionTariff)
        static let systemTariff = Column(CodingKeys.systemTariff)
        static let electricityCharge = Column(CodingKeys.electricityCharge)
    }
}
