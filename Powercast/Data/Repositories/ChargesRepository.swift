import Foundation
import Combine
import GRDB
import Flogger

class ChargesRepository {
    private let database: DatabaseQueue
    private let service: ChargesService

    init(database: DatabaseQueue, service: ChargesService) {
        self.database = database
        self.service = service
    }

    func charges(for zone: Zone, at date: Date) throws -> Charges {
        guard let grid = try database.read({ db in
            return try Database.GridPrice
                .filter(Database.GridPrice.Columns.zone == zone.rawValue)
                .filter(Database.GridPrice.Columns.validFrom < date)
                .filter(Database.GridPrice.Columns.validTo >= date || Database.GridPrice.Columns.validTo == nil)
                .fetchOne(db)
        }) else {
            throw ChargesRepositoryError.noGridPrice(zone: zone, date: date)
        }

        guard let network = try database.read({ db in
            return try Database.NetworkPrice
                .filter(Database.NetworkPrice.Columns.zone == zone.rawValue)
                .filter(Database.NetworkPrice.Columns.validFrom < date)
                .filter(Database.NetworkPrice.Columns.validTo >= date || Database.NetworkPrice.Columns.validTo == nil)
                .fetchOne(db)
        }) else {
            throw ChargesRepositoryError.noNetworkPrice(zone: zone, date: date)
        }

        return try Charges.from(GridPrice.from(model: grid), and: NetworkPrice.from(model: network))
    }

    func refresh() async throws {
        for zone in Zone.allCases {
            let (gps, nps) = try await service.data(for: zone)
            Flog.info("ChargesRepository: Updating \(gps.count) grid prices and \(nps.count) network prices for zone \(zone)")

            try await database.write { db in
                try gps.map { try Database.GridPrice.from(model: $0) }.forEach {
                    var item = $0
                    try item.insert(db)
                }
                try nps.map { try Database.NetworkPrice.from(model: $0) }.forEach {
                    var item = $0
                    try item.insert(db)
                }
            }
        }
    }

    func pull() {
        Task {
            try await refresh()
        }
    }
}

enum ChargesRepositoryError: Error {
    case noNetworkPrice(zone: Zone, date: Date)
    case noGridPrice(zone: Zone, date: Date)
}
