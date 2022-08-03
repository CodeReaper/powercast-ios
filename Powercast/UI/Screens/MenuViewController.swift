import UIKit

class MenuViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Stack.views(
            aligned: .center,
            on: .vertical,
            spacing: 15,
            FlexibleSpace(),
            ImageView(image: Images.powercast_splash, mode: .center).set(height: 175),
            FlexibleSpace(),
            MenuButton(symbolName: "square.3.stack.3d.middle.filled", text: Translations.DASHBOARD_TITLE, target: self, action: #selector(didTapDashboard)).set(height: 44),
            MenuButton(symbolName: "gearshape", text: Translations.SETTINGS_TITLE, target: self, action: #selector(didTapSettings)).set(height: 44),
            MenuButton(symbolName: "person", text: Translations.ABOUT_TITLE, target: self, action: #selector(didTapAbout)).set(height: 44),
            MenuButton(symbolName: "paragraphsign", text: Translations.LICENSES_TITLE, target: self, action: #selector(didTapLicense)).set(height: 44),
            FlexibleSpace(),
            FlexibleSpace()
        )
        .apply(flexible: .fillEqual)
        .fill()
        .setup(in: view)
    }

    @objc private func didTapDashboard() {
        navigation.navigate(to: .dashboard)
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
