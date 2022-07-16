import UIKit

class RegionSelectionViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.REGION_SELECTION_TITLE

        view.backgroundColor = .white

        Stack.views(aligned: .center, on: .vertical, Label(text: Translations.REGION_SELECTION_TITLE)).setup(in: view)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    @objc private func didTap() {
        navigation.navigate(to: .loadData)
    }
}
