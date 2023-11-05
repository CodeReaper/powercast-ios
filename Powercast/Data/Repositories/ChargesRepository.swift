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

    func charges(for network: Network, at date: Date) throws -> Charges {
        guard let grid = try database.read({ db in
            return try Database.GridPrice
                .filter(Database.GridPrice.Columns.zone == network.zone.rawValue)
                .filter(Database.GridPrice.Columns.validFrom < date)
                .filter(Database.GridPrice.Columns.validTo >= date || Database.GridPrice.Columns.validTo == nil)
                .fetchOne(db)
        }) else {
            throw ChargesRepositoryError.noGridPrice(zone: network.zone, date: date)
        }

        guard let network = try database.read({ db in
            return try Database.NetworkPrice
                .filter(Database.NetworkPrice.Columns.networkId == network.id)
                .filter(Database.NetworkPrice.Columns.validFrom < date)
                .filter(Database.NetworkPrice.Columns.validTo >= date || Database.NetworkPrice.Columns.validTo == nil)
                .fetchOne(db)
        }) else {
            throw ChargesRepositoryError.noNetworkPrice(id: network.id, zone: network.zone, date: date)
        }

        return try Charges.from(GridPrice.from(model: grid), and: NetworkPrice.from(model: network))
    }

    func refresh() async throws {
        let networks = try await service.networks()
        Flog.info("ChargesRepository: Updating \(networks.count) network rows")
        try await database.write { db in
            try networks.map { try Database.Network.from(model: $0) }.forEach { var item = $0; try item.insert(db) }
        }

        let grid = try await service.grid()
        Flog.info("ChargesRepository: Updating \(grid.count) grid price rows")
        try await database.write { db in
            try grid.map { try Database.GridPrice.from(model: $0) }.forEach { var item = $0; try item.insert(db) }
        }

        for item in networks {
            let network = try await service.network(id: item.id)
            Flog.info("ChargesRepository: Updating \(network.count) network price rows")
            try await database.write { db in
                try network.map { try Database.NetworkPrice.from(model: $0) }.forEach { var item = $0; try item.insert(db) }
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
    case noNetworkPrice(id: Int, zone: Zone, date: Date)
    case noGridPrice(zone: Zone, date: Date)
}
