import UIKit
import SugarKit

indirect enum Navigation {
    case intro
    case regionSelection(configuration: ZoneSelectionViewController.Configuration)
    case loadData
    case dashboard
    case settings
    case specificSettings(configuration: [SettingsViewController.Section])
    case licenses
    case license(title: String, content: String)
    case actionSheet(options: [ActionSheetOption])
    case menu
}

class AppNavigation {
    private let dependencies: Dependenables
    private let device: UIUserInterfaceIdiom

    private lazy var drawer = Drawer(
        covering: device == .phone ? 0.65 : 0.25,
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

    private var navigationController = UINavigationController()

    private var hasCompletedIntroduction: Bool { drawer.parent != nil }

    private var window: UIWindow?

    init(using dependencies: Dependenables, on device: UIUserInterfaceIdiom) {
        self.dependencies = dependencies
        self.device = device
    }

    func setup(using window: UIWindow) {
        self.window = window

        navigate(to: .intro)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func navigate(to endpoint: Navigation) {
        guard let window = window else {
            return
        }

        switch endpoint {
        case .intro:
            navigationController.setViewControllers([IntroViewController(navigation: self, state: dependencies.stateRepository.state, databases: dependencies.databases)], animated: false)
        case let .regionSelection(configuration):
            navigationController.pushViewController(ZoneSelectionViewController(navigation: self, configuration: configuration, repository: dependencies.stateRepository), animated: true)
        case .loadData:
            navigationController.pushViewController(DataLoadingViewController(navigation: self, energyPriceRepository: dependencies.energyPriceRepository, chargesRepository: dependencies.chargesRepository, stateRepository: dependencies.stateRepository), animated: true)
        case .menu:
            drawer.set(drawer.state == .opened ? .closed : .opened, animated: true)
        case .dashboard:
            if hasCompletedIntroduction {
                drawer.set(.closed, animated: true) {
                    self.navigationController.setViewControllers([self.drawer], animated: true)
                }
            } else {
                navigationController = UINavigationController(rootViewController: drawer)
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    let oldState = UIView.areAnimationsEnabled
                    UIView.setAnimationsEnabled(false)
                    window.rootViewController = self.navigationController
                    UIView.setAnimationsEnabled(oldState)
                }, completion: nil)
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
