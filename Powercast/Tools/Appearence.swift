import UIKit

extension App {
    func setupAppearence() {
        for metric in [UIBarMetrics.default, .compact, .compactPrompt, .defaultPrompt] {
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: metric)
        }
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.navigationBarTitle]
        UINavigationBar.appearance().backgroundColor = .navigationBarBackground

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.navigationBarTitle], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.navigationBarTitle], for: .highlighted)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .navigationBarTitle
    }
}
