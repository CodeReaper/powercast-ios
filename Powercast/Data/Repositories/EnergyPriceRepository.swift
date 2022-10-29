import Foundation
import Combine
import GRDB

class EnergyPriceRepository {
    private let factory: PowercastDataServiceFactory
    private let database: DatabaseQueue

    private var statusSubject = CurrentValueSubject<Status, Never>(.pending)
    private var refreshTask: Task<Void, Never>?
    private var sink: AnyCancellable?

    lazy var publishedStatus = statusSubject.eraseToAnyPublisher()

    var status: Status { statusSubject.value }

    init(factory: PowercastDataServiceFactory, database: DatabaseQueue) {
        self.factory = factory
        self.database = database

        sink = publishedStatus.receive(on: DispatchQueue.main).sink(receiveValue: { status in
            switch status {
            case .syncing, .pending, .synced:
                break
            case .updated(let newData):
                print("PriceSync: Finished - newData: \(newData)")
            case .failed(let error):
                switch (error as? URLError)?.code {
                case .some(.timedOut):
                    print("PriceSync: Timed out.")
                default:
                    print("PriceSync: Failed: \(error)")
                }
            case .cancelled:
                print("PriceSync: Was cancelled")
            }
        })
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

    @discardableResult // swiftlint:disable:next function_body_length
    func refresh(mode: PowercastDataServiceFactory.Mode = .ephemeral) -> Task<Void, Never> {
        let runningTask = refreshTask
        guard runningTask == nil else { return runningTask! }

        statusSubject.send(.syncing)

        let service = factory.build(mode)

        let task = Task {
            do {
                for zone in Zone.allCases {
                    guard !Task.isCancelled else {
                        statusSubject.send(.cancelled)
                        return
                    }

                    let latest = try await service.latest(for: zone)
                    let oldest = try await service.oldest(for: zone)
                    let known = try await database.read { db in
                        return try Date.fetchOne(db, Database.EnergyPriceSource.select(max(Database.EnergyPriceSource.Columns.timestamp)).filter(Database.EnergyPriceSource.Columns.zone == zone.rawValue))
                    }
                    let start = Calendar.current.date(byAdding: .day, value: -1, to: known ?? oldest)!

                    try database.inTransaction { db in
                        for var item in DateInterval(start: max(start, oldest), end: latest).dates().map({ Database.EnergyPriceSource(fetched: false, zone: zone, timestamp: $0) }) {
                            try item.insert(db)
                        }
                        return .commit
                    }
                }

                let sources = try await database.read { db in
                    try Database.EnergyPriceSource.fetchAll(db, Database.EnergyPriceSource.filter(Database.EnergyPriceSource.Columns.fetched == false).order(Database.EnergyPriceSource.Columns.timestamp.desc))
                }.map { EnergyPriceSource.from(model: $0) }

                var hasNewData = false
                var current = sources.first?.timestamp ?? Calendar.current.startOfDay(for: Date())
                for source in sources {
                    guard !Task.isCancelled else {
                        statusSubject.send(.cancelled)
                        return
                    }

                    let items = try await service.data(for: source.zone, at: source.timestamp)
                    try database.inTransaction { db in
                        try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                            var item = $0
                            hasNewData = try hasNewData || !item.exists(db)
                            try item.insert(db)
                        }
                        try Database.EnergyPriceSource.from(model: source.copy(fetched: true)).update(db)
                        return .commit
                    }

                    if current != source.timestamp {
                        statusSubject.send(.synced(with: current))
                        current = source.timestamp
                    }
                }

                statusSubject.send(.updated(newData: hasNewData))
            } catch {
                statusSubject.send(.failed(error: error))
            }

            refreshTask = nil
        }
        refreshTask = task
        return task
    }

    enum Status {
        case pending
        case syncing
        case synced(with: Date)
        case updated(newData: Bool)
        case failed(error: Error)
        case cancelled
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

            guard let models = models, dates.count == models.count else { return nil }

            let model = models[indexPath.item]

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
