import Foundation
import Combine
import GRDB

class EnergyPriceRepository {
    private let service: PowercastDataService
    private let database: DatabaseQueue

    private var statusSubject = CurrentValueSubject<Status, Never>(.pending)
    private var refreshTask: Task<Void, Never>?

    lazy var status = statusSubject.eraseToAnyPublisher()

    init(service: PowercastDataService, database: DatabaseQueue) {
        self.service = service
        self.database = database
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

    // swiftlint:disable:next function_body_length
    func refresh() -> Task<Void, Never> {
        let runningTask = refreshTask
        guard runningTask == nil else { return runningTask! }

        statusSubject.send(.syncing)

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

                var current = sources.first?.timestamp ?? Calendar.current.startOfDay(for: Date())
                for source in sources {
                    guard !Task.isCancelled else {
                        statusSubject.send(.cancelled)
                        return
                    }

                    if current != source.timestamp {
                        statusSubject.send(.synced(with: current))
                        current = source.timestamp
                    }

                    let items = try await service.data(for: source.zone, at: source.timestamp)
                    try database.inTransaction { db in
                        try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                            var item = $0
                            try item.insert(db)
                        }
                        try Database.EnergyPriceSource.from(model: source.copy(fetched: true)).update(db)
                        return .commit
                    }
                }

                statusSubject.send(.updated)
            } catch {
                print(error)
                statusSubject.send(.failed)
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
        case updated
        case failed
        case cancelled
    }
}
