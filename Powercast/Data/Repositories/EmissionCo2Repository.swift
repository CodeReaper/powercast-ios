import Foundation
import GRDB
import Flogger

class EmissionCo2Repository {
    private let database: DatabaseQueue
    private let service: EmissionService

    init(database: DatabaseQueue, service: EmissionService) {
        self.database = database
        self.service = service
    }

    func range(for zone: Zone, in interval: DateInterval) throws -> ClosedRange<Double>? {
        let items = try database.read { db in
            return try Database.Co2
                .filter(Database.Co2.Columns.zone == zone.rawValue)
                .filter(Database.Co2.Columns.timestamp >= interval.start)
                .filter(Database.Co2.Columns.timestamp < interval.end)
                .order(Database.Co2.Columns.timestamp.desc)
                .fetchAll(db)
        }
        return items.map { $0.amount }.span()
    }

    func data(for zone: Zone, in interval: DateInterval) throws -> [Co2] {
        let items = try database.read { db in
            return try Database.Co2
                .filter(Database.Co2.Columns.zone == zone.rawValue)
                .filter(Database.Co2.Columns.timestamp >= interval.start)
                .filter(Database.Co2.Columns.timestamp < interval.end)
                .order(Database.Co2.Columns.timestamp.desc)
                .fetchAll(db)
        }
        return items.map { Co2.from(model: $0) }
    }

    func dates(for zone: Zone, inset: Int = -2, offset: Int = 2, now: Date = .now) -> DateInterval {
        let max: Date? = try? database.read { db in
            let item = try Database.Co2
                .filter(Database.Co2.Columns.zone == zone.rawValue)
                .order(Database.Co2.Columns.timestamp.desc)
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

    func source(for zone: Zone) throws -> EmissionTableDataSource {
        let max = try database.read { db in
            return try Date.fetchOne(db, Database.Co2.select(GRDB.max(Database.Co2.Columns.timestamp)))
        }
        guard let max = max else {
            return EmptyEmissionTableDataSource()
        }
        return try CurrentEmissionTableDataSource(interval: DateInterval(start: max.date(byAdding: .day, value: -15), end: max), zone: zone, emission: self)
    }

    func pull(zone: Zone, at date: Date) async throws {
        guard let items: [Co2] = try? await service.co2Data(for: zone, at: date) else { return }

        Flog.debug("EmissionRepository: Updating \(items.count) co2 items in \(zone)")

        try await database.write { [items] db in
            try items.map { Database.Co2.from(model: $0) }.forEach {
                var item = $0
                try item.insert(db)
            }
        }
    }
}
