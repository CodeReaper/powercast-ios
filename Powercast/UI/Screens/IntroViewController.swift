import UIKit

class IntroViewController: ViewController {
    private let overlayBackground = UIView()

    private let energyPriceDatabase: EnergyPriceDatabase
    private let state: State

    init(navigation: AppNavigation, state: State, energyPriceDatabase: EnergyPriceDatabase) {
        self.energyPriceDatabase = energyPriceDatabase
        self.state = state
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.INTRO_TITLE

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        ImageView(image: Images.offshore_wind_power, mode: .scaleAspectFill).setup(in: view, usingSafeLayout: false)

        Stack.views(
            aligned: .center,
            on: .vertical,
            Label(
                text: Translations.INTRO_WELCOME_TITLE,
                color: .white
            ),
            Label(
                text: Translations.INTRO_WELCOME_MESSAGE(formatter.string(from: Date())),
                color: .white
            ),
            FlexibleSpace()
        )
        .apply(flexible: .fillEqual)
        .setup(in: view)

        overlayBackground.isUserInteractionEnabled = true
        overlayBackground.backgroundColor = UIColor.from(hex: "#2c90d3")
        overlayBackground.setup(in: view, usingSafeLayout: false)

        let imageView = ImageView(image: Images.powercast_splash, mode: .center).setup(centeredIn: overlayBackground)

        SpinnerView(color: .white).startAnimating().set(size: CGSize(width: 60, height: 60)).setup(under: imageView, in: overlayBackground)

        let dispatch = DispatchGroup()
        // swiftlint:disable force_try
        dispatch.enter()
        Task {
            try! await Task.sleep(seconds: 0.5)
            dispatch.leave()
        }
        dispatch.enter()
        Task {
            try! energyPriceDatabase.migrate()
            dispatch.leave()
        }
        // swiftlint:enable force_try
        dispatch.notify(queue: .main) { [weak self, state] in
            if state.setupCompleted {
                self?.navigation.navigate(to: .dashboard)
            } else {
                UIView.animate(withDuration: 0.9) {
                    self?.overlayBackground.alpha = 0
                } completion: { _ in
                    self?.overlayBackground.removeFromSuperview()
                }
            }
        }

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    @objc private func didTap() {
        navigation.navigate(to: .regionSelection)
    }
}
