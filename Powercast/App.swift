import UIKit
import GRDB
import Flogger

protocol Dependenables: AnyObject {
    var configuration: AppConfiguration { get }

    var databases: [Migratable] { get }

    var chargesDatabase: ChargesDatabase { get }
    var emissionDatabase: EmissionDatabase { get }
    var energyPriceDatabase: EnergyPriceDatabase { get }

    var chargesRepository: ChargesRepository { get }
    var emissionRepository: EmissionRepository { get }
    var energyPriceRepository: EnergyPriceRepository { get }
    var stateRepository: StateRepository { get }
    var storeRepository: StoreRepository { get }

    var notificationScheduler: NotificationScheduler { get }
    var backgroundScheduler: BackgroundScheduler { get }
}

class App: Dependenables {
    private lazy var navigation = AppNavigation(using: self as Dependenables)

    let configuration: AppConfiguration
    let chargesDatabase: ChargesDatabase
    let emissionDatabase: EmissionDatabase
    let energyPriceDatabase: EnergyPriceDatabase
    let stateRepository = StateRepository()
    let databases: [Migratable]

    lazy var storeRepository = StoreRepository()
    lazy var chargesRepository = ChargesRepository(database: chargesDatabase.queue, service: ChargesServiceAPI())
    lazy var emissionRepository = EmissionRepository(database: emissionDatabase, service: EmissionServiceAPI())
    lazy var energyPriceRepository = EnergyPriceRepository(database: energyPriceDatabase.queue, service: EnergyPriceServiceAPI(), lookup: chargesRepository)
    lazy var notificationScheduler = NotificationScheduler(
        charges: chargesRepository,
        prices: energyPriceRepository,
        state: stateRepository
    )

    var backgroundScheduler: BackgroundScheduler {
        BackgroundScheduler(
            charges: chargesRepository,
            prices: energyPriceRepository,
            emission: emissionRepository,
            state: stateRepository,
            notifications: notificationScheduler
        )
    }

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.energyPriceDatabase = Self.setupEnergyPriceDatabase(configuration)
        self.emissionDatabase = Self.setupEmissionDatabase(configuration)
        self.chargesDatabase = Self.setupChargesDatabase(configuration)
        self.databases = [energyPriceDatabase, emissionDatabase, chargesDatabase]
    }

    func didLaunch(with window: UIWindow) {
        let tags = ["session": UUID().uuidString, "release": "\(configuration.isReleaseBuild)", "commit": Bundle.commit]
        if configuration.isRunningOnSimulator || configuration.isRunningUnitTests {
            Flogger(level: .debug, [ConsoleLogger()])
        } else if configuration.isReleaseBuild {
            Flogger(level: .warn, [HumioLogger(tags: tags)])
        } else {
            Flogger(level: .debug, [ConsoleLogger(), HumioLogger(tags: tags)])
        }

        if configuration.isRunningUnitTests { return }

        Flog.info("App: Cold start")

        setupAppearence()
        backgroundScheduler.register()
        backgroundScheduler.schedule()
        notificationScheduler.register()
        navigation.setup(using: window)
    }

    func willEnterForeground() { }

    func didEnterBackground() {
        backgroundScheduler.schedule()
    }

    // MARK: - setups

    private class func setupChargesDatabase(_ configuration: AppConfiguration) -> ChargesDatabase {
        var config = Configuration()
        config.label = "EnergyCharges"

        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("energyCharges.db")
        let database = setupDatabase(at: url, using: config, and: configuration)

        return ChargesDatabase(queue: database, configuration: configuration)
    }

    private class func setupEmissionDatabase(_ configuration: AppConfiguration) -> EmissionDatabase {
        var config = Configuration()
        config.label = "Emission"

        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("emission.db")
        let database = setupDatabase(at: url, using: config, and: configuration)

        return EmissionDatabase(queue: database, configuration: configuration)
    }

    private class func setupEnergyPriceDatabase(_ configuration: AppConfiguration) -> EnergyPriceDatabase {
        var config = Configuration()
        config.label = "EnergyPrice"

        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("energyPrice.db")
        let database = setupDatabase(at: url, using: config, and: configuration)

        return EnergyPriceDatabase(queue: database, configuration: configuration)
    }

    private class func setupDatabase(at url: URL, using config: Configuration, and configuration: AppConfiguration) -> DatabaseQueue {
        var config = config
        if configuration.traceDatabaseStatments {
            NSLog("enabled tracing for: \(url.path)")
            config.prepareDatabase { db in
                db.trace { print($0) }
            }
        }

        // swiftlint:disable force_try
        if !FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path) {
            try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: false)
        }
        let database = try! DatabaseQueue(
            path: url.path,
            configuration: config
        )
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try! url.setResourceValues(values)
        // swiftlint:enable force_try
        return database
    }
}
