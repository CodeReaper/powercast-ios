import Foundation
import GRDB
import Flogger

class ChargesRepository: ChargesLookup {
    private let database: DatabaseQueue
    private let service: ChargesService

    init(database: DatabaseQueue, service: ChargesService) {
        self.database = database
        self.service = service
    }

    func interval(for network: Network) throws -> DateInterval {
        try database.read { db in
            let gridEnd = try Database.GridPrice.filter(Database.GridPrice.Columns.validFrom == Date.fetchOne(db, Database.GridPrice.select(max(Database.GridPrice.Columns.validFrom)))!).fetchOne(db)?.validTo
            let grid = DateInterval(
                start: try Date.fetchOne(db, Database.GridPrice.select(min(Database.GridPrice.Columns.validFrom)))!,
                end: gridEnd ?? .distantFuture
            )

            let networkEnd = try Database.NetworkPrice.filter(Database.NetworkPrice.Columns.validFrom == Date.fetchOne(db, Database.NetworkPrice.select(max(Database.NetworkPrice.Columns.validFrom)))!).fetchOne(db)?.validTo
            let network = DateInterval(
                start: try Date.fetchOne(db, Database.NetworkPrice.select(min(Database.NetworkPrice.Columns.validFrom)))!,
                end: networkEnd ?? .distantFuture
            )

            return DateInterval(start: max(grid.start, network.start), end: min(grid.end, network.end))
        }
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

    func gridPrices(by zone: Zone) throws -> [GridPrice] {
        try database.read {
            try Database.GridPrice
                .filter(Database.GridPrice.Columns.zone == zone.rawValue)
                .order(Database.GridPrice.Columns.validFrom.desc)
                .fetchAll($0).map { try GridPrice.from(model: $0) }
        }
    }

    func networkPrices(by id: Int) throws -> [NetworkPrice] {
        try database.read {
            try Database.NetworkPrice
                .filter(Database.NetworkPrice.Columns.networkId == id)
                .order(Database.NetworkPrice.Columns.validFrom.desc)
                .fetchAll($0).map { try NetworkPrice.from(model: $0) }
        }
    }

    func networks() throws -> [Network] {
        try database.read {
            try Database.Network.fetchAll($0).map { try Network.from(model: $0) }
        }
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
        Flog.debug("ChargesRepository: Updating \(items.count) grid price rows")
        try await database.write { db in
            try items.map { try Database.GridPrice.from(model: $0) }.forEach { var item = $0; try item.upsert(db) }
        }
    }

    func pullNetworks() async throws {
        let known = try networks().map { $0.id }
        let items = try await service.networks()
        let removables = Set(known).subtracting(Set(items.map { $0.id }))
        Flog.debug("ChargesRepository: Updating \(items.count) network rows and removing \(removables.count) rows")
        try await database.write { db in
            try items.map { try Database.Network.from(model: $0) }.forEach { var item = $0; try item.upsert(db) }
            try Database.Network.deleteAll(db, ids: removables)
        }
    }

    func pullNetworks(_ ids: [Int]) async throws {
        for id in ids {
            let items = try await service.network(id: id)
            Flog.debug("ChargesRepository: Updating \(items.count) network price rows")
            try await database.write { db in
                try items.map { try Database.NetworkPrice.from(model: $0) }.forEach { var item = $0; try item.upsert(db) }
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
    func interval(for network: Network) throws -> DateInterval
    func charges(for network: Network, at date: Date) throws -> Charges
}
