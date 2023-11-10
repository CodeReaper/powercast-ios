import Foundation
import Combine
import GRDB
import Flogger

class ChargesRepository: ChargesLookup {
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

    func network(by id: Int) -> Network? {
        guard let item = try? database.read({ db in
            try Database.Network.filter(Database.Network.Columns.id == id).fetchOne(db)
        }) else {
            return nil
        }
        return try? Network.from(model: item)
    }

    func pullGrid() async throws {
        let items = try await service.grid()
        Flog.info("ChargesRepository: Updating \(items.count) grid price rows")
        try await database.write { db in
            try items.map { try Database.GridPrice.from(model: $0) }.forEach { var item = $0; try item.insert(db) }
        }
    }

    func pullNetworks() async throws {
        let items = try await service.networks()
        Flog.info("ChargesRepository: Updating \(items.count) network rows")
        try await database.write { db in
            try items.map { try Database.Network.from(model: $0) }.forEach { var item = $0; try item.upsert(db) }
        }
    }

    func pullNetworks(_ ids: [Int]) async throws {
        for id in ids {
            let items = try await service.network(id: id)
            Flog.info("ChargesRepository: Updating \(items.count) network price rows")
            try await database.write { db in
                try items.map { try Database.NetworkPrice.from(model: $0) }.forEach { var item = $0; try item.insert(db) }
            }
        }
    }

    func pullNetwork(id: Int) async throws {
        try await pullNetworks([id])
    }
}

enum ChargesRepositoryError: Error {
    case noNetworkPrice(id: Int, zone: Zone, date: Date)
    case noGridPrice(zone: Zone, date: Date)
}

protocol ChargesLookup {
    func charges(for network: Network, at date: Date) throws -> Charges
}
