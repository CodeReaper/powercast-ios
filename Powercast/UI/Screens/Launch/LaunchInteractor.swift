import Foundation
import SugarKit

protocol LaunchDelegate: AnyObject {
    func showOnBoarding()
    func showDashboard()
    func showUpgradeRequired()
}

struct LaunchInteractor {
    private let databases: [Migratable]
    private let charges: ChargesRepository
    private let state: LaunchState
    private let service: ConfigurationService

    private weak var delegate: LaunchDelegate?

    init(delegate: LaunchDelegate, databases: [Migratable], charges: ChargesRepository, state: LaunchState, service: ConfigurationService) {
        self.delegate = delegate
        self.databases = databases
        self.charges = charges
        self.state = state
        self.service = service
    }

    func viewWillAppear() {
        let dispatch = DispatchGroup()

        dispatch.enter()
        Task {
            try? await Task.sleep(seconds: 0.5)

            // swiftlint:disable force_try
            for database in databases {
                try! database.migrate()
            }
            // swiftlint:enable force_try

            try? await charges.pullNetworks()

            if let configuration = try? await service.configuration() {
                state.save(configuration: configuration)
            }

            dispatch.leave()
        }

        dispatch.notify(queue: .main) {
            if Int(Bundle.version)! < state.configuration.minimumBuildVersion {
                delegate?.showUpgradeRequired()
            } else if charges.network(by: state.network.id) == nil {
                delegate?.showOnBoarding()
            } else {
                delegate?.showDashboard()
            }
        }
    }
}
