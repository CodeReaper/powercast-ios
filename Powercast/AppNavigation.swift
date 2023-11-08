import UIKit
import SugarKit

indirect enum Navigation {
    case launch
    case networkSelection
    case loadData(network: Network)
    case dashboard
    case settings
    case specificSettings(configuration: [SettingsViewController.Section])
    case licenses
    case license(title: String, content: String)
    case actionSheet(options: [ActionSheetOption])
    case menu
}

class AppNavigation {
    private let navigationController = UINavigationController()

    private let dependencies: Dependenables

    private lazy var drawer = Drawer(
        covering: 0.65,
        drawer: MenuViewController(
            navigation: self,
            configuration: dependencies.configuration
        ),
        main: PricesViewController(
            navigation: self,
            energyPriceRepository: dependencies.energyPriceRepository,
            stateRepository: dependencies.stateRepository
        )
    )

    private var network: Network? {
        dependencies.chargesRepository.network(by: dependencies.stateRepository.network.id)
    }
    private var networks: [Network]? {
        try? dependencies.energyChargesDatabase.queue.read {
            try Database.Network.fetchAll($0).compactMap { try? Network.from(model: $0) }
        }
    }

    private var window: UIWindow?

    init(using dependencies: Dependenables) {
        self.dependencies = dependencies
    }

    func setup(using window: UIWindow) {
        self.window = window

        navigate(to: .launch)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func navigate(to endpoint: Navigation) {
        switch endpoint {
        case .launch:
            if network != nil {
                navigate(to: .dashboard)
                return
            }
            let viewController = LaunchViewController(
                navigation: self,
                databases: dependencies.databases,
                repository: dependencies.chargesRepository
            )
            navigationController.setViewControllers([viewController], animated: true)
        case .networkSelection:
            let viewController = NetworkSelectionViewController(
                navigation: self,
                repository: dependencies.chargesRepository,
                networks: networks ?? [],
                networkId: dependencies.stateRepository.network.id
            )
            navigationController.setViewControllers([viewController], animated: true)
        case let .loadData(network):
            let viewController = DataLoadingViewController(
                navigation: self,
                energyPriceRepository: dependencies.energyPriceRepository,
                chargesRepository: dependencies.chargesRepository,
                stateRepository: dependencies.stateRepository,
                network: network
            )
            navigationController.setViewControllers([viewController], animated: true)
        case .menu:
            drawer.set(drawer.state == .opened ? .closed : .opened, animated: true)
        case .dashboard:
            drawer.set(.closed, animated: true) {
                self.navigationController.setViewControllers([self.drawer], animated: true)
            }
        case .settings:
            navigationController.pushViewController(SettingsViewController(navigation: self, repository: dependencies.stateRepository, sections: nil), animated: true)
        case let .specificSettings(configuration):
            navigationController.pushViewController(SettingsViewController(navigation: self, repository: dependencies.stateRepository, sections: configuration), animated: true)
        case .licenses:
            navigationController.pushViewController(LicensesViewController(navigation: self), animated: true)
        case let .license(title, content):
            navigationController.pushViewController(LicenseViewController(navigation: self, title: title, content: content), animated: true)
        case .actionSheet(let options):
            navigationController.present(UIAlertController.build(with: options), animated: true)
        }
    }
}
