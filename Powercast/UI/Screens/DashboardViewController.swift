import UIKit

class DashboardViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.DASHBOARD_TITLE

        Stack.views(
            aligned: .center,
            on: .vertical,
            FlexibleSpace(),
            Label(text: Translations.DASHBOARD_TITLE),
            FlexibleSpace(),
            Button(text: Translations.SETTINGS_TITLE, target: self, action: #selector(didTapSettings)),
            Button(text: Translations.ABOUT_TITLE, target: self, action: #selector(didTapAbout)),
            Button(text: Translations.LICENSES_TITLE, target: self, action: #selector(didTapLicense)),
            FlexibleSpace()
        )
        .apply(flexible: .fillEqual)
        .setup(in: view)
    }

    @objc private func didTapSettings() {
        navigation.navigate(to: .settings)
    }

    @objc private func didTapLicense() {
        navigation.navigate(to: .licenses)
    }

    @objc private func didTapAbout() {
        navigation.navigate(to: .about)
    }
}
