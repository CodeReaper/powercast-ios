import Foundation

protocol DashboardDelegate: AnyObject {
}

class DashboardInteractor {
    private let repository: EnergyPriceRepository

    private weak var delegate: DashboardDelegate?

    init(delegate: DashboardDelegate, repository: EnergyPriceRepository) {
        self.delegate = delegate
        self.repository = repository
    }
}
