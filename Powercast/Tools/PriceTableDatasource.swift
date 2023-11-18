import Foundation
import GRDB

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

class CurrentPriceTableDatasource: PriceTableDatasource {
    private let network: Network
    private let lookup: ChargesLookup
    private let prices: EnergyPriceRepository
    private let items: [[Date]]
    private let sections: [Date]

    init(interval: DateInterval, network: Network, prices: EnergyPriceRepository, lookup: ChargesLookup) throws {
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
        self.prices = prices
        self.network = network
        self.lookup = lookup
    }

    var sectionCount: Int { sections.count }

    func numberOfRows(in section: Int) -> Int {
        return items[section].count
    }

    func item(at indexPath: IndexPath) -> Price? {
        guard
            items.count > indexPath.section,
            items[indexPath.section].count > indexPath.row
        else { return nil }

        let dates = items[indexPath.section]
        guard
            let max = dates.max(),
            let min = dates.min(),
            let models = try? prices.data(for: network.zone, in: DateInterval(start: min, end: max))
        else { return nil }

        let target = dates[indexPath.item]
        guard
            let model = models.first(where: { $0.timestamp == target }),
            let charges = try? lookup.charges(for: network, at: model.timestamp)
        else { return nil }

        return Price(
            price: charges.format(model.price, at: model.timestamp),
            priceSpan: models.map({ charges.format($0.price, at: $0.timestamp) }).span(),
            rawPrice: charges.convert(model.price, at: model.timestamp),
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
}
