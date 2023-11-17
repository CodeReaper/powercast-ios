import UIKit
import SugarKit

class MenuViewController: ViewController {
    private let state: StateRepository

    init(navigation: AppNavigation, state: StateRepository) {
        self.state = state
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
            MenuButton(symbolName: "poweroutlet.type.k.fill", text: Translations.NETWORK_DETAILS_TITLE, target: self, action: #selector(didTapNetworkDetails)).set(height: 44),
            MenuButton(symbolName: "gearshape", text: Translations.SETTINGS_TITLE, target: self, action: #selector(didTapSettings)).set(height: 44),
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
        navigate(to: .dashboard)
    }

    @objc private func didTapNetworkDetails() {
        navigate(to: .networkDetails(network: state.network))
    }

    @objc private func didTapSettings() {
        navigate(to: .settings)
    }

    @objc private func didTapLicense() {
        navigate(to: .licenses)
    }
}
