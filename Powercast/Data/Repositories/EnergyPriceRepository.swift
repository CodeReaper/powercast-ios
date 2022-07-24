import Foundation
import Combine
import GRDB

class EnergyPriceRepository {
    private let service: PowercastDataService
    private let database: DatabaseQueue

    private var statusSubject = PassthroughSubject<Status, Never>()

    lazy var status = statusSubject.eraseToAnyPublisher()

    init(service: PowercastDataService, database: DatabaseQueue) {
        self.service = service
        self.database = database

        statusSubject.send(.unknown)
    }

    func refresh() -> Task<Void, Never> {
        statusSubject.send(.updating(progress: 0))

        return Task {
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

                    work[zone] = Date.dates(from: start, to: latest)
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
        }
    }

    enum Status {
        case unknown
        case updating(progress: Double)
        case updated
        case failed
        case cancelled
    }
}

private extension Date {
    static func dates(from fromDate: Date, to toDate: Date) -> [Date] {
        var dates: [Date] = []
        var date = fromDate

        while date <= toDate {
            dates.append(date)
            guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else { break }
            date = newDate
        }
        return dates
    }
}
