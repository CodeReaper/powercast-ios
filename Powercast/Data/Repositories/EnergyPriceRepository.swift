import Foundation
import Combine
import GRDB
import Flogger

class EnergyPriceRepository {
    private let database: DatabaseQueue
    private let service: PowercastDataService

    init(database: DatabaseQueue, service: PowercastDataService) {
        self.database = database
        self.service = service
    }

    func data(in interval: DateInterval) async throws -> [EnergyPrice] {
        let items = try await database.read { db in
            return try Database.EnergyPrice
                .filter(Database.EnergyPrice.Columns.timestamp >= interval.start)
                .filter(Database.EnergyPrice.Columns.timestamp <= interval.end)
                .fetchAll(db)
        }
        return items.map { EnergyPrice.from(model: $0) }
    }

    func data(for zone: Zone, in interval: DateInterval) async throws -> [EnergyPrice] {
        let items = try await database.read { db in
            return try Database.EnergyPrice
                .filter(Database.EnergyPrice.Columns.zone == zone.rawValue)
                .filter(Database.EnergyPrice.Columns.timestamp >= interval.start)
                .filter(Database.EnergyPrice.Columns.timestamp <= interval.end)
                .fetchAll(db)
        }
        return items.map { EnergyPrice.from(model: $0) }
    }

    func latest(for zone: Zone) throws -> Date? {
        try database.read { db in
            try Date.fetchOne(
                db,
                Database.EnergyPrice
                    .filter(Database.EnergyPrice.Columns.zone == zone.rawValue)
                    .select(max(Database.EnergyPrice.Columns.timestamp))
            )
        }
    }

    func source(for zone: Zone) throws -> PriceTableDatasource {
        return try TableDatasource(database: database, zone: zone)
    }

    func refresh(in zone: Zone) async throws {
        let max = try await database.read { db in
            return try Date.fetchOne(db, Database.EnergyPrice.select(GRDB.max(Database.EnergyPrice.Columns.timestamp)).filter(Database.EnergyPrice.Columns.zone == zone.rawValue))
        } ?? Date()

        let start = Calendar.current.date(byAdding: .day, value: -2, to: max)!
        let end = Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))!

        var items: [EnergyPrice] = []
        for date in start.dates(until: end) {
            guard let list = try? await service.data(for: zone, at: date) else { break }

            items.append(contentsOf: list)
        }

        Flog.info("EnergyPriceRepository: Updating \(items.count) items")

        try await database.write { [items] db in
            try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                var item = $0
                try item.insert(db)
            }
        }
    }

    func pull(zone: Zone) {
        guard let min = try? database.read({ db in
            try Date.fetchOne(db, Database.EnergyPrice.select(GRDB.min(Database.EnergyPrice.Columns.timestamp)).filter(Database.EnergyPrice.Columns.zone == zone.rawValue))
        }) else { return }

        let dates = Date.year2000.dates(until: min).reversed().prefix(30)

        Task {
            for date in dates {
                let items = try await service.data(for: zone, at: date)
                try await database.write { db in
                    try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                        var item = $0
                        try item.insert(db)
                    }
                }
            }
        }
    }

    private class TableDatasource: PriceTableDatasource {
        private let database: DatabaseQueue
        private let zone: Zone
        private let items: [[Date]]
        private let sections: [Date]

        init(database: DatabaseQueue, zone: Zone) throws {
            let max = try database.read { db in
                return try Date.fetchOne(db, Database.EnergyPrice.select(GRDB.max(Database.EnergyPrice.Columns.timestamp)))
            }
            let min = try database.read { db in
                return try Date.fetchOne(db, Database.EnergyPrice.select(GRDB.min(Database.EnergyPrice.Columns.timestamp)))
            }

            let calendar = Calendar.current
            guard let max = max, let min = min, var tomorrow = calendar.nextDate(after: min, matching: DateComponents(hour: 0), matchingPolicy: .strict), max > min else {
                throw Failure.dataMissing
            }

            var date = tomorrow
            var items: [[Date]] = []
            var sections: [Date] = []
            repeat {
                sections.append(tomorrow)
                tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!

                var weekdays: [Date] = []
                repeat {
                    weekdays.append(date)
                    date = calendar.date(byAdding: .hour, value: 1, to: date)!
                } while date != tomorrow && date <= max
                items.append(weekdays.reversed())

            } while date < max

            self.items = items.reversed()
            self.sections = sections.reversed()
            self.database = database
            self.zone = zone
        }

        var sectionCount: Int { sections.count }

        func numberOfRows(in section: Int) -> Int {
            return items[section].count
        }

        func item(at indexPath: IndexPath) -> Price? {
            let dates = items[indexPath.section]
            guard let max = dates.max(), let min = dates.min() else { return nil }

            let models = try? database.read { db in
                return try Database.EnergyPrice
                    .filter(Database.EnergyPrice.Columns.zone == zone.rawValue)
                    .filter(Database.EnergyPrice.Columns.timestamp >= min)
                    .filter(Database.EnergyPrice.Columns.timestamp <= max)
                    .order(Database.EnergyPrice.Columns.timestamp.desc)
                    .fetchAll(db).map {
                        EnergyPrice.from(model: $0)
                    }
            }

            let target = dates[indexPath.item]
            guard let models = models, let model = models.first(where: { $0.timestamp == target }) else { return nil }

            let high = models.reduce(-Double.infinity, { $0 < $1.price ? $1.price : $0 })
            let low = models.reduce(Double.infinity, { $0 > $1.price ? $1.price : $0 })

            return Price(price: model.price, priceSpan: low...high, zone: model.zone, duration: model.timestamp...model.timestamp.addingTimeInterval(.oneHour))
        }

        func activeIndexPath(at date: Date) -> IndexPath? {
            for (section, rows) in items.enumerated() {
                for (row, item) in rows.enumerated() where date >= item && date < item.addingTimeInterval(.oneHour) {
                    return IndexPath(row: row, section: section)
                }
            }
            return nil
        }

        enum Failure: Error {
            case dataMissing
        }
    }
}

protocol PriceTableDatasource {
    var sectionCount: Int { get }
    func numberOfRows(in section: Int) -> Int
    func item(at indexPath: IndexPath) -> Price?
    func activeIndexPath(at date: Date) -> IndexPath?
}

struct EmptyPriceTableDatasource: PriceTableDatasource {
    let sectionCount: Int = 0
    func numberOfRows(in section: Int) -> Int { 0 }
    func item(at indexPath: IndexPath) -> Price? { nil }
    func activeIndexPath(at date: Date) -> IndexPath? { nil }
}
