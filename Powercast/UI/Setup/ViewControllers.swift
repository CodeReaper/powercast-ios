import UIKit

class ViewController: UIViewController {
    let navigation: AppNavigation

    init(navigation: AppNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
