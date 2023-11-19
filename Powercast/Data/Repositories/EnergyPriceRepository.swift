import Foundation
import Combine
import GRDB
import Flogger

class EnergyPriceRepository {
    private let database: DatabaseQueue
    private let service: EnergyPriceService
    private let lookup: ChargesLookup

    init(database: DatabaseQueue, service: EnergyPriceService, lookup: ChargesLookup) {
        self.database = database
        self.service = service
        self.lookup = lookup
    }

    func data(for zone: Zone, in interval: DateInterval) throws -> [EnergyPrice] {
        let items = try database.read { db in
            return try Database.EnergyPrice
                .filter(Database.EnergyPrice.Columns.zone == zone.rawValue)
                .filter(Database.EnergyPrice.Columns.timestamp >= interval.start)
                .filter(Database.EnergyPrice.Columns.timestamp <= interval.end)
                .order(Database.EnergyPrice.Columns.timestamp.desc)
                .fetchAll(db)
        }
        return items.map { EnergyPrice.from(model: $0) }
    }

    func dates(for zone: Zone, inset: Int = -2, offset: Int = 2, now: Date = .now) -> DateInterval {
        let max: Date? = try? database.read { db in
            let item = try Database.EnergyPrice
                .filter(Database.EnergyPrice.Columns.zone == zone.rawValue)
                .order(Database.EnergyPrice.Columns.timestamp.desc)
                .limit(1)
                .fetchOne(db)
            return item?.timestamp
        }
        let latest = Calendar.current.startOfDay(for: max ?? now)
        let today = Calendar.current.startOfDay(for: now)
        let start = Calendar.current.date(byAdding: .day, value: inset, to: latest)!
        let end = Calendar.current.date(byAdding: .day, value: offset, to: today)!
        return DateInterval(start: start, end: end)
    }

    func source(for network: Network) throws -> PriceTableDatasource {
        let max = try database.read { db in
            return try Date.fetchOne(db, Database.EnergyPrice.select(GRDB.max(Database.EnergyPrice.Columns.timestamp)))
        }
        guard let max = max else {
            return EmptyPriceTableDatasource()
        }
        return try CurrentPriceTableDatasource(interval: DateInterval(start: max.date(byAdding: .day, value: -15), end: max), network: network, prices: self, lookup: lookup)
    }

    func pull(zone: Zone, at date: Date) async throws {
        guard let items: [EnergyPrice] = try? await service.data(for: zone, at: date) else { return }

        Flog.info("EnergyPriceRepository: Updating \(items.count) items in \(zone)")

        try await database.write { [items] db in
            try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                var item = $0
                try item.insert(db)
            }
        }
    }
}
