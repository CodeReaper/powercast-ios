import Foundation
import GRDB

class EnergyPriceRepository {
    private let service: PowercastDataService
    private let database: DatabaseQueue

    init(service: PowercastDataService, database: DatabaseQueue) {
        self.service = service
        self.database = database
    }

    func refresh() async throws {
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
