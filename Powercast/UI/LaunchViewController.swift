import UIKit
import SugarKit

class LaunchViewController: ViewController {
    private let overlayBackground = UIView()
    private let titleView = ImageView(image: Images.powercast_splash, mode: .center)
    private let spinnerView = SpinnerView(color: .white)

    private var interactor: LaunchInteractor!

    init(navigation: AppNavigation, databases: [Migratable], repository: ChargesRepository, networkId: Int?) {
        super.init(navigation: navigation)
        self.interactor = LaunchInteractor(delegate: self, databases: databases, repository: repository, networkId: networkId)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        interactor.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.INTRO_TITLE

        ImageView(image: Images.offshore_wind_power, mode: .scaleAspectFill).setup(in: view, usingSafeLayout: false)

        overlayBackground.isUserInteractionEnabled = true
        overlayBackground.backgroundColor = Color.primary
        overlayBackground.setup(in: view, usingSafeLayout: false)

        titleView.setup(centeredIn: overlayBackground, usingSafeLayout: false)

        spinnerView.startAnimating().layout(in: overlayBackground) { (make, its) in
            make(its.heightAnchor.constraint(greaterThanOrEqualToConstant: 60))
            make(its.centerXAnchor.constraint(equalTo: self.view.centerXAnchor))
            make(its.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 40))
        }
    }
}

extension LaunchViewController: LaunchDelegate {
    func showNetworkSelection() {
        titleView.layout(in: view) { (make, its) in
            make(its.leftAnchor.constraint(equalTo: self.view.leftAnchor))
            make(its.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 15))
            make(its.rightAnchor.constraint(equalTo: self.view.rightAnchor))
        }

        UIView.animate(withDuration: 0.9) {
            self.titleView.layoutIfNeeded()
            self.overlayBackground.alpha = 0
        } completion: { _ in
            self.overlayBackground.removeFromSuperview()
            self.navigation.navigate(to: .regionSelection(configuration: ZoneSelectionViewController.Configuration(behavior: .navigate(endpoint: .loadData))))
        }
    }
}
