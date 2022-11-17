import UIKit
import HumioLogger

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        app.willEnterForeground()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        app.didEnterBackground()
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String) async {
        Humio.debug("AppDelegate stuff with \(identifier)")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
