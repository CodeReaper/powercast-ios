import UIKit
import Lottie
import SugarKit

class IntroductionViewController: UIPageViewController {
    // FIXME: colors, translations
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let pages: [UIViewController]
    private let navigation: AppNavigation

    private var button: Button!

    init(navigation: AppNavigation) {
        let locationText = "Your **location**\nAffects\nYour **price**".components(separatedBy: "**").enumerated().reduce(into: NSMutableAttributedString(), { string, pair in
            let font = !pair.offset.isMultiple(of: 2) ? UIFont.boldSystemFont(ofSize: 48) : UIFont.italicSystemFont(ofSize: 40)
            string.append(NSAttributedString(string: pair.element, attributes: [NSAttributedString.Key.font: font]))
        })

        let locationText2 = "Your2 **location**\nAffects\nYour **price**".components(separatedBy: "**").enumerated().reduce(into: NSMutableAttributedString(), { string, pair in
            let font = !pair.offset.isMultiple(of: 2) ? UIFont.boldSystemFont(ofSize: 48) : UIFont.italicSystemFont(ofSize: 40)
            string.append(NSAttributedString(string: pair.element, attributes: [NSAttributedString.Key.font: font]))
        })

        let locationText3 = "Your3 **location**\nAffects\nYour **price**".components(separatedBy: "**").enumerated().reduce(into: NSMutableAttributedString(), { string, pair in
            let font = !pair.offset.isMultiple(of: 2) ? UIFont.boldSystemFont(ofSize: 48) : UIFont.italicSystemFont(ofSize: 40)
            string.append(NSAttributedString(string: pair.element, attributes: [NSAttributedString.Key.font: font]))
        })

        self.pages = [
            Page(supportingView: AnimationView.LocationSelection(mode: .playOnce), information: locationText),
            Page(supportingView: AnimationView.Electricity(color: .white), information: locationText2),
            Page(supportingView: AnimationView.QuestionMark(color: .white, mode: .playOnce), information: locationText3)
        ]
        self.navigation = navigation
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)

        button = Button(text: "Continue", target: self, action: #selector(didTapNext))
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
        navigation.navigate(to: .networkSelection(forceSelection: false))
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
            supportingView.loopMode = .playOnce
            supportingView.layout(in: view) { (make, its) in
                make(its.heightAnchor.constraint(equalToConstant: 100))
                make(its.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor))
                make(its.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor))
                make(its.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor))
            }
            Label(attributedString: information).layout(in: view) { (make, its) in
                make(its.topAnchor.constraint(equalTo: supportingView.bottomAnchor))
                make(its.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor))
                make(its.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor))
                make(its.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor))
                make(its.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor))
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

extension IntroductionViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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
            button.setTitle("Done", for: .normal)
        } else {
            button.setTitle("Continue", for: .normal)
        }
    }
}
