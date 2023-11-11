import UIKit
import GRDB
import Flogger

protocol Dependenables: AnyObject {
    var configuration: AppConfiguration { get }

    var databases: [Migratable] { get }

    var energyChargesDatabase: ChargesDatabase { get }
    var energyPriceDatabase: EnergyPriceDatabase { get }

    var chargesRepository: ChargesRepository { get }
    var energyPriceRepository: EnergyPriceRepository { get }
    var stateRepository: StateRepository { get }

    var scheduler: BackgroundScheduler { get }
}

class App: Dependenables {
    private lazy var navigation = AppNavigation(using: self as Dependenables)

    let configuration: AppConfiguration
    let energyChargesDatabase: ChargesDatabase
    let energyPriceDatabase: EnergyPriceDatabase
    let stateRepository = StateRepository()
    let databases: [Migratable]

    lazy var chargesRepository = ChargesRepository(database: energyChargesDatabase.queue, service: ChargesServiceAPI())
    lazy var energyPriceRepository = EnergyPriceRepository(database: energyPriceDatabase.queue, service: EnergyPriceServiceAPI(), lookup: chargesRepository)
    var notificationRepository: NotificationRepository {
        NotificationRepository(
            charges: chargesRepository,
            prices: energyPriceRepository,
            state: stateRepository
        )
    }
    var scheduler: BackgroundScheduler {
        BackgroundScheduler(
            charges: chargesRepository,
            prices: energyPriceRepository,
            state: stateRepository,
            notifications: notificationRepository
        )
    }

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.energyPriceDatabase = Self.setupEnergyPriceDatabase(configuration)
        self.energyChargesDatabase = Self.setupEnergyChargesDatabase(configuration)
        self.databases = [energyPriceDatabase, energyChargesDatabase]
    }

    func didLaunch(with window: UIWindow) {
        if configuration.isRunningOnSimulator || configuration.isRunningUnitTests {
            Flogger(level: .debug, [ConsoleLogger()])
        } else {
            Flogger(level: .debug, [ConsoleLogger(), HumioLogger(tags: ["session": UUID().uuidString])])
        }

        if configuration.isRunningUnitTests { return }

        Flog.info("App: Cold start")

        setupAppearence()
        scheduler.register()
        scheduler.schedule()
        notificationRepository.register()
        navigation.setup(using: window)

        // TODO: move somewhere more appropriate like dashboard
        if stateRepository.network.id != 0 {
            notificationRepository.request()
        }

        Task {
            await notificationRepository.schedule()
        }
    }

    func willEnterForeground() { }

    func didEnterBackground() {
        scheduler.schedule()
    }

    // MARK: - setups

    private class func setupEnergyChargesDatabase(_ configuration: AppConfiguration) -> ChargesDatabase {
        var config = Configuration()
        config.label = "EnergyCharges"

        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("energyCharges.db")
        let database = setupDatabase(at: url, using: config, and: configuration)

        return ChargesDatabase(queue: database, configuration: configuration)
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
