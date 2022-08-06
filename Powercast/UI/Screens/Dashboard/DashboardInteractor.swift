import Foundation
import Combine

protocol DashboardDelegate: AnyObject {
    func show(loading: Bool)
    func show(items: [EnergyPrice])
}

class DashboardInteractor {
    private let calendar = Calendar.current

    private let repository: EnergyPriceRepository

    private var isRefreshed = false
    private var hasLoadedRefreshedData = false
    private var retryDelay: TimeInterval = 1

    private var statusSink: AnyCancellable?
    private var loadingTask: Task<Void, Error>?
    private var dateLimit: Date?

    private weak var delegate: DashboardDelegate?

    init(delegate: DashboardDelegate, repository: EnergyPriceRepository) {
        self.delegate = delegate
        self.repository = repository
    }

    func viewDidLoad() {
        delegate?.show(loading: true)
        startLoadData()
    }

    func viewWillAppear() {
        statusSink = repository.status.receive(on: DispatchQueue.main).sink { [weak self, startLoadData, repository] in
            switch $0 {
            case let .synced(with: date):
                let load = self?.dateLimit == nil
                self?.dateLimit = date
                if load {
                    _ = startLoadData()
                }
                self?.retryDelay = 1
            case .updated, .cancelled:
                self?.dateLimit = Date.distantPast
                self?.retryDelay = 1
                self?.hasLoadedRefreshedData = startLoadData()
            case .failed:
                DispatchQueue.main.asyncAfter(deadline: .now() + (self?.retryDelay ?? 1), execute: {
                    self?.retryDelay += min(30, 1)
                    _ = repository.refresh()
                })
            case .pending, .syncing: break
            }
        }

        if !isRefreshed {
            isRefreshed = true
            _ = repository.refresh()
        }
    }

    func viewWillDisappear() {
        statusSink = nil
    }

    func showing(time: TimeInterval, in dateInterval: DateInterval) {
        if abs(dateInterval.start.timeIntervalSince1970 - time) < .thirtySixHours {
            let request = DateInterval(start: calendar.date(byAdding: .day, value: -2, to: dateInterval.start)!, end: dateInterval.start)
            if let dateLimit = dateLimit {
                if dateLimit >= request.end {
                    self.dateLimit = nil
                } else if dateLimit > request.start {
                    loadData(in: DateInterval(start: dateLimit, end: request.end))
                } else {
                    loadData(in: request)
                }
            } else {
                loadData(in: request)
            }
        } else if !hasLoadedRefreshedData && abs(dateInterval.end.timeIntervalSince1970 - time) < .thirtySixHours {
            hasLoadedRefreshedData = startLoadData()
        }
    }

    @discardableResult
    private func startLoadData() -> Bool {
        let now = Date()
        let interval = DateInterval(start: calendar.date(byAdding: .hour, value: -6, to: now)!, end: Calendar.current.date(byAdding: .hour, value: 36, to: now)!)
        return loadData(in: interval)
    }

    @discardableResult
    private func loadData(in interval: DateInterval) -> Bool {
        guard loadingTask == nil else { return false }

        loadingTask = Task {
            let items = try await repository.data(in: interval)

            loadingTask = nil

            guard items.count > 0 else { return }

            DispatchQueue.main.async { [delegate] in
                delegate?.show(items: items)
                delegate?.show(loading: false)
            }
        }
        return true
    }
}
