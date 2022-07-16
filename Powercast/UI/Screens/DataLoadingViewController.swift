import UIKit

class DataLoadingViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.DATA_LOADING_TITLE

        view.backgroundColor = .white

        Stack.views(aligned: .center, on: .vertical, Label(text: Translations.DATA_LOADING_TITLE)).setup(in: view)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    @objc private func didTap() {
        navigation.navigate(to: .dashboard)
    }
}
