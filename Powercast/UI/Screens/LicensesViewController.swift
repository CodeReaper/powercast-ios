import UIKit

class LicensesViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.LICENSES_TITLE

        Stack.views(aligned: .center, on: .vertical, Label(text: Translations.LICENSES_TITLE)).setup(in: view)
    }
}
