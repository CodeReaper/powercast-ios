import Foundation
import Combine

protocol DataLoadingDelegate: AnyObject {
    func displayFailed()
}

class DataLoadingInteractor {
    private let navigation: AppNavigation
    private let energyPriceRepository: EnergyPriceRepository
    private let stateRepository: StateRepository

    private var statusSink: AnyCancellable?
    private var refreshTask: Task<Void, Never>?

    private weak var delegate: DataLoadingDelegate?

    init(navigation: AppNavigation, delegate: DataLoadingDelegate, energyPriceRepository: EnergyPriceRepository, stateRepository: StateRepository) {
        self.navigation = navigation
        self.delegate = delegate
        self.energyPriceRepository = energyPriceRepository
        self.stateRepository = stateRepository
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
            let zone = stateRepository.state.selectedZone
            let success: Bool
            do {
                try await energyPriceRepository.refresh(in: zone)
                success = true
            } catch {
                success = false
            }

            DispatchQueue.main.asyncAfter(deadline: success ? minimumTime : DispatchTime.now()) { [self] in
                if success {
                    stateRepository.setupCompleted()
                    navigation.navigate(to: .dashboard)
                    energyPriceRepository.pull(zone: zone)
                } else {
                    delegate?.displayFailed()
                }
            }
        }
    }
}
