import Foundation
import Combine

protocol DataLoadingDelegate: AnyObject {
    func display(progress: String)
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
        let dispatch = DispatchGroup()

        dispatch.enter()
        Task {
            try? await Task.sleep(seconds: 1.0)
            dispatch.leave()
        }

        dispatch.enter()
        statusSink = energyPriceRepository.status.receive(on: DispatchQueue.main).sink { [delegate] in
            switch $0 {
            case let .updating(progress):
                delegate?.display(progress: String(format: "%.0f%%", progress * 100))
            case .updated:
                dispatch.leave()
            case .failed:
                delegate?.displayFailed()
            default: break
            }
        }
        refreshTask = energyPriceRepository.refresh()

        dispatch.notify(queue: .main) { [weak self] in
            self?.statusSink = nil
            self?.refreshTask?.cancel()
            self?.stateRepository.setupCompleted()
            self?.navigation.navigate(to: .dashboard)
        }
    }

    func retry() {
        refreshTask = energyPriceRepository.refresh()
    }
}
