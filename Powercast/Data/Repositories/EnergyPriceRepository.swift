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

    func refresh() {
        statusSubject.send(.updating)

        Task {
            do {
                for zone in Zone.allCases {
                    let latest = await service.latest(for: zone)
                    let oldest = await service.oldest(for: zone)
                    let dates = Date.dates(from: oldest, to: latest)
                    for date in dates {
                        let items = await service.data(for: zone, at: date)
                        try await database.write { db in
                            try items.map { Database.EnergyPrice.from(model: $0) }.forEach {
                                var item = $0
                                try item.insert(db)
                            }
                        }
                    }
                }
                statusSubject.send(.updated)
            } catch {
                print(error)
                statusSubject.send(.failed)
            }
        }
    }

    enum Status {
        case unknown
        case updating
        case updated
        case failed
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
