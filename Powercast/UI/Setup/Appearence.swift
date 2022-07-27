import UIKit

extension App {
    func setupAppearence() {
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.white], for: .highlighted)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .white
    }
}
