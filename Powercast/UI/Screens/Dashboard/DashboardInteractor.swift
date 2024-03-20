import Foundation

enum DashboardMessage {
    case hidden
    case spinner(message: String)
    case warning(message: String)
}

protocol DashboardDelegate: AnyObject {
    func show(loading: Bool)
    func show(priceData: PriceTableDatasource, emissionData: EmissionTableDataSource, forceOffsetUpdate: Bool)
    func show(message: DashboardMessage)
}

class DashboardInteractor {
    let timeBetweenRefreshes: TimeInterval = 120
    let timeBetweenOffsetUpdates: TimeInterval = 900

    private let notifications: NotificationScheduler
    private let prices: EnergyPriceRepository
    private let emission: EmissionRepository
    private let state: StateRepository

    private var nextRefresh = Date.distantFuture.timeIntervalSince1970
    private var nextOffsetUpdate: Double

    private weak var delegate: DashboardDelegate?

    init(delegate: DashboardDelegate, prices: EnergyPriceRepository, emission: EmissionRepository, notifications: NotificationScheduler, state: StateRepository) {
        self.delegate = delegate
        self.notifications = notifications
        self.prices = prices
        self.emission = emission
        self.state = state
        self.nextOffsetUpdate = Date.now.timeIntervalSince1970 + timeBetweenOffsetUpdates
    }

    func viewDidLoad() {
        delegate?.show(loading: true)
    }

    func viewWillAppear() {
        Task {
            let now = Date()
            let priceSource = try? prices.source(for: state.network)
            let emissionSource = try? emission.co2.source(for: state.network.zone)
            let isOutdated = priceSource?.isOutdated(comparedTo: now) ?? true
            let needsRefresh = priceSource?.needsRefresh(comparedTo: now) ?? true

            DispatchQueue.main.async { [delegate] in
                defer { delegate?.show(loading: false) }
                guard let priceSource = priceSource else {
                    delegate?.show(priceData: EmptyPriceTableDatasource(), emissionData: EmptyEmissionTableDataSource(), forceOffsetUpdate: false)
                    return
                }
                delegate?.show(priceData: priceSource, emissionData: emissionSource ?? EmptyEmissionTableDataSource(), forceOffsetUpdate: false)
            }

            if needsRefresh && now.timeIntervalSince1970 <= nextRefresh {
                nextRefresh = now.timeIntervalSince1970 + timeBetweenRefreshes
                await refreshAsync()
            } else if isOutdated {
                delegate?.show(message: .warning(message: Translations.DASHBOARD_OUTDATED_DATA_MESSAGE))
            }
        }
    }

    func viewWillDisappear() { }

    func refreshData() {
        Task {
            await refreshAsync()
        }
    }

    private func refreshAsync() async {
        DispatchQueue.main.async { [delegate] in
            delegate?.show(message: .spinner(message: Translations.DASHBOARD_REFRESHING_MESSAGE))
        }

        let now = Date()

        var updated = true
        do {
            let interval = prices.dates(for: state.network.zone).combine(with: emission.co2.dates(for: state.network.zone))
            for date in interval.dates() {
                try await prices.pull(zone: state.network.zone, at: date)
                try await emission.co2.pull(zone: state.network.zone, at: date)
            }
        } catch {
            updated = false
        }

        let updatedPriceSource = try? prices.source(for: state.network)
        let updatedEmissionSource = try? emission.co2.source(for: state.network.zone)
        let isOutdated = updatedPriceSource?.isOutdated(comparedTo: now) ?? true

        let updateOffset = now.timeIntervalSince1970 > nextOffsetUpdate
        if updateOffset {
            nextOffsetUpdate = now.timeIntervalSince1970 + timeBetweenOffsetUpdates
        }

        let minimum = max(0, now.timeIntervalSince1970 + 1.3 - Date().timeIntervalSince1970)
        DispatchQueue.main.asyncAfter(deadline: .now() + minimum) { [delegate, updated] in
            guard let priceSource = updatedPriceSource else {
                delegate?.show(priceData: EmptyPriceTableDatasource(), emissionData: EmptyEmissionTableDataSource(), forceOffsetUpdate: false)
                if updated {
                    delegate?.show(message: .warning(message: Translations.DASHBOARD_NO_DATA_MESSAGE))
                } else {
                    delegate?.show(message: .warning(message: Translations.DASHBOARD_REFRESH_FAILED_MESSAGE))
                }
                return
            }
            delegate?.show(priceData: priceSource, emissionData: updatedEmissionSource ?? EmptyEmissionTableDataSource(), forceOffsetUpdate: updateOffset)
            if isOutdated {
                delegate?.show(message: .warning(message: Translations.DASHBOARD_OUTDATED_DATA_MESSAGE))
            } else if updated {
                delegate?.show(message: .hidden)
            } else {
                delegate?.show(message: .warning(message: Translations.DASHBOARD_REFRESH_FAILED_MESSAGE))
            }
        }
    }
}

private extension PriceTableDatasource {
    func isOutdated(comparedTo date: Date) -> Bool {
        guard let item = item(at: IndexPath(row: 0, section: 0)) else {
            return true
        }

        return date > item.duration.upperBound
    }

    func needsRefresh(comparedTo date: Date) -> Bool {
        guard
            let item = item(at: IndexPath(row: 0, section: 0)),
            let minimum = Calendar.current.date(byAdding: .hour, value: -11, to: item.duration.upperBound)
        else {
            return true
        }

        return date >= minimum
    }
}
