import UIKit

class DashboardViewController: ViewController {
    private var interactor: DashboardInteractor!

    init(navigation: AppNavigation, repository: EnergyPriceRepository) {
        super.init(navigation: navigation)
        interactor = DashboardInteractor(delegate: self, repository: repository)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.DASHBOARD_TITLE

        let item = UINavigationItem(title: Translations.DASHBOARD_TITLE)
        item.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.trailing"), style: .plain, target: self, action: #selector(didTapMenu))

        let bar = UINavigationBar()
        bar.isTranslucent = false
        bar.barTintColor = view.backgroundColor
        bar.shadowImage = UIImage()
        bar.delegate = self
        bar.items = [item]
        bar.layout(in: view) { make, its in
            make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            make(its.leadingAnchor.constraint(equalTo: view.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        }

        Stack.views(
            aligned: .center,
            on: .vertical,
            FlexibleSpace(),
            Label(text: Translations.DASHBOARD_TITLE),
            FlexibleSpace()
        )
        .apply(flexible: .fillEqual)
        .layout(in: view) { make, its in
            make(its.topAnchor.constraint(equalTo: bar.bottomAnchor))
            make(its.leadingAnchor.constraint(equalTo: view.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: view.trailingAnchor))
            make(its.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    @objc private func didTapMenu() {
        navigation.navigate(to: .menu)
    }
}

extension DashboardViewController: DashboardDelegate {
}

extension DashboardViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
