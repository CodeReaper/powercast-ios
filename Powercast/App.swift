import UIKit
import GRDB

protocol Dependenables: AnyObject {
    var energyPriceDatabase: EnergyPriceDatabase { get }

    var energyPriceRepository: EnergyPriceRepository { get }

    var stateRepository: StateRepository { get }

    var powercastDataService: PowercastDataService { get }

    var scheduler: BackgroundScheduler { get }
}

class App: Dependenables {
    private let configuration: AppConfiguration

    private lazy var navigation = AppNavigation(using: self as Dependenables, on: UIScreen.main.traitCollection.userInterfaceIdiom)

    let powercastDataService: PowercastDataService
    let energyPriceDatabase: EnergyPriceDatabase
    let stateRepository = StateRepository()

    lazy var energyPriceRepository = EnergyPriceRepository(service: powercastDataService, database: energyPriceDatabase.queue)
    lazy var scheduler = BackgroundScheduler(repository: energyPriceRepository)

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.powercastDataService = Self.setupPowercastDataService(configuration)
        self.energyPriceDatabase = Self.setupEnergyPriceDatabase(configuration)
    }

    func didLaunch(with window: UIWindow) {
        setupAppearence()
        scheduler.register()
        navigation.setup(using: window)
    }

    func willEnterForeground() {
        energyPriceRepository.refresh()
    }

    // MARK: - setups

    private class func setupEnergyPriceDatabase(_ configuration: AppConfiguration) -> EnergyPriceDatabase {
        var energyPriceConfiguration = Configuration()
        energyPriceConfiguration.label = "EnergyPrice"

        if configuration.traceDatabaseStatments {
            energyPriceConfiguration.prepareDatabase { db in
                db.trace { print($0) }
            }
        }

        let database: DatabaseQueue
        if configuration.inMemoryDatabase {
            database = DatabaseQueue(configuration: energyPriceConfiguration)
        } else {
            // swiftlint:disable force_try
            database = try! DatabaseQueue(
                path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("energyPrice.db").path,
                configuration: energyPriceConfiguration
            )
            // swiftlint:enable force_try
        }

        return EnergyPriceDatabase(queue: database, configuration: configuration)
    }

    private class func setupPowercastDataService(_ configuration: AppConfiguration) -> PowercastDataService {
        if configuration.usesDemoData {
            return PowercastDataServiceDemoValues()
        } else {
            return PowercastDataServiceAPI()
        }
    }
}
