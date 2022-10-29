import Foundation

protocol IntroDelegate: AnyObject {
    func showIntroduction()
    func showDashboard()
}

struct IntroInteractor {
    private let databases: [Migratable]
    private let state: State

    private weak var delegate: IntroDelegate?

    init(delegate: IntroDelegate, state: State, databases: [Migratable]) {
        self.delegate = delegate
        self.state = state
        self.databases = databases
    }

    func viewDidLoad() {
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

        dispatch.notify(queue: .main) {
            if state.setupCompleted {
                delegate?.showDashboard()
            } else {
                delegate?.showIntroduction()
            }
        }
    }
}
