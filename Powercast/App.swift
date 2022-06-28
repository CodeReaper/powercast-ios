import Foundation
import UIKit

class App {
    func didLaunch(with window: UIWindow) {
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
    }
}
