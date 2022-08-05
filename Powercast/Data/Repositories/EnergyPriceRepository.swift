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

    func refresh() -> Task<Void, Never> {
        let runningTask = refreshTask
        guard runningTask == nil else { return runningTask! }

        statusSubject.send(.updating(progress: 0))

        let task = Task {
            do {
                var work: [Zone: [Date]] = [:]
                var completed: [Zone: [Date]] = [:]

                for zone in Zone.allCases {
                    guard !Task.isCancelled else {
                        statusSubject.send(.cancelled)
                        return
                    }

                    let latest = try await service.latest(for: zone)
                    let oldest = try await service.oldest(for: zone)
                    let known = try await database.read { db in
                        return try Date.fetchOne(db, Database.EnergyPrice.select(max(Database.EnergyPrice.Columns.timestamp)).filter(Database.EnergyPrice.Columns.zone == zone.rawValue))
                    }
                    let start = Calendar.current.date(byAdding: .day, value: -1, to: known ?? oldest)!

                    work[zone] = DateInterval(start: max(start, oldest), end: latest).dates()
                    completed[zone] = []
                }

                let workTotal = work.values.map { $0.count }.reduce(0, +)

                for (zone, dates) in work {
                    for date in dates {
                        guard !Task.isCancelled else {
                            statusSubject.send(.cancelled)
                            return
                        }

                        let items = try await service.data(for: zone, at: date)

                        try await database.write { db in
                            try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                                var item = $0
                                try item.insert(db)
                            }
                        }

                        completed[zone]?.append(date)
                        let completedTotal = completed.values.map { $0.count }.reduce(0, +)
                        statusSubject.send(.updating(progress: Double(completedTotal)/Double(workTotal)))
                    }
                }
                statusSubject.send(.updating(progress: 1))
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
        case updating(progress: Double)
        case updated
        case failed
        case cancelled
    }
}
