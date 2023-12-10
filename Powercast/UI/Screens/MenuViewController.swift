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
            ImageView(image: UIImage.powercastSplash, mode: .center),
            MenuButton(symbolName: "square.3.stack.3d.middle.filled", text: Translations.DASHBOARD_TITLE, textColor: .buttonText, target: self, action: #selector(didTapDashboard)).set(height: 44),
            MenuButton(symbolName: "poweroutlet.type.k.fill", text: Translations.NETWORK_DETAILS_TITLE, textColor: .buttonText, target: self, action: #selector(didTapNetworkDetails)).set(height: 44),
            MenuButton(symbolName: "bolt.fill", text: Translations.GRID_DETAILS_TITLE, textColor: .buttonText, target: self, action: #selector(didTapGridDetails)).set(height: 44),
            MenuButton(symbolName: "archivebox.fill", text: Translations.PRICE_ARCHIVE_TITLE, textColor: .buttonText, target: self, action: #selector(didTapPriceArchive)).set(height: 44),
            MenuButton(symbolName: "gearshape", text: Translations.SETTINGS_TITLE, textColor: .buttonText, target: self, action: #selector(didTapSettings)).set(height: 44),
            MenuButton(symbolName: "paragraphsign", text: Translations.LICENSES_TITLE, textColor: .buttonText, target: self, action: #selector(didTapLicense)).set(height: 44),
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

        let container = Stack.views(
            inset: NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
            Label(style: .body, text: Translations.VERSION_LABEL(Bundle.shortVersion, Bundle.version, Bundle.commit), color: .secondaryLabel).aligned(to: .center)
        ).layout(in: view) { make, its in
            make(its.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
            make(its.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor))
        }

        UIView().set(backgroundColor: .viewBackground).setup(matching: container, in: view)

        view.bringSubviewToFront(container)
    }

    @objc private func didTapDashboard() {
        navigate(to: .dashboard)
    }

    @objc private func didTapNetworkDetails() {
        navigate(to: .networkDetails(network: state.network))
    }

    @objc private func didTapGridDetails() {
        navigate(to: .gridDetails(zone: state.network.zone))
    }

    @objc private func didTapPriceArchive() {
        navigate(to: .priceArchive)
    }

    @objc private func didTapSettings() {
        navigate(to: .settings)
    }

    @objc private func didTapLicense() {
        navigate(to: .licenses)
    }
}
