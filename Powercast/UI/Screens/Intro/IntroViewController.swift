import UIKit

class IntroViewController: ViewController {
    private let overlayBackground = UIView()
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let button: Button
    private let pages: [UIViewController]

    private var fullConstraints: [NSLayoutConstraint] = []
    private var halfConstraints: [NSLayoutConstraint] = []

    private var interactor: IntroInteractor!

    init(navigation: AppNavigation, state: State, energyPriceDatabase: EnergyPriceDatabase) {
        self.pages = [
            Page(
                view: Stack.views(
                    aligned: .center,
                    on: .vertical,
                    spacing: 10,
                    Label(style: .title1, text: Translations.INTRO_PAGE_REGION_SELECTION_TITLE, color: .black).aligned(to: .center),
                    Label(style: .body, text: Translations.INTRO_PAGE_REGION_SELECTION_MESSAGE, color: .black),
                    ImageView(image: Images.powercast_splash, mode: .center).set(height: 175)
                ).fill()
            ),
            Page(
                view: Stack.views(
                    aligned: .center,
                    on: .vertical,
                    spacing: 10,
                    Label(style: .title1, text: Translations.INTRO_PAGE_DASHBOARD_TITLE, color: .black).aligned(to: .center),
                    Label(style: .body, text: Translations.INTRO_PAGE_DASHBOARD_MESSAGE, color: .black),
                    ImageView(image: Images.powercast_splash, mode: .center).set(height: 175)
                ).fill()
            ),
            Page(
                view: Stack.views(
                    aligned: .center,
                    on: .vertical,
                    spacing: 10,
                    Label(style: .title1, text: Translations.INTRO_PAGE_NOTIFICATIONS_TITLE, color: .black).aligned(to: .center),
                    Label(style: .body, text: Translations.INTRO_PAGE_NOTIFICATIONS_MESSAGE, color: .black),
                    ImageView(image: Images.powercast_splash, mode: .center).set(height: 175)
                ).fill()
            ),
            Page(
                view: Stack.views(
                    aligned: .center,
                    on: .vertical,
                    spacing: 10,
                    Label(style: .title1, text: Translations.INTRO_PAGE_READY_TITLE, color: .black).aligned(to: .center),
                    Label(style: .body, text: Translations.INTRO_PAGE_READY_MESSAGE, color: .black),
                    ImageView(image: Images.powercast_splash, mode: .center).set(height: 175)
                ).fill()
            )
        ]
        self.button = RoundedButton(text: Translations.INTRO_PAGES_BUTTON_NEXT)
        super.init(navigation: navigation)
        self.interactor = IntroInteractor(delegate: self, state: state, energyPriceDatabase: energyPriceDatabase)
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

        addChild(pageViewController)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        if let first = pages.first {
            pageViewController.setViewControllers([first], direction: .forward, animated: true)
        }

        ImageView(image: Images.offshore_wind_power, mode: .scaleAspectFill).setup(in: view, usingSafeLayout: false)

        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        let stackView = Stack.views(
            aligned: .center,
            on: .vertical,
            spacing: 15,
            inset: NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0),
            ImageView(image: Images.powercast_splash, mode: .center).inset(NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)),
            pageViewController.view,
            button.set(height: 44).inset(NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
        )
        .fill()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        fullConstraints.append(contentsOf: [
            stackView.safeAreaLayoutGuide.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            stackView.safeAreaLayoutGuide.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            stackView.safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stackView.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        halfConstraints.append(contentsOf: [
            stackView.safeAreaLayoutGuide.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.666),
            stackView.safeAreaLayoutGuide.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            stackView.safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stackView.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])

        overlayBackground.isUserInteractionEnabled = true
        overlayBackground.backgroundColor = Color.primary
        overlayBackground.setup(in: view, usingSafeLayout: false)

        let imageView = ImageView(image: Images.powercast_splash, mode: .center).setup(centeredIn: overlayBackground, usingSafeLayout: false)

        SpinnerView(color: .white).startAnimating().set(height: 60).setup(under: imageView, in: overlayBackground)

        layoutTrait(traitCollection: UIScreen.main.traitCollection)

        interactor.viewDidLoad()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layoutTrait(traitCollection: traitCollection)
    }

    private func layoutTrait(traitCollection: UITraitCollection) {
        if traitCollection.userInterfaceIdiom != .phone {
            NSLayoutConstraint.deactivate(fullConstraints)
            NSLayoutConstraint.activate(halfConstraints)
        } else {
            NSLayoutConstraint.deactivate(halfConstraints)
            NSLayoutConstraint.activate(fullConstraints)
        }
    }

    @objc private func didTap() {
        let index = presentationIndex(for: pageViewController)

        if let next = pageViewController(pageViewController, viewControllerAfter: pages[index]) {
            pageViewController.setViewControllers([next], direction: .forward, animated: true) {
                self.pageViewController(self.pageViewController, didFinishAnimating: $0, previousViewControllers: [], transitionCompleted: true)
            }
        } else {
            navigation.navigate(to: .regionSelection(configuration: RegionSelectionViewController.Configuration(behavior: .navigate(endpoint: .loadData))))
        }
    }

    private class Page: UIViewController {
        private let background = UIView()

        init(view page: UIView) {
            super.init(nibName: nil, bundle: nil)

            view = UIView()
            view.backgroundColor = .clear

            let stackView = Stack.views(
                on: .vertical,
                inset: NSDirectionalEdgeInsets(top: 0, leading: 25, bottom: 15, trailing: 25),
                FlexibleSpace(),
                page,
                FlexibleSpace()
            )
                .apply(flexible: .fillEqual)
                .setup(in: view)

            background.backgroundColor = .white
            background.layer.cornerRadius = 10
            background.setup(matching: page, in: stackView, inset: NSDirectionalEdgeInsets(top: -10, leading: -10, bottom: -10, trailing: -10))
            stackView.sendSubviewToBack(background)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension IntroViewController: IntroDelegate {
    func showIntroduction() {
        UIView.animate(withDuration: 0.9) {
            self.overlayBackground.alpha = 0
        } completion: { _ in
            self.overlayBackground.removeFromSuperview()
        }
    }

    func showDashboard() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigation.navigate(to: .dashboard)
    }
}

extension IntroViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let index = pages.firstIndex(of: viewController),
            let wanted = Optional.some(index + 1),
            pages.count != wanted,
            pages.count > wanted
        else {
            return nil
        }

        return pages[wanted]
    }

    func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let index = pages.firstIndex(of: viewController),
            let wanted = Optional.some(index - 1),
            wanted >= 0,
            pages.count > wanted
        else {
            return nil
        }

        return pages[wanted]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let current = pageViewController.viewControllers?.first else { return 0 }
        return pages.firstIndex(of: current) ?? 0
    }
}

extension IntroViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let current = pageViewController.viewControllers?.first, completed else { return }

        if self.pageViewController(pageViewController, viewControllerAfter: current) == nil {
            button.setTitle(Translations.INTRO_PAGES_BUTTON_DONE, for: .normal)
        } else {
            button.setTitle(Translations.INTRO_PAGES_BUTTON_NEXT, for: .normal)
        }
    }
}
