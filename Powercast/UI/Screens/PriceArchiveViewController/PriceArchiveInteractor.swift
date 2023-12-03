import UIKit

protocol PriceArchiveDelegate: AnyObject {
    func configure(with interval: DateInterval)
    func show(source: PriceArchiveSource)
}

struct PriceArchiveInteractor {
    private weak var delegate: PriceArchiveDelegate?
    private let network: Network
    private let prices: EnergyPriceRepository
    private let emission: EmissionRepository
    private let lookup: ChargesLookup
    private let range: ClosedRange<Double>?

    init(delegate: PriceArchiveDelegate, network: Network, prices: EnergyPriceRepository, emission: EmissionRepository, lookup: ChargesLookup) {
        self.delegate = delegate
        self.network = network
        self.prices = prices
        self.emission = emission
        self.lookup = lookup
        self.range = try? emission.co2.source(for: network.zone).range
    }

    func viewDidLoad() {
        if let interval = try? lookup.interval(for: network) {
            delegate?.configure(with: interval)
        }
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
            let archivedPrices = await lookup(pricesAt: date, in: network)
            let archivedEmissions = await lookup(emissionsAt: date, in: network)

            DispatchQueue.main.asyncAfter(deadline: minimumTime) { [range, delegate, network, lookup, archivedPrices, archivedEmissions] in
                if let prices = archivedPrices, let emissions = archivedEmissions {
                    let source = PriceArchiveSource(
                        date: date,
                        prices: prices.compactMap { Price.map(prices, at: $0.timestamp, in: network, using: lookup) },
                        emissions: prices.compactMap { Emission.Co2.map(emissions, at: $0.timestamp, in: network.zone) },
                        emissionRange: range
                    )
                    delegate?.show(source: source)
                } else {
                    delegate?.show(source: PriceArchiveSource(date: date, failed: true))
                }
            }
        }
    }

    private func lookup(emissionsAt date: Date, in network: Network) async -> [Co2]? {
        guard date.timeIntervalSince1970 >= 1483225200 else { return nil } // NOTE: hard limit on emission data

        let start = date.startOfDay
        let end = start.date(byAdding: .hour, value: 23).date(byAdding: .hour, value: 1)
        var items = try? emission.co2.data(for: network.zone, in: DateInterval(start: start, end: end))

        if items?.count != 288 {
            for date in DateInterval(start: start.date(byAdding: .day, value: -1), end: start.date(byAdding: .day, value: 1)).dates() {
                try? await emission.co2.pull(zone: network.zone, at: date)
            }
            items = try? emission.co2.data(for: network.zone, in: DateInterval(start: start, end: end))
        }
        return items
    }

    private func lookup(pricesAt date: Date, in network: Network) async -> [EnergyPrice]? {
        let start = date.startOfDay
        let end = start.date(byAdding: .hour, value: 23)
        var items = try? prices.data(for: network.zone, in: DateInterval(start: start, end: end))

        if items?.count != 24 {
            for date in DateInterval(start: start.date(byAdding: .day, value: -1), end: start.date(byAdding: .day, value: 1)).dates() {
                try? await prices.pull(zone: network.zone, at: date)
            }
            items = try? prices.data(for: network.zone, in: DateInterval(start: start, end: end))
        }
        return items
    }
}

struct PriceArchiveSource {
    var itemCount: Int { prices.count }
    func items(at index: Int) -> (Price, Emission.Co2?)? {
        guard index < prices.count else { return nil }
        return (prices[index], emissions[safe: index])
    }

    let date: Date
    let loading: Bool
    let failed: Bool
    let emissionRange: ClosedRange<Double>?
    private let prices: [Price]
    private let emissions: [Emission.Co2]

    init(date: Date, prices: [Price], emissions: [Emission.Co2], emissionRange: ClosedRange<Double>? = nil) {
        self.date = date
        self.loading = false
        self.failed = false
        self.prices = prices
        self.emissions = emissions
        self.emissionRange = emissionRange
    }

    init(date: Date, loading: Bool = false, failed: Bool = false) {
        self.date = date
        self.loading = loading
        self.failed = failed
        self.prices = []
        self.emissions = []
        self.emissionRange = nil
    }

    static func empty() -> Self {
        return PriceArchiveSource(date: .now, prices: [], emissions: [])
    }
}
