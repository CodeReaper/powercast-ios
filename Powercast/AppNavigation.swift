import UIKit

enum Navigation {
    case intro
    case regionSelection
    case loadData
    case dashboard
    case settings
    case about
    case licenses
}

class AppNavigation {
    private let navigationController = UINavigationController()

    private let dependencies: Dependenables

    private var lastEndpoint = Navigation.intro

    init(using dependencies: Dependenables) {
        self.dependencies = dependencies
    }

    func setup(using window: UIWindow) {
        if dependencies.completedSetup {
            navigate(to: .dashboard)
        } else {
            navigate(to: .intro)
        }

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func navigate(to endpoint: Navigation) {
        defer { lastEndpoint = endpoint }

        switch endpoint {
        case .intro:
            navigationController.setViewControllers([IntroViewController(navigation: self)], animated: false)
        case .regionSelection:
            navigationController.pushViewController(RegionSelectionViewController(navigation: self), animated: true)
        case .loadData:
            navigationController.pushViewController(DataLoadingViewController(navigation: self), animated: true)
        case .dashboard:
            navigationController.setViewControllers([DashboardViewController(navigation: self)], animated: lastEndpoint != .intro)
        case .settings:
            navigationController.pushViewController(SettingsViewController(navigation: self), animated: true)
        case .licenses:
            navigationController.pushViewController(LicensesViewController(navigation: self), animated: true)
        case .about:
            navigationController.pushViewController(AboutViewController(navigation: self), animated: true)
        }
    }
}
