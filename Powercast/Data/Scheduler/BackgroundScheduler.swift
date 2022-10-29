import Foundation
import Combine
import BackgroundTasks
import os.log

class BackgroundScheduler {
    private static let formatter = DateFormatter.with(format: "yyyy-MM-dd HH:mm.ss")

    private let zone: Zone
    private let repository: EnergyPriceRepository
    private let notification: NotificationRepository

    private var statusSink: AnyCancellable?
    private var refreshTask: Task<Void, Never>?

    init(zone: Zone, repository: EnergyPriceRepository, notification: NotificationRepository) {
        self.zone = zone
        self.repository = repository
        self.notification = notification
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundIdentifiers.energyPrice, using: .main, launchHandler: handle(task:))
    }

    func schedule() {
        let date = beginDate()
        let request = BGProcessingTaskRequest(identifier: BackgroundIdentifiers.energyPrice)
        request.earliestBeginDate = date
        request.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduling: Request scheduled at \(Self.formatter.string(from: date))")
        } catch {
            os_log("Could not schedule app refresh, error: %{private}@", type: .error, "\(error)")
            print("Scheduling: Request scheduling failed, \(error).")
        }
    }

    private func beginDate() -> Date {
        let minutesToFull = (60 - Calendar.current.component(.minute, from: Date()))
        let fallbackDate = Date().date(bySetting: .second, value: 0).date(byAdding: .minute, value: minutesToFull)
        let calculatedDate = try? repository.latest(for: zone)?.date(byAdding: .hour, value: -8).date(byAdding: .minute, value: 15).date(bySetting: .second, value: 0)
        return max(calculatedDate ?? fallbackDate, fallbackDate)
    }

    private func handle(task: BGTask) { // TODO: remove debugging
        schedule()

        print("Scheduling: Task started")

        task.expirationHandler = { [refreshTask, notification, weak self] in
            print("Scheduling: Task expired")
            notification.show(
                message: NotificationRepository.Message(
                    title: "Background",
                    body: "Expired"
                )
            )
            task.setTaskCompleted(success: false)
            refreshTask?.cancel()
            self?.statusSink = nil
        }

        statusSink = repository.publishedStatus.receive(on: DispatchQueue.main).sink { [notification, weak self] in
            switch $0 {
            case .updated(let newData):
                print("Scheduling: Task finished succesfully - newData: \(newData)")
                notification.show(
                    message: NotificationRepository.Message(
                        title: "Background",
                        body: "Updated, newData: \(newData)"
                    )
                )
                task.setTaskCompleted(success: newData)
                self?.statusSink = nil
            case .failed(let error):
                print("Scheduling: Task failed")
                notification.show(
                    message: NotificationRepository.Message(
                        title: "Background",
                        body: "Failed: \(error.localizedDescription)"
                    )
                )
                task.setTaskCompleted(success: false)
                self?.statusSink = nil
            case .syncing, .synced, .cancelled, .pending: break
            }
        }

        refreshTask = repository.refresh(mode: .background)
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
