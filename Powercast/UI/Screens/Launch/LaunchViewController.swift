import UIKit
import SugarKit

class LaunchViewController: ViewController {
    private var interactor: LaunchInteractor!

    init(navigation: AppNavigation, databases: [Migratable], charges: ChargesRepository) {
        super.init(navigation: navigation)
        self.interactor = LaunchInteractor(delegate: self, databases: databases, charges: charges)
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

        view.backgroundColor = .brand

        ImageView(image: UIImage.powercastSplash, mode: .center).setup(centeredIn: view, usingSafeLayout: false)

        SpinnerView(color: .white).startAnimating().layout(in: view) { (make, its) in
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
}
