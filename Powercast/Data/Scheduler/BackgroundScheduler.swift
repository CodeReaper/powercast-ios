import Foundation
import BackgroundTasks
import Flogger

class BackgroundScheduler {
    private static let formatter = DateFormatter.with(format: "yyyy-MM-dd HH:mm.ss Z")
    private static let identifier = "Powercast.energyprice.refresh"

    private let zone: Zone
    private let prices: EnergyPriceRepository
    private let notifications: NotificationRepository

    init(zone: Zone, prices: EnergyPriceRepository, notifications: NotificationRepository) {
        self.zone = zone
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
            try BGTaskScheduler.shared.submit(request)
            Flog.info("Scheduling: Request scheduled at \(Self.formatter.string(from: date))")
        } catch {
            Flog.error("Scheduling: Request scheduling failed, \(error).")
        }
    }

    private func beginDate() -> Date {
        let fallbackDate = Date().date(bySetting: .minute, value: 0).date(bySetting: .second, value: 0)
        let calculatedDate = try? prices.latest(for: zone)?.date(byAdding: .hour, value: -8).date(byAdding: .minute, value: 15).date(bySetting: .second, value: 0)
        return max(calculatedDate ?? fallbackDate, fallbackDate)
    }

    private func handle(task: BGTask) {
        schedule()

        Flog.info("Scheduling: Task started")

        task.expirationHandler = {
            Flog.info("Scheduling: Task expired")
            task.setTaskCompleted(success: false)
        }

        Task {
            do {
                try await prices.refresh(in: zone)
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

private extension Date {
    func date(byAdding component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self)!
    }

    func date(bySetting component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(bySetting: component, value: value, of: self)!
    }
}
