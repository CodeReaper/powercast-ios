import Foundation

protocol DataLoadingDelegate: AnyObject {
    func displayFailed()
    func display(progress: Float)
}

class DataLoadingInteractor {
    private let navigation: AppNavigation
    private let prices: EnergyPriceRepository
    private let charges: ChargesRepository
    private let emission: EmissionRepository
    private let state: NetworkState
    private let network: Network

    private weak var delegate: DataLoadingDelegate?

    init(navigation: AppNavigation, delegate: DataLoadingDelegate, prices: EnergyPriceRepository, charges: ChargesRepository, emission: EmissionRepository, state: NetworkState, network: Network) {
        self.navigation = navigation
        self.delegate = delegate
        self.prices = prices
        self.charges = charges
        self.emission = emission
        self.state = state
        self.network = network
    }

    func viewDidLoad() {
        update()
    }

    func retry() {
        update()
    }

    private func update() {
        Task {
            let success: Bool
            let minimumTime = DispatchTime.now() + 0.7

            let today = Calendar.current.startOfDay(for: Date())
            let start = Calendar.current.date(byAdding: .day, value: -16, to: today)!
            let end = Calendar.current.date(byAdding: .day, value: 2, to: today)!
            let dates = DateInterval(start: start, end: end).dates()
            let totalCalls = Float(3 + (dates.count * 2))
            var calls = Float.zero

            DispatchQueue.main.async { [delegate] in delegate?.display(progress: 0) }
            do {
                try await charges.pullNetworks()
                report(&calls, of: totalCalls)

                try await charges.pullGrid()
                report(&calls, of: totalCalls)

                try await charges.pullNetwork(id: network.id)
                report(&calls, of: totalCalls)

                for date in dates {
                    try await prices.pull(zone: network.zone, at: date)
                    report(&calls, of: totalCalls)

                    try await emission.co2.pull(zone: network.zone, at: date)
                    report(&calls, of: totalCalls)
                }
                success = true
            } catch {
                success = false
            }

            DispatchQueue.main.async { [delegate] in delegate?.display(progress: success ? 1 : 0) }

            DispatchQueue.main.asyncAfter(deadline: success ? minimumTime : DispatchTime.now()) { [self] in
                if success {
                    state.select(network: network)
                    navigation.navigate(to: .dashboard)
                } else {
                    delegate?.displayFailed()
                }
            }
        }
    }

    private func report(_ calls: inout Float, of total: Float) {
        calls += 1
        let ratio = calls / total
        DispatchQueue.main.async { [delegate] in delegate?.display(progress: ratio) }
    }
}
