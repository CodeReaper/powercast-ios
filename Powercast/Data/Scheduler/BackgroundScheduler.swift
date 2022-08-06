import Foundation
import Combine
import BackgroundTasks

class BackgroundScheduler {
    private let energyPriceRefresh = "com.codereaper.Powercast.energyprice.refresh"

    private var statusSink: AnyCancellable?
    private var refreshTask: Task<Void, Never>?

    let repository: EnergyPriceRepository

    init(repository: EnergyPriceRepository) {
        self.repository = repository
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: energyPriceRefresh, using: .main, launchHandler: handle(task:))
    }

    func schedule() {
        let minutesToFull = (60 - Calendar.current.component(.minute, from: Date())) + 5
        let request = BGProcessingTaskRequest(identifier: energyPriceRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(minutesToFull * 60))
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        do {
           try BGTaskScheduler.shared.submit(request)
        } catch {
           print("Could not schedule app refresh: \(error)")
        }
    }

    private func handle(task: BGTask) {
        schedule()

        task.expirationHandler = { [weak self] in
            task.setTaskCompleted(success: false)
            self?.refreshTask?.cancel()
        }

        statusSink = repository.status.receive(on: DispatchQueue.main).sink {
            switch $0 {
            case .updated:
                task.setTaskCompleted(success: true)
            case .failed, .cancelled, .pending:
                task.setTaskCompleted(success: false)
            case .syncing, .synced: break
            }
        }

        refreshTask = repository.refresh()
    }
}
