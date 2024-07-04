import UIKit
import SugarKit

indirect enum Navigation {
    case launch
    case onBoarding
    case networkSelection
    case loadData(network: Network)
    case dashboard
    case archives
    case dataDetails(price: Price, emission: Emission.Co2?)
    case priceArchive
    case delays
    case settings
    case notification(notification: Notification?)
    case networkDetails(network: Network)
    case gridDetails(zone: Zone)
    case licenses
    case show(title: String, content: String)
    case faq
    case actionSheet(options: [ActionSheetOption])
    case menu
    case systemSettings
    case reset
}

class AppNavigation {
    private let navigationController = UINavigationController()

    private let dependencies: Dependenables

    private lazy var drawer = Drawer(
        covering: 0.65,
        drawer: MenuViewController(
            navigation: self,
            state: dependencies.stateRepository
        ),
        main: DashboardViewController(
            navigation: self,
            prices: dependencies.energyPriceRepository,
            emission: dependencies.emissionRepository,
            notifications: dependencies.notificationScheduler,
            state: dependencies.stateRepository
        )
    )

    private var network: Network? {
        dependencies.chargesRepository.network(by: dependencies.stateRepository.network.id)
    }
    private var networks: [Network]? {
        try? dependencies.chargesRepository.networks()
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

    func navigate(to endpoint: Navigation) { // swiftlint:disable:this function_body_length
        switch endpoint {
        case .launch:
            let viewController = LaunchViewController(
                navigation: self,
                databases: dependencies.databases,
                charges: dependencies.chargesRepository,
                state: dependencies.stateRepository,
                service: dependencies.configurationService
            )
            navigationController.setViewControllers([viewController], animated: true)
        case .onBoarding:
            let viewController = OnBoardingViewController(navigation: self)
            navigationController.setViewControllers([viewController], animated: true)
        case .networkSelection:
            let viewController = NetworkSelectionViewController(
                navigation: self,
                networks: networks ?? [],
                charges: dependencies.chargesRepository
            )
            navigationController.pushViewController(viewController, animated: true)
        case let .loadData(network):
            let viewController = DataLoadingViewController(
                navigation: self,
                prices: dependencies.energyPriceRepository,
                charges: dependencies.chargesRepository,
                emission: dependencies.emissionRepository,
                state: dependencies.stateRepository,
                network: network
            )
            navigationController.setViewControllers([viewController], animated: true)
        case .menu:
            drawer.set(drawer.state == .opened ? .closed : .opened, animated: true)
        case .dashboard:
            drawer.set(.closed, animated: true) {
                self.navigationController.setViewControllers([self.drawer], animated: true)
            }
        case let .dataDetails(price, emission):
            navigationController.pushViewController(DataDetailsViewController(navigation: self, price: price, emission: emission), animated: true)
        case .priceArchive:
            let viewController = PriceArchiveViewController(
                navigation: self,
                state: dependencies.stateRepository,
                prices: dependencies.energyPriceRepository,
                emission: dependencies.emissionRepository,
                lookup: dependencies.chargesRepository
            )
            navigationController.pushViewController(viewController, animated: true)
        case .settings:
            navigationController.pushViewController(SettingsViewController(navigation: self, state: dependencies.stateRepository, notifications: dependencies.notificationScheduler), animated: true)
        case let .notification(notification):
            navigationController.pushViewController(NotificationViewController(navigation: self, state: dependencies.stateRepository, notification: notification), animated: true)
        case let .networkDetails(network):
            let viewController = NetworkDetailsViewController(
                navigation: self,
                network: network,
                charges: dependencies.chargesRepository
            )
            navigationController.pushViewController(viewController, animated: true)
        case let .gridDetails(zone):
            let viewController = GridDetailsViewController(
                navigation: self,
                zone: zone,
                charges: dependencies.chargesRepository
            )
            navigationController.pushViewController(viewController, animated: true)
        case .licenses:
            navigationController.pushViewController(LicensesViewController(navigation: self), animated: true)
        case let .show(title, content):
            navigationController.pushViewController(TitleAndTextViewController(navigation: self, title: title, content: content), animated: true)
        case .faq:
            navigationController.pushViewController(FAQViewController(navigation: self), animated: true)
        case .actionSheet(let options):
            (navigationController.topViewController ?? navigationController).present(UIAlertController.build(with: options), animated: true)
        case .systemSettings:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        case .reset:
            let viewController = NetworkSelectionViewController(
                navigation: self,
                networks: networks ?? [],
                charges: dependencies.chargesRepository
            )
            navigationController.setViewControllers([OnBoardingViewController(navigation: self), viewController], animated: true)
        case .archives:
            navigationController.pushViewController(ArchivesViewController(navigation: self, state: dependencies.stateRepository), animated: true)
        case .delays:
            navigationController.pushViewController(DelaysViewController(navigation: self, service: dependencies.incidentsService, zone: dependencies.stateRepository.network.zone), animated: true)
        }
    }
}
