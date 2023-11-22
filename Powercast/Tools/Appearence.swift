import UIKit

extension App {
    func setupAppearence() {
        for metric in [UIBarMetrics.default, .compact, .compactPrompt, .defaultPrompt] {
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: metric)
        }
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.navigationBarText]
        UINavigationBar.appearance().backgroundColor = .navigationBarBackground

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.navigationBarText], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.navigationBarText], for: .highlighted)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .navigationBarText
    }
}
