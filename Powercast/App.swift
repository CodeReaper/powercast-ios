import UIKit

protocol Dependenables: AnyObject {
    var completedSetup: Bool { get }
}

class App: Dependenables {
    private lazy var navigation = AppNavigation(using: self)

    var completedSetup: Bool { false }

    func didLaunch(with window: UIWindow) {
        navigation.setup(using: window)
    }
}
