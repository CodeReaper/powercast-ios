import Foundation
import Combine
import GRDB
import Flogger

class EnergyPriceRepository {
    private let database: DatabaseQueue
    private let service: EnergyPriceService
    private let repository: ChargesRepository

    init(database: DatabaseQueue, service: EnergyPriceService, repository: ChargesRepository) {
        self.database = database
        self.service = service
        self.repository = repository
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

    func source(for network: Network) throws -> PriceTableDatasource {
        return try TableDatasource(database: database, network: network, repository: repository)
    }

    func refresh() async throws {
        for zone in Zone.allCases {
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

            Flog.info("EnergyPriceRepository: Updating \(items.count) items in \(zone)")

            try await database.write { [items] db in
                try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                    var item = $0
                    try item.insert(db)
                }
            }
        }
    }

    func pull() {
        for zone in Zone.allCases {
            guard let min = try? database.read({ db in
                try Date.fetchOne(db, Database.EnergyPrice.select(GRDB.min(Database.EnergyPrice.Columns.timestamp)).filter(Database.EnergyPrice.Columns.zone == zone.rawValue))
            }) else { continue }

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
    }

    private class TableDatasource: PriceTableDatasource {
        private let database: DatabaseQueue
        private let network: Network
        private let repository: ChargesRepository
        private let items: [[Date]]
        private let sections: [Date]

        init(database: DatabaseQueue, network: Network, repository: ChargesRepository) throws {
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
            self.network = network
            self.repository = repository
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
                    .filter(Database.EnergyPrice.Columns.zone == network.zone.rawValue)
                    .filter(Database.EnergyPrice.Columns.timestamp >= min)
                    .filter(Database.EnergyPrice.Columns.timestamp <= max)
                    .order(Database.EnergyPrice.Columns.timestamp.desc)
                    .fetchAll(db).map {
                        EnergyPrice.from(model: $0)
                    }
            }

            let target = dates[indexPath.item]
            guard
                let models = models,
                let model = models.first(where: { $0.timestamp == target }),
                let charges = try? repository.charges(for: network, at: model.timestamp)
            else { return nil }

            return Price(
                price: charges.format(model.price, at: model.timestamp),
                priceSpan: span(of: models.map({ charges.format($0.price, at: $0.timestamp) })),
                rawPrice: model.price,
                rawPriceSpan: span(of: models.map({ $0.price })),
                fees: charges.fees(at: model.timestamp),
                fixedFees: charges.fixedFees(at: model.timestamp),
                variableFees: charges.variableFees(at: model.timestamp),
                zone: model.zone,
                duration: model.timestamp...model.timestamp.addingTimeInterval(.oneHour)
            )
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

        private func span(of values: [Double]) -> ClosedRange<Double> {
            let high = values.reduce(-Double.infinity, { $0 < $1 ? $1 : $0 })
            let low = values.reduce(Double.infinity, { $0 > $1 ? $1 : $0 })
            return low...high
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
