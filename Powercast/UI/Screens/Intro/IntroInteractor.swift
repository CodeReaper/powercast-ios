import Foundation

protocol IntroDelegate: AnyObject {
    func showIntroduction()
    func showDashboard()
}

struct IntroInteractor {
    private let energyPriceDatabase: EnergyPriceDatabase
    private let state: State

    private weak var delegate: IntroDelegate?

    init(delegate: IntroDelegate, state: State, energyPriceDatabase: EnergyPriceDatabase) {
        self.delegate = delegate
        self.state = state
        self.energyPriceDatabase = energyPriceDatabase
    }

    func viewDidLoad() {
        let dispatch = DispatchGroup()

        dispatch.enter()
        Task {
            try? await Task.sleep(seconds: 0.5)
            dispatch.leave()
        }

        // swiftlint:disable force_try
        dispatch.enter()
        Task {
            try! energyPriceDatabase.migrate()
            dispatch.leave()
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