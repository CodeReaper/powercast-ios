import UIKit
import Lottie
import SugarKit

class OnBoardingViewController: UIPageViewController {
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private let navigation: AppNavigation
    private var pages: [UIViewController]!
    private var button: Button!

    init(navigation: AppNavigation) {
        self.navigation = navigation
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        self.pages = [
            Page(supportingView: AnimationView.LocationSelection(mode: .playOnce), information: formatted(string: Translations.ONBOARDING_PAGE_LOCATION)),
            Page(supportingView: AnimationView.Euro(mode: .playOnce), information: formatted(string: Translations.ONBOARDING_PAGE_VARIABLE_COSTS)),
            Page(supportingView: AnimationView.Electricity(color: .white), information: formatted(string: Translations.ONBOARDING_PAGE_TARIFS)),
            Page(supportingView: AnimationView.QuestionMark(color: .white, mode: .playOnce), information: formatted(string: Translations.ONBOARDING_PAGE_LOOKUP))
        ]
        button = Button(text: Translations.ONBOARDING_BUTTON_NEXT, target: self, action: #selector(didTapNext))
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

        view.backgroundColor = .viewBackground

        addChild(pageViewController)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        pageViewController.setViewControllers([pages.first!], direction: .forward, animated: false)

        pageViewController.view.layout(in: view) { (make, its) in
            make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            make(its.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor))
            make(its.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor))
        }

        button.layout(in: view) { (make, its) in
            make(its.topAnchor.constraint(equalTo: pageViewController.view.bottomAnchor))
            make(its.heightAnchor.constraint(equalToConstant: 44))
            make(its.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor))
            make(its.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor))
            make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        }
    }

    @objc private func didTapNext() {
        let index = presentationIndex(for: pageViewController)
        if let next = pageViewController(pageViewController, viewControllerAfter: pages[index]) {
            pageViewController.setViewControllers([next], direction: .forward, animated: true) {
                self.pageViewController(self.pageViewController, didFinishAnimating: $0, previousViewControllers: [], transitionCompleted: true)
            }
        } else {
            navigation.navigate(to: .networkSelection)
        }
    }

    private func formatted(string: String) -> NSAttributedString {
        let normal = UIFont.italicSystemFont(ofSize: 40)
        return string.components(separatedBy: "**").enumerated().reduce(into: NSMutableAttributedString(), { string, pair in
            let font = !pair.offset.isMultiple(of: 2) ? UIFont.boldSystemFont(ofSize: normal.pointSize + 8) : normal
            string.append(NSAttributedString(string: pair.element, attributes: [NSAttributedString.Key.font: font]))
        })
    }

    private class Page: UIViewController {
        private let supportingView: LottieAnimationView
        private let information: NSAttributedString
        init(supportingView: LottieAnimationView, information: NSAttributedString) {
            self.supportingView = supportingView
            self.information = information
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            let label = Label(attributedString: information)
            label.adjustsFontSizeToFitWidth = true

            supportingView.heightAnchor.constraint(equalToConstant: 100).isActive = true
            Stack.views(
                aligned: .center,
                on: .vertical,
                spacing: 15,
                inset: NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15),
                FlexibleSpace(),
                supportingView,
                label,
                FlexibleSpace()
            ).apply(flexible: .fillEqual).layout(in: view) { (make, its) in
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
                make(its.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor))
                make(its.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor))
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            supportingView.play()
        }

        override func viewWillDisappear(_ animated: Bool) {
            supportingView.pause()
            super.viewWillDisappear(animated)
        }
    }
}

extension OnBoardingViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
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

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let current = pageViewController.viewControllers?.first else { return 0 }
        return pages.firstIndex(of: current) ?? 0
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let current = pageViewController.viewControllers?.first, completed else { return }

        if self.pageViewController(pageViewController, viewControllerAfter: current) == nil {
            button.setTitle(Translations.ONBOARDING_BUTTON_DONE, for: .normal)
        } else {
            button.setTitle(Translations.ONBOARDING_BUTTON_NEXT, for: .normal)
        }
    }
}
