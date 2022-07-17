import UIKit
import GRDB

protocol Dependenables: AnyObject {
    var completedSetup: Bool { get }

    var energyPriceRepository: EnergyPriceRepository { get }

    var powercastDataService: PowercastDataService { get }
}

class App: Dependenables {
    private lazy var navigation = AppNavigation(using: self)

    lazy var energyPriceRepository = EnergyPriceRepository(service: powercastDataService, database: energyPriceDatabase)

    let powercastDataService = PowercastDataService()

    let completedSetup = false

    let energyPriceDatabase = setupEnergyPriceDatabase()

    func didLaunch(with window: UIWindow) {
        navigation.setup(using: window)
    }

    private class func setupEnergyPriceDatabase() -> DatabaseQueue {
        var energyPriceConfiguration = Configuration()
        energyPriceConfiguration.label = "EnergyPrice"
        #if DEBUG
        energyPriceConfiguration.prepareDatabase { db in
            db.trace { print($0) }
        }
        #endif

        // swiftlint:disable force_try
        let database = try! DatabaseQueue(
            path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("energyPrice.db").path,
            configuration: energyPriceConfiguration
        )
        try! setup(energyPriceDatabase: database)
        // swiftlint:enableforce_try

        return database
    }
}
