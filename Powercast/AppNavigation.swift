import UIKit

enum Navigation {
    case intro
    case regionSelection
    case loadData
    case dashboard
    case settings
    case about
    case licenses
    case actionSheet(options: [ActionSheetOption])
}

class AppNavigation {
    private let navigationController = UINavigationController()

    private let dependencies: Dependenables

    private var setDashboardAnimated = false

    init(using dependencies: Dependenables) {
        self.dependencies = dependencies
    }

    func setup(using window: UIWindow) {
        if dependencies.stateRepository.state.setupCompleted {
            navigate(to: .dashboard)
        } else {
            setDashboardAnimated = true
            navigate(to: .intro)
        }

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func navigate(to endpoint: Navigation) {
        switch endpoint {
        case .intro:
            navigationController.setViewControllers([IntroViewController(navigation: self, state: dependencies.stateRepository.state, energyPriceDatabase: dependencies.energyPriceDatabase)], animated: false)
        case .regionSelection:
            navigationController.pushViewController(RegionSelectionViewController(navigation: self, repository: dependencies.stateRepository), animated: true)
        case .loadData:
            navigationController.pushViewController(DataLoadingViewController(navigation: self, repository: dependencies.energyPriceRepository), animated: true)
        case .dashboard:
            dependencies.scheduler.schedule()
            navigationController.setViewControllers([DashboardViewController(navigation: self)], animated: setDashboardAnimated)
        case .settings:
            navigationController.pushViewController(SettingsViewController(navigation: self), animated: true)
        case .licenses:
            navigationController.pushViewController(LicensesViewController(navigation: self), animated: true)
        case .about:
            navigationController.pushViewController(AboutViewController(navigation: self), animated: true)
        case .actionSheet(let options):
            navigationController.present(UIAlertController.build(with: options), animated: true)
        }
    }
}
