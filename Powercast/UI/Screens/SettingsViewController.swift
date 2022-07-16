import UIKit

class SettingsViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.SETTINGS_TITLE

        view.backgroundColor = .white

        Stack.views(aligned: .center, on: .vertical, Label(text: Translations.SETTINGS_TITLE)).setup(in: view)
    }
}
