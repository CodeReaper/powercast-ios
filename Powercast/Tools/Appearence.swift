import UIKit

extension App {
    func setupAppearence() {
        for metric in [UIBarMetrics.default, .compact, .compactPrompt, .defaultPrompt] {
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: metric)
        }
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().backgroundColor = Color.primary

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.white], for: .highlighted)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .white
    }
}
