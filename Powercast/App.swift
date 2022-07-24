import UIKit
import GRDB

protocol Dependenables: AnyObject {
    var completedSetup: Bool { get }

    var energyPriceRepository: EnergyPriceRepository { get }

    var powercastDataService: PowercastDataService { get }

    var scheduler: BackgroundScheduler { get }
}

class App: Dependenables {
    private let configuration: AppConfiguration

    private lazy var navigation = AppNavigation(using: self as Dependenables)

    let completedSetup = false

    let powercastDataService: PowercastDataService
    let energyPriceDatabase: DatabaseQueue

    lazy var energyPriceRepository = EnergyPriceRepository(service: powercastDataService, database: energyPriceDatabase)
    lazy var scheduler = BackgroundScheduler(repository: energyPriceRepository)

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.powercastDataService = Self.setupPowercastDataService(configuration)
        self.energyPriceDatabase = Self.setupEnergyPriceDatabase(configuration)
    }

    func didLaunch(with window: UIWindow) {
        scheduler.register()
        navigation.setup(using: window)
    }

    // MARK: - setups

    private class func setupEnergyPriceDatabase(_ configuration: AppConfiguration) -> DatabaseQueue {
        var energyPriceConfiguration = Configuration()
        energyPriceConfiguration.label = "EnergyPrice"

        if configuration.traceDatabaseStatments {
            energyPriceConfiguration.prepareDatabase { db in
                db.trace { print($0) }
            }
        }

        // swiftlint:disable force_try
        let database = try! DatabaseQueue(
            path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("energyPrice.db").path,
            configuration: energyPriceConfiguration
        )
        try! setup(energyPriceDatabase: database, using: configuration)
        // swiftlint:enableforce_try

        return database
    }

    private class func setupPowercastDataService(_ configuration: AppConfiguration) -> PowercastDataService {
        if configuration.usesDemoData {
            return PowercastDataServiceDemoValues()
        } else {
            return PowercastDataServiceAPI()
        }
    }
}
