import Foundation
import Combine

protocol PricesDelegate: AnyObject {
    func show(loading: Bool)
    func show(data: PriceTableDatasource)
    func showNoData()
}

class PricesInteractor {
    private let energyPriceRepository: EnergyPriceRepository
    private let stateRepository: StateRepository

    private var syncedData = Date.distantPast
    private var sink = Set<AnyCancellable>()

    private weak var delegate: PricesDelegate?

    init(delegate: PricesDelegate, energyPriceRepository: EnergyPriceRepository, stateRepository: StateRepository) {
        self.delegate = delegate
        self.energyPriceRepository = energyPriceRepository
        self.stateRepository = stateRepository
    }

    func viewDidLoad() {
        delegate?.show(loading: true)
    }

    func viewWillAppear() {
        Publishers
            .CombineLatest(energyPriceRepository.publishedStatus, stateRepository.publishedState)
            .prepend((energyPriceRepository.status, stateRepository.state))
            .receive(on: DispatchQueue.main)
            .sink { [energyPriceRepository, delegate, weak self] (status, state) in
                defer { delegate?.show(loading: false) }
                switch status {
                case .synced(let date):
                    guard let syncedData = self?.syncedData, date > syncedData else { return }
                    self?.syncedData = date
                    fallthrough
                case .updated, .cancelled, .failed:
                    guard let source = try? energyPriceRepository.source(for: state.selectedZone) else {
                        delegate?.showNoData()
                        return
                    }
                    delegate?.show(data: source)
                case .pending, .syncing: break
                }
            }.store(in: &sink)
    }

    func viewWillDisappear() {
        sink.removeAll()
    }
}
