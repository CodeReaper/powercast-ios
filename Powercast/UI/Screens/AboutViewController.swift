import UIKit

class AboutViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.ABOUT_TITLE

        Stack.views(aligned: .center, on: .vertical, Label(text: Translations.ABOUT_TITLE)).setup(in: view)
    }
}
