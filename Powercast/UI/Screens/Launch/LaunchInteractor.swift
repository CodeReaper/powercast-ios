import Foundation
import SugarKit

protocol LaunchDelegate: AnyObject {
    func showOnBoarding()
    func showDashboard()
    func showUpgradeRequired()
}

struct LaunchInteractor {
    private let databases: [Migratable]
    private let store: StoreRepository
    private let charges: ChargesRepository
    private let state: LaunchState
    private let service: ConfigurationService

    private weak var delegate: LaunchDelegate?

    init(delegate: LaunchDelegate, databases: [Migratable], store: StoreRepository, charges: ChargesRepository, state: LaunchState, service: ConfigurationService) {
        self.delegate = delegate
        self.databases = databases
        self.store = store
        self.charges = charges
        self.state = state
        self.service = service
    }

    func viewWillAppear() {
        let dispatch = DispatchGroup()

        dispatch.enter()
        Task {
            try? await Task.sleep(seconds: 0.5)
            dispatch.leave()
        }

        // swiftlint:disable force_try
        for database in databases {
            dispatch.enter()
            Task {
                try! database.migrate()
                dispatch.leave()
            }
        }
        // swiftlint:enable force_try

        dispatch.enter()
        Task {
            try? await store.load()
            dispatch.leave()
        }

        dispatch.enter()
        Task {
            try? await charges.pullNetworks()
            dispatch.leave()
        }

        dispatch.enter()
        Task {
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
