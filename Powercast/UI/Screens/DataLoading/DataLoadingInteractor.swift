import Foundation
import Combine

protocol DataLoadingDelegate: AnyObject {
    func displayFailed()
}

class DataLoadingInteractor {
    private let navigation: AppNavigation
    private let energyPriceRepository: EnergyPriceRepository
    private let chargesRepository: ChargesRepository
    private let stateRepository: StateRepository
    private let network: Network

    private var statusSink: AnyCancellable?
    private var refreshTask: Task<Void, Never>?

    private weak var delegate: DataLoadingDelegate?

    init(navigation: AppNavigation, delegate: DataLoadingDelegate, energyPriceRepository: EnergyPriceRepository, chargesRepository: ChargesRepository, stateRepository: StateRepository, network: Network) {
        self.navigation = navigation
        self.delegate = delegate
        self.energyPriceRepository = energyPriceRepository
        self.chargesRepository = chargesRepository
        self.stateRepository = stateRepository
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
                try await chargesRepository.pullNetworks()
                try await chargesRepository.pullGrid()
                try await chargesRepository.pullNetwork(id: network.id)

                let today = Calendar.current.startOfDay(for: Date())
                let start = Calendar.current.date(byAdding: .day, value: -14, to: today)!
                let end = Calendar.current.date(byAdding: .day, value: 2, to: today)!
                for date in start.dates(until: end) {
                    try await energyPriceRepository.pull(zone: network.zone, at: date)
                }
                success = true
            } catch {
                success = false
            }

            DispatchQueue.main.asyncAfter(deadline: success ? minimumTime : DispatchTime.now()) { [self] in
                if success {
                    stateRepository.select(network: network)
                    navigation.navigate(to: .dashboard)
                } else {
                    delegate?.displayFailed()
                }
            }
        }
    }
}
