import UIKit
import GRDB
import Flogger

protocol Dependenables: AnyObject {
    var configuration: AppConfiguration { get }

    var databases: [Migratable] { get }

    var energyPriceDatabase: EnergyPriceDatabase { get }

    var energyPriceRepository: EnergyPriceRepository { get }
    var stateRepository: StateRepository { get }

    var scheduler: BackgroundScheduler { get }
}

class App: Dependenables {
    private lazy var navigation = AppNavigation(using: self as Dependenables, on: UIScreen.main.traitCollection.userInterfaceIdiom)

    let configuration: AppConfiguration
    let energyPriceDatabase: EnergyPriceDatabase
    let stateRepository = StateRepository()
    let databases: [Migratable]

    lazy var energyPriceRepository = EnergyPriceRepository(database: energyPriceDatabase.queue, service: PowercastDataServiceAPI(), charges: ChargesServiceHardcoded())
    var notificationRepository: NotificationRepository {
        NotificationRepository(
            charges: ChargesServiceHardcoded(),
            prices: energyPriceRepository,
            state: stateRepository
        )
    }
    var scheduler: BackgroundScheduler {
        BackgroundScheduler(
            zone: stateRepository.state.selectedZone,
            prices: energyPriceRepository,
            notifications: notificationRepository
        )
    }

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.energyPriceDatabase = Self.setupEnergyPriceDatabase(configuration)
        self.databases = [energyPriceDatabase]
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

        if stateRepository.state.setupCompleted {
            energyPriceRepository.pull(zone: stateRepository.state.selectedZone)
            notificationRepository.request() // TODO: move to an intro step

            Task {
                await notificationRepository.schedule()
            }
        }
    }

    func willEnterForeground() { }

    func didEnterBackground() {
        scheduler.schedule()
    }

    // MARK: - setups

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
