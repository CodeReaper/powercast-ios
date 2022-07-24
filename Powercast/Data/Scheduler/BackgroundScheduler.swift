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
        let request = BGProcessingTaskRequest(identifier: energyPriceRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // TODO: determine a good schedule
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
            case .failed, .cancelled, .unknown:
                task.setTaskCompleted(success: false)
            case .updating: break
            }
        }

        refreshTask = repository.refresh()
    }
}
