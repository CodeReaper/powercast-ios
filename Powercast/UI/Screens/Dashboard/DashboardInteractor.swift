import Foundation

enum DashboardMessage {
    case hidden
    case spinner(message: String)
    case warning(message: String)
}

protocol DashboardDelegate: AnyObject {
    func show(loading: Bool)
    func show(priceData: PriceTableDatasource, emissionData: EmissionTableDataSource, updateOffset: Bool)
    func show(message: DashboardMessage)
}

class DashboardInteractor {
    let timeBetweenRefreshes: TimeInterval = 120
    let timeBetweenOffsetUpdates: TimeInterval = 900

    private let notifications: NotificationScheduler
    private let prices: EnergyPriceRepository
    private let emission: EmissionRepository
    private let state: StateRepository

    private var latestCutoffDate = Date.distantPast
    private var latestRefresh = Date.distantPast
    private var latestOffsetUpdate = Date.distantPast

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
            let now = Date()
            let priceSource = try? prices.source(for: state.network)
            let emissionSource = try? emission.co2.source(for: state.network.zone)
            let isOutdated = priceSource?.outdated(comparedTo: now) ?? true
            let isUpdatable = priceSource?.updatable(comparedTo: now) ?? true

            DispatchQueue.main.async { [show, delegate] in
                defer { delegate?.show(loading: false) }
                guard let priceSource = priceSource else {
                    delegate?.show(priceData: EmptyPriceTableDatasource(), emissionData: EmptyEmissionTableDataSource(), updateOffset: false)
                    return
                }
                show(delegate, priceSource, emissionSource ?? EmptyEmissionTableDataSource())
            }

            let isFirstAppearance = latestRefresh == Date.distantPast
            if isUpdatable && now.addingTimeInterval(timeBetweenRefreshes) > latestRefresh {
                latestRefresh = now
                await refreshAsync(delay: isFirstAppearance ? 1.3 : 0.0)
            } else if isOutdated {
                delegate?.show(message: .warning(message: Translations.DASHBOARD_OUTDATED_DATA_MESSAGE))
            }
            if isFirstAppearance {
                latestRefresh = now
            }
        }
    }

    func viewWillDisappear() { }

    func refreshData() {
        Task {
            await refreshAsync(delay: 1.3)
        }
    }

    private func refreshAsync(delay: TimeInterval) async {
        DispatchQueue.main.async { [delegate] in
            delegate?.show(message: .spinner(message: Translations.DASHBOARD_REFRESHING_MESSAGE))
        }

        let now = Date()

        var isUpdated = true
        do {
            let interval = prices.dates(for: state.network.zone).combine(with: emission.co2.dates(for: state.network.zone))
            for date in interval.dates() {
                try await prices.pull(zone: state.network.zone, at: date)
                try await emission.co2.pull(zone: state.network.zone, at: date)
            }
        } catch {
            isUpdated = false
        }

        let updatedPriceSource = try? prices.source(for: state.network)
        let updatedEmissionSource = try? emission.co2.source(for: state.network.zone)
        let isOutdated = updatedPriceSource?.outdated(comparedTo: now) ?? true

        let minimum = max(0, now.timeIntervalSince1970 + delay - Date().timeIntervalSince1970)
        DispatchQueue.main.asyncAfter(deadline: .now() + minimum) { [show, delegate, isUpdated] in
            guard let priceSource = updatedPriceSource else {
                delegate?.show(priceData: EmptyPriceTableDatasource(), emissionData: EmptyEmissionTableDataSource(), updateOffset: false)
                if isUpdated {
                    delegate?.show(message: .warning(message: Translations.DASHBOARD_NO_DATA_MESSAGE))
                } else {
                    delegate?.show(message: .warning(message: Translations.DASHBOARD_REFRESH_FAILED_MESSAGE))
                }
                return
            }
            show(delegate, priceSource, updatedEmissionSource ?? EmptyEmissionTableDataSource())
            if isOutdated {
                delegate?.show(message: .warning(message: Translations.DASHBOARD_OUTDATED_DATA_MESSAGE))
            } else if isUpdated {
                delegate?.show(message: .hidden)
            } else {
                delegate?.show(message: .warning(message: Translations.DASHBOARD_REFRESH_FAILED_MESSAGE))
            }
        }
    }

    private func show(delegate: DashboardDelegate?, priceData: PriceTableDatasource, emissionData: EmissionTableDataSource?) {
        let now = Date()
        let cutoffDate = priceData.cutoffDate
        let updateOffset = cutoffDate.matchesHourIn(date: latestCutoffDate) == false || latestOffsetUpdate.matchesHourIn(date: now) == false
        if updateOffset {
            latestOffsetUpdate = now
        }
        latestCutoffDate = cutoffDate
        delegate?.show(priceData: priceData, emissionData: emissionData ?? EmptyEmissionTableDataSource(), updateOffset: updateOffset)
    }
}

private extension PriceTableDatasource {
    var cutoffDate: Date {
        item(at: IndexPath(row: 0, section: 0))?.duration.upperBound ?? Date.distantPast
    }

    func outdated(comparedTo date: Date) -> Bool {
        guard let item = item(at: IndexPath(row: 0, section: 0)) else {
            return true
        }

        return date > item.duration.upperBound
    }

    func updatable(comparedTo date: Date) -> Bool {
        guard
            let item = item(at: IndexPath(row: 0, section: 0)),
            let minimum = Calendar.current.date(byAdding: .hour, value: -11, to: item.duration.upperBound)
        else {
            return true
        }

        return date >= minimum
    }
}

private extension Date {
    func matchesHourIn(date: Date) -> Bool {
        Calendar.current.date(self, matchesComponents: Calendar.current.dateComponents([.year, .month, .day, .hour], from: date))
    }
}
