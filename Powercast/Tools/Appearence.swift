import UIKit

extension App {
    func setupAppearence() {
        let navigationBar = UINavigationBarAppearance()
        navigationBar.configureWithOpaqueBackground()
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.navigationBarText]
        navigationBar.backgroundColor = .navigationBarBackground
        UINavigationBar.appearance().standardAppearance = navigationBar
        for metric in [UIBarMetrics.default, .compact, .compactPrompt, .defaultPrompt] {
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: metric)
        }

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.navigationBarText], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.navigationBarText], for: .highlighted)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .navigationBarText
    }
}
