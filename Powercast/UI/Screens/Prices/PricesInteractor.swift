import Foundation
import Combine

protocol PricesDelegate: AnyObject {
    func show(loading: Bool)
    func show(data: PriceTableDatasource)
    func showNoData()
    func endRefreshing()
}

class PricesInteractor {
    private let energyPriceRepository: EnergyPriceRepository
    private let stateRepository: StateRepository

    private var refresh = false

    private weak var delegate: PricesDelegate?

    init(delegate: PricesDelegate, energyPriceRepository: EnergyPriceRepository, stateRepository: StateRepository) {
        self.delegate = delegate
        self.energyPriceRepository = energyPriceRepository
        self.stateRepository = stateRepository
    }

    func viewDidLoad() {
        delegate?.show(loading: true)
        refresh = true
    }

    func viewWillAppear() {
        Task {
            let zone = stateRepository.state.selectedZone
            let source = try? energyPriceRepository.source(for: zone)

            DispatchQueue.main.async { [delegate] in
                defer { delegate?.show(loading: false) }
                guard let source = source else {
                    delegate?.showNoData()
                    return
                }
                delegate?.show(data: source)
            }

            guard refresh else { return }
            refresh = false

            await refreshAsync()
        }
    }

    func viewWillDisappear() { }

    func refreshData() {
        Task {
            await refreshAsync()

            DispatchQueue.main.async { [delegate] in
                delegate?.endRefreshing()
            }
        }
    }

    private func refreshAsync() async {
        let zone = stateRepository.state.selectedZone

        try? await energyPriceRepository.refresh(in: stateRepository.state.selectedZone)
        let updatedSource = try? energyPriceRepository.source(for: zone)

        DispatchQueue.main.async { [delegate] in
            guard let source = updatedSource else {
                delegate?.showNoData()
                return
            }
            delegate?.show(data: source)
        }
    }
}
