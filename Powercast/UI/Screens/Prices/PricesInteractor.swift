import Foundation
import Combine

protocol PricesDelegate: AnyObject {
    func show(loading: Bool)
    func show(data: PriceTableDatasource)
    func showNoData()
    func showRefreshFailed()
    func endRefreshing()
}

class PricesInteractor {
    let timeBetweenRefreshes: TimeInterval = 900

    private let prices: EnergyPriceRepository
    private let state: StateRepository

    private var nextRefresh = 0.0

    private weak var delegate: PricesDelegate?

    init(delegate: PricesDelegate, energyPriceRepository: EnergyPriceRepository, stateRepository: StateRepository) {
        self.delegate = delegate
        self.prices = energyPriceRepository
        self.state = stateRepository
    }

    func viewDidLoad() {
        delegate?.show(loading: true)
    }

    func viewWillAppear() {
        Task {
            let source = try? prices.source(for: state.network)

            DispatchQueue.main.async { [delegate] in
                defer { delegate?.show(loading: false) }
                guard let source = source else {
                    delegate?.showNoData()
                    return
                }
                delegate?.show(data: source)
            }

            let now = Date().timeIntervalSince1970
            if now > nextRefresh {
                nextRefresh = now + timeBetweenRefreshes
                await refreshAsync()
            }
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
        do {
            for date in prices.dates(for: state.network.zone) {
                try await prices.pull(zone: state.network.zone, at: date)
            }
        } catch {
            delegate?.showRefreshFailed()
        }

        let updatedSource = try? prices.source(for: state.network)

        DispatchQueue.main.async { [delegate] in
            guard let source = updatedSource else {
                delegate?.showNoData()
                return
            }
            delegate?.show(data: source)
        }
    }
}
