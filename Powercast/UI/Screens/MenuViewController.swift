import UIKit

class MenuViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = UIScrollView().setup(in: view)
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        Stack.views(
            aligned: .center,
            on: .vertical,
            spacing: 15,
            FlexibleSpace(),
            ImageView(image: Images.powercast_splash, mode: .center),
            MenuButton(symbolName: "square.3.stack.3d.middle.filled", text: Translations.DASHBOARD_TITLE, target: self, action: #selector(didTapDashboard)).set(height: 44),
            MenuButton(symbolName: "gearshape", text: Translations.SETTINGS_TITLE, target: self, action: #selector(didTapSettings)).set(height: 44),
            MenuButton(symbolName: "person", text: Translations.ABOUT_TITLE, target: self, action: #selector(didTapAbout)).set(height: 44),
            MenuButton(symbolName: "paragraphsign", text: Translations.LICENSES_TITLE, target: self, action: #selector(didTapLicense)).set(height: 44),
            FlexibleSpace()
        )
        .apply(flexible: .fillEqual)
        .fill()
        .layout(in: scrollView) { make, its in
            make(its.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor))
            make(its.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor))
            make(its.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor))
            make(its.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor))
            make(its.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor))
        }
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
