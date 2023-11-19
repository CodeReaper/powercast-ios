import Foundation
import Combine

protocol DataLoadingDelegate: AnyObject {
    func displayFailed()
}

class DataLoadingInteractor {
    private let navigation: AppNavigation
    private let prices: EnergyPriceRepository
    private let charges: ChargesRepository
    private let emission: EmissionRepository
    private let state: StateRepository
    private let network: Network

    private var statusSink: AnyCancellable?
    private var refreshTask: Task<Void, Never>?

    private weak var delegate: DataLoadingDelegate?

    init(navigation: AppNavigation, delegate: DataLoadingDelegate, prices: EnergyPriceRepository, charges: ChargesRepository, emission: EmissionRepository, state: StateRepository, network: Network) {
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
            let minimumTime = DispatchTime.now() + 2
            let success: Bool
            do {
                try await charges.pullNetworks()
                try await charges.pullGrid()
                try await charges.pullNetwork(id: network.id)

                let today = Calendar.current.startOfDay(for: Date())
                let start = Calendar.current.date(byAdding: .day, value: -16, to: today)!
                let end = Calendar.current.date(byAdding: .day, value: 2, to: today)!
                for date in DateInterval(start: start, end: end).dates() {
                    try await prices.pull(zone: network.zone, at: date)
                    try await emission.co2.pull(zone: network.zone, at: date)
                }
                success = true
            } catch {
                success = false
            }

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
}
