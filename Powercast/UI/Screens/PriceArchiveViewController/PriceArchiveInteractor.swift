import Foundation

protocol PriceArchiveDelegate: AnyObject {
    func show(source: PriceArchiveSource)
}

struct PriceArchiveInteractor {
    private weak var delegate: PriceArchiveDelegate?
    private let prices: EnergyPriceRepository
    private let emission: EmissionRepository

    init(delegate: PriceArchiveDelegate, prices: EnergyPriceRepository, emission: EmissionRepository) {
        self.delegate = delegate
        self.prices = prices
        self.emission = emission
    }

    func viewWillAppear() {
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
            let success: Bool
            do {
//                try await charges.pullNetworks()
//                try await charges.pullGrid()
//                try await charges.pullNetwork(id: network.id)
//
//                let today = Calendar.current.startOfDay(for: Date())
//                let start = Calendar.current.date(byAdding: .day, value: -14, to: today)!
//                let end = Calendar.current.date(byAdding: .day, value: 2, to: today)!
//                for date in DateInterval(start: start, end: end).dates() {
//                    try await prices.pull(zone: network.zone, at: date)
//                    try await emission.co2.pull(zone: network.zone, at: date)
//                }
                success = true
            } catch {
                success = false
            }

            DispatchQueue.main.asyncAfter(deadline: success ? minimumTime : DispatchTime.now()) { [self] in
//                if success {
//                    state.select(network: network)
//                    navigation.navigate(to: .dashboard)
//                } else {
//                    delegate?.displayFailed()
//                }
            }
        }
        // FIXME:
    }
}

struct PriceArchiveSource {
    var itemCount: Int { loading ? 1 : prices.count }

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
