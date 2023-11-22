import Foundation
import GRDB

protocol EmissionTableDataSource {
    var range: ClosedRange<Double>? { get }
    var sectionCount: Int { get }
    func numberOfRows(in section: Int) -> Int
    func item(at indexPath: IndexPath) -> Emission.Co2?
}

struct EmptyEmissionTableDataSource: EmissionTableDataSource {
    let range: ClosedRange<Double>? = nil
    let sectionCount: Int = 0
    func numberOfRows(in section: Int) -> Int { 0 }
    func item(at indexPath: IndexPath) -> Emission.Co2? { nil }
}

class CurrentEmissionTableDataSource: EmissionTableDataSource {
    private let zone: Zone
    private let emission: EmissionCo2Repository
    private let items: [[Date]]
    private let sections: [Date]

    let range: ClosedRange<Double>?

    init(interval: DateInterval, zone: Zone, emission: EmissionCo2Repository) throws {
        let calendar = Calendar.current
        guard var tomorrow = calendar.nextDate(after: interval.start, matching: DateComponents(hour: 0), matchingPolicy: .strict), interval.end > interval.start else {
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
            } while date != tomorrow && date <= interval.end
            items.append(weekdays.reversed())

        } while date < interval.end

        self.items = items.reversed()
        self.sections = sections.reversed()
        self.emission = emission
        self.zone = zone
        self.range = try? emission.range(for: zone, in: interval)
    }

    var sectionCount: Int { sections.count }

    func numberOfRows(in section: Int) -> Int {
        return items[section].count
    }

    func item(at indexPath: IndexPath) -> Emission.Co2? {
        guard
            items.count > indexPath.section,
            items[indexPath.section].count > indexPath.row
        else { return nil }

        let dates = items[indexPath.section]
        let date = dates[indexPath.item]

        guard
            let max = dates.max(),
            let min = dates.min(),
            let items = try? emission.data(for: zone, in: DateInterval(start: min, end: max.addingTimeInterval(.oneHour)))
        else { return nil }

        return Emission.Co2.map(items, at: date, in: zone)
    }

    enum Failure: Error {
        case dataMissing
    }
}
