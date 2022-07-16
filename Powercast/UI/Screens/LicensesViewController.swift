import UIKit

class LicensesViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.LICENSES_TITLE

        view.backgroundColor = .white

        Stack.views(aligned: .center, on: .vertical, Label(text: Translations.LICENSES_TITLE)).setup(in: view)
    }
}
