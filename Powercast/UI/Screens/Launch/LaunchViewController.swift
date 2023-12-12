import UIKit
import SugarKit

class LaunchViewController: ViewController {
    private let spinner = SpinnerView(color: .spinner)
    private let requiredUpdate = Label(style: .body, text: Translations.UPGRADE_IS_REQUIRED, color: .labelText)

    private var interactor: LaunchInteractor!

    init(navigation: AppNavigation, databases: [Migratable], store: StoreRepository, charges: ChargesRepository, state: ConfigurationState, service: ConfigurationService) {
        super.init(navigation: navigation)
        self.interactor = LaunchInteractor(delegate: self, databases: databases, store: store, charges: charges, state: state, service: service)
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

        view.backgroundColor = .viewBackground

        let imageView = ImageView(image: UIImage.powercastSplash, mode: .center).setup(centeredIn: view, usingSafeLayout: false)

        requiredUpdate.set(hidden: true).aligned(to: .center).layout(in: view) { make, its in
            make(its.topAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.bottomAnchor, constant: 12))
            make(its.centerXAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.centerXAnchor))
            make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20))
            make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20))
            make(its.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor))
        }

        spinner.startAnimating().layout(in: view) { (make, its) in
            make(its.heightAnchor.constraint(greaterThanOrEqualToConstant: 60))
            make(its.centerXAnchor.constraint(equalTo: self.view.centerXAnchor))
            make(its.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 40))
        }
    }
}

extension LaunchViewController: LaunchDelegate {
    func showNetworkSelection() {
        navigate(to: .networkSelection(forceSelection: false))
    }

    func showUpgradeRequired() {
        spinner.stopAnimating().set(hidden: true)
        requiredUpdate.set(hidden: false)
    }
}
