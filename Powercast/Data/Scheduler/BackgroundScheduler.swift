import Foundation
import BackgroundTasks

class BackgroundScheduler {
    private static let formatter = DateFormatter.with(format: "yyyy-MM-dd HH:mm.ss Z")

    private let zone: Zone
    private let repository: EnergyPriceRepository

    init(zone: Zone, repository: EnergyPriceRepository) {
        self.zone = zone
        self.repository = repository
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundIdentifiers.energyPrice, using: .main, launchHandler: handle(task:))
    }

    func schedule() {
        let date = beginDate()
        let request = BGAppRefreshTaskRequest(identifier: BackgroundIdentifiers.energyPrice)
        request.earliestBeginDate = date
        do {
            try BGTaskScheduler.shared.submit(request)
            Humio.info("Scheduling: Request scheduled at \(Self.formatter.string(from: date))")
        } catch {
            Humio.error("Scheduling: Request scheduling failed, \(error).")
        }
    }

    private func beginDate() -> Date {
        let fallbackDate = Date().date(bySetting: .minute, value: 0).date(bySetting: .second, value: 0)
        let calculatedDate = try? repository.latest(for: zone)?.date(byAdding: .hour, value: -8).date(byAdding: .minute, value: 15).date(bySetting: .second, value: 0)
        return max(calculatedDate ?? fallbackDate, fallbackDate)
    }

    private func handle(task: BGTask) {
        schedule()

        Humio.info("Scheduling: Task started")

        task.expirationHandler = {
            Humio.info("Scheduling: Task expired")
            task.setTaskCompleted(success: false)
        }

        Task {
            do {
                try await repository.refresh(in: zone)
                Humio.info("Scheduling: Task finished")
                task.setTaskCompleted(success: true)
            } catch {
                Humio.warn("Scheduling: Unable to complete refresh: \(error)")
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
