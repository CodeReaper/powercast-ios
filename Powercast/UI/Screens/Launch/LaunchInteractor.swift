import Foundation
import SugarKit

protocol LaunchDelegate: AnyObject {
    func showNetworkSelection()
}

struct LaunchInteractor {
    private let databases: [Migratable]
    private let store: StoreRepository
    private let charges: ChargesRepository

    private weak var delegate: LaunchDelegate?

    init(delegate: LaunchDelegate, databases: [Migratable], store: StoreRepository, charges: ChargesRepository) {
        self.delegate = delegate
        self.databases = databases
        self.store = store
        self.charges = charges
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
        dispatch.enter()
        Task {
            try? await store.load()
            dispatch.leave()
        }
        // swiftlint:enable force_try

        dispatch.enter()
        Task {
            try? await charges.pullNetworks()
            dispatch.leave()
        }

        dispatch.notify(queue: .main) {
            delegate?.showNetworkSelection()
        }
    }
}
