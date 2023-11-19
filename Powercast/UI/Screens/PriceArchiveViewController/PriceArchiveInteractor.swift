import UIKit

protocol PriceArchiveDelegate: AnyObject {
    func show(source: PriceArchiveSource)
}

struct PriceArchiveInteractor {
    private weak var delegate: PriceArchiveDelegate?
    private let network: Network
    private let prices: EnergyPriceRepository
    private let emission: EmissionRepository
    private let lookup: ChargesLookup

    init(delegate: PriceArchiveDelegate, network: Network, prices: EnergyPriceRepository, emission: EmissionRepository, lookup: ChargesLookup) {
        self.delegate = delegate
        self.network = network
        self.prices = prices
        self.emission = emission
        self.lookup = lookup
    }

    func viewDidLoad() {
        delegate?.show(source: PriceArchiveSource(date: .now, loading: true))
        load(.now)
    }

    func select(date: Date) {
        delegate?.show(source: PriceArchiveSource(date: date, loading: true))
        load(date)
    }

    private func load(_ date: Date) {
        Task {
            let minimumTime = DispatchTime.now() + 0.7
            var archivedPrices: [EnergyPrice]?
            var archivedEmissions: [Co2]?
            do {
                let start = date.startOfDay
                let end = start.date(byAdding: .hour, value: 23)
                let emissionEnd = end.date(byAdding: .hour, value: 1)
                archivedPrices = try prices.data(for: network.zone, in: DateInterval(start: start, end: end))
                archivedEmissions = try emission.co2.data(for: network.zone, in: DateInterval(start: start, end: emissionEnd))
                if archivedPrices?.count != 24 || archivedEmissions?.count != 288 {
                    let duration = DateInterval(start: start.date(byAdding: .day, value: -1), end: start.date(byAdding: .day, value: 1))
                    for date in duration.dates() {
                        try await prices.pull(zone: network.zone, at: date)
                        try await emission.co2.pull(zone: network.zone, at: date)
                    }
                    archivedPrices = try prices.data(for: network.zone, in: DateInterval(start: start, end: end))
                    archivedEmissions = try emission.co2.data(for: network.zone, in: DateInterval(start: start, end: emissionEnd))
                }
            } catch {
                archivedPrices = nil
                archivedEmissions = nil
            }

            DispatchQueue.main.asyncAfter(deadline: minimumTime) { [delegate, network, lookup, archivedPrices, archivedEmissions] in
                if let prices = archivedPrices, let emissions = archivedEmissions {
                    let source = PriceArchiveSource(
                        date: date,
                        prices: prices.compactMap { Price.map(prices, at: $0.timestamp, in: network, using: lookup) },
                        emissions: prices.compactMap { Emission.Co2.map(emissions, at: $0.timestamp, in: network.zone) }
                    )
                    delegate?.show(source: source)
                } else {
                    delegate?.show(source: PriceArchiveSource(date: date, failed: true))
                }
            }
        }
    }
}

struct PriceArchiveSource {
    var separatorStyle: UITableViewCell.SeparatorStyle { loading || failed ? .none : .singleLine }
    var itemCount: Int { loading || failed ? 1 : prices.count }
    func items(at index: Int) -> (Price, Emission.Co2)? {
        guard index < prices.count && index < emissions.count else { return nil }
        return (prices[index], emissions[index])
    }

    let date: Date
    let loading: Bool
    let failed: Bool
    private let prices: [Price]
    private let emissions: [Emission.Co2]

    init(date: Date, prices: [Price], emissions: [Emission.Co2]) {
        self.date = date
        self.loading = false
        self.failed = false
        self.prices = prices
        self.emissions = emissions
    }

    init(date: Date, loading: Bool = false, failed: Bool = false) {
        self.date = date
        self.loading = loading
        self.failed = failed
        self.prices = []
        self.emissions = []
    }

    static func empty() -> Self {
        return PriceArchiveSource(date: .now, prices: [], emissions: [])
    }
}
