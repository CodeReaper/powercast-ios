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
    private var hasFetchedRefreshedData = false

    private var statusSink: AnyCancellable?
    private var fetchTask: Task<Void, Error>?

    private weak var delegate: DashboardDelegate?

    init(delegate: DashboardDelegate, repository: EnergyPriceRepository) {
        self.delegate = delegate
        self.repository = repository
    }

    func viewDidLoad() {
        delegate?.show(loading: true)
        fetchData()
    }

    func viewWillAppear() {
        statusSink = repository.status.receive(on: DispatchQueue.main).sink { [weak self] in
            switch $0 {
            case .updated:
                self?.hasFetchedRefreshedData = self?.fetchData() ?? false
            default: break
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
            fetchData(in: DateInterval(start: calendar.date(byAdding: .day, value: -2, to: dateInterval.start)!, end: dateInterval.start))
        } else if !hasFetchedRefreshedData && abs(dateInterval.end.timeIntervalSince1970 - time) < .thirtySixHours {
            hasFetchedRefreshedData = fetchData()
        }
    }

    @discardableResult
    private func fetchData() -> Bool {
        let now = Date()
        let interval = DateInterval(start: calendar.date(byAdding: .hour, value: -6, to: now)!, end: Calendar.current.date(byAdding: .hour, value: 36, to: now)!)
        return fetchData(in: interval)
    }

    @discardableResult
    private func fetchData(in interval: DateInterval) -> Bool {
        guard fetchTask == nil else { return false }

        fetchTask = Task {
            let items = try await repository.data(in: interval)

            fetchTask = nil
            DispatchQueue.main.async { [delegate] in
                delegate?.show(items: items)
                delegate?.show(loading: false)
            }
        }
        return true
    }
}
