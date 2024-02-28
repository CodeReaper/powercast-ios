import Foundation
import BackgroundTasks
import Flogger

class BackgroundScheduler {
    private static let formatter = DateFormatter.with(format: "yyyy-MM-dd HH:mm.ss Z")
    private static let identifier = "Powercast.energyprice.refresh"

    private let navigation: AppNavigation
    private let prices: EnergyPriceRepository
    private let emission: EmissionRepository
    private let charges: ChargesRepository
    private let state: StateRepository
    private let notifications: NotificationScheduler

    init(navigation: AppNavigation, charges: ChargesRepository, prices: EnergyPriceRepository, emission: EmissionRepository, state: StateRepository, notifications: NotificationScheduler) {
        self.navigation = navigation
        self.prices = prices
        self.emission = emission
        self.charges = charges
        self.state = state
        self.notifications = notifications
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.identifier, using: .main, launchHandler: handle(task:))
    }

    func schedule() {
        let date = beginDate()
        let request = BGAppRefreshTaskRequest(identifier: Self.identifier)
        request.earliestBeginDate = date
        do {
            BGTaskScheduler.shared.cancelAllTaskRequests()
            try BGTaskScheduler.shared.submit(request)
            Flog.info("Scheduling: Request scheduled at \(Self.formatter.string(from: date))")
        } catch {
            Flog.error("Scheduling: Request scheduling failed, \(error).")
        }
    }

    private func beginDate() -> Date {
        return Date.now.date(byAdding: .hour, value: 1).date(bySetting: .minute, value: 15).date(bySetting: .second, value: 0)
    }

    private func handle(task: BGTask) {
        schedule()

        Flog.info("Scheduling: Task started")

        task.expirationHandler = {
            Flog.info("Scheduling: Task expired")
            task.setTaskCompleted(success: false)
        }

        guard let network = charges.network(by: state.network.id) else {
            task.setTaskCompleted(success: true)
            return
        }

        Task {
            do {
                try await charges.pullNetworks()
                if try charges.networks().map({ $0.id }).contains(network.id) == false {
                    Flog.warn("Scheduling: network \(network.id) was discontinued - resetting state")
                    try await notifications.discontinue(network: network.name)
                    state.forgetNetwork()
                    DispatchQueue.main.async { [navigation] in
                        navigation.navigate(to: .reset)
                    }
                    task.setTaskCompleted(success: true)
                    return
                }

                try await charges.pullNetwork(id: network.id)
                try await charges.pullGrid()
                let interval = prices.dates(for: network.zone).combine(with: emission.co2.dates(for: network.zone))
                for date in interval.dates() {
                    try await prices.pull(zone: network.zone, at: date)
                    try await emission.co2.pull(zone: network.zone, at: date)
                }

                Flog.info("Scheduling: Task finished")
                await notifications.schedule()
                task.setTaskCompleted(success: true)
            } catch {
                Flog.warn("Scheduling: Unable to complete refresh: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
}
