import Foundation
import Combine

protocol DashboardDelegate: AnyObject {
    func show(loading: Bool)
    func show(priceData: PriceTableDatasource, emissionData: EmissionTableDataSource)
    func showNoData()
    func showRefreshFailed()
    func endRefreshing()
}

class DashboardInteractor {
    let timeBetweenRefreshes: TimeInterval = 900

    private let notifications: NotificationScheduler
    private let prices: EnergyPriceRepository
    private let emission: EmissionRepository
    private let state: StateRepository

    private var nextRefresh = 0.0

    private weak var delegate: DashboardDelegate?

    init(delegate: DashboardDelegate, prices: EnergyPriceRepository, emission: EmissionRepository, notifications: NotificationScheduler, state: StateRepository) {
        self.delegate = delegate
        self.notifications = notifications
        self.prices = prices
        self.emission = emission
        self.state = state
    }

    func viewDidLoad() {
        delegate?.show(loading: true)
    }

    func viewWillAppear() {
        Task {
            let priceSource = try? prices.source(for: state.network)
            let emissionSource = try? emission.co2.source(for: state.network.zone)

            DispatchQueue.main.async { [delegate] in
                defer { delegate?.show(loading: false) }
                guard let priceSource = priceSource else {
                    delegate?.showNoData()
                    return
                }
                delegate?.show(priceData: priceSource, emissionData: emissionSource ?? EmptyEmissionTableDataSource())
            }

            let now = Date().timeIntervalSince1970
            if now > nextRefresh {
                nextRefresh = now + timeBetweenRefreshes
                await refreshAsync()
            }
        }
        state.add(observer: self)
        updated()
    }

    func viewWillDisappear() {
        state.remove(observer: self)
    }

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
            let interval = prices.dates(for: state.network.zone).combine(with: emission.co2.dates(for: state.network.zone))
            for date in interval.dates() {
                try await prices.pull(zone: state.network.zone, at: date)
                try await emission.co2.pull(zone: state.network.zone, at: date)
            }
        } catch {
            DispatchQueue.main.async { [delegate] in
                delegate?.showRefreshFailed()
            }
        }

        let updatedPriceSource = try? prices.source(for: state.network)
        let updatedEmissionSource = try? emission.co2.source(for: state.network.zone)

        DispatchQueue.main.async { [delegate] in
            guard let priceSource = updatedPriceSource else {
                delegate?.showNoData()
                return
            }
            delegate?.show(priceData: priceSource, emissionData: updatedEmissionSource ?? EmptyEmissionTableDataSource())
        }
    }
}

extension DashboardInteractor: Observer {
    func updated() {
        DispatchQueue.main.async {
            switch self.state.notificationStatus {
            case .notDetermined:
                self.notifications.request()
            default: break
            }
        }
    }
}
