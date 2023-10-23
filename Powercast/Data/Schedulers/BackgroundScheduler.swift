import Foundation
import BackgroundTasks
import Flogger

class BackgroundScheduler {
    private static let formatter = DateFormatter.with(format: "yyyy-MM-dd HH:mm.ss Z")
    private static let identifier = "Powercast.energyprice.refresh"

    private let prices: EnergyPriceRepository
    private let notifications: NotificationRepository

    init(prices: EnergyPriceRepository, notifications: NotificationRepository) {
        self.prices = prices
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

        // FIXME: refresh charges too
        Task {
            do {
                try await prices.refresh()
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
