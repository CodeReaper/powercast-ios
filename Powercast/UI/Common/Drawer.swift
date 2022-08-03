import UIKit

final class Drawer: UIViewController {
    enum State {
        case opened, closed
    }

    private let overlayView = UIView()

    private let sideViewController: UIViewController
    private let mainViewController: UIViewController

    private let covering: CGFloat
    private let dimmingAlpha: CGFloat

    private var screenEdgePanGesture: UIScreenEdgePanGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var contraint: NSLayoutConstraint!

    private var panStartLocation: CGPoint!
    private var panDelta: CGFloat = 0
    private var panningOffset: CGFloat = 0
    private var drawerWidth: CGFloat {
        view.bounds.width * covering
    }

    var state: Drawer.State {
        get { return overlayView.isHidden ? .closed : .opened }
        set { set(newValue, animated: false) }
    }

    init(covering: CGFloat = 0.8, dimmingAlpha: CGFloat = 0.2, drawer: UIViewController, main: UIViewController) {
        self.sideViewController = drawer
        self.mainViewController = main
        self.covering = min(1, max(0, covering))
        self.dimmingAlpha = dimmingAlpha
        super.init(nibName: nil, bundle: nil)
        screenEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOverlay))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        addChild(mainViewController)
        view.addSubview(mainViewController.view)
        view.sendSubviewToBack(mainViewController.view)
        mainViewController.didMove(toParent: self)

        addChild(sideViewController)
        view.addSubview(sideViewController.view)
        view.sendSubviewToBack(sideViewController.view)
        sideViewController.didMove(toParent: self)

        overlayView.isHidden = true
        view.addSubview(overlayView)

        setupAutolayout()

        setupGestures()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if contraint != nil && state == .opened {
            coordinator.animate { _ in
                self.contraint.constant = -self.drawerWidth
                self.view.layoutIfNeeded()
            }
        }
    }

    private func setupAutolayout() {
        mainViewController.view.translatesAutoresizingMaskIntoConstraints = false
        mainViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mainViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mainViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        contraint = mainViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        contraint.isActive = true

        sideViewController.view.translatesAutoresizingMaskIntoConstraints = false
        sideViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        sideViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        sideViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: covering).isActive = true
        sideViewController.view.leadingAnchor.constraint(equalTo: mainViewController.view.trailingAnchor).isActive = true

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        overlayView.trailingAnchor.constraint(equalTo: mainViewController.view.trailingAnchor).isActive = true
        overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupGestures() {
        screenEdgePanGesture.edges = [.right]
        screenEdgePanGesture.delegate = self
        view.addGestureRecognizer(screenEdgePanGesture)

        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)

        tapGesture.delegate = self
        overlayView.addGestureRecognizer(tapGesture)
    }

    func set(_ state: Drawer.State, animated: Bool, completion: (() -> Void)? = nil) {
        let duration: TimeInterval = animated ? 0.3 : 0

        guard let constraint = self.contraint else {
            completion?()
            return
        }

        overlayView.isHidden = false

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseOut,
            animations: { () -> Void in
                switch state {
                case .closed:
                    constraint.constant = 0
                    self.overlayView.backgroundColor = UIColor(white: 0, alpha: 0)
                case .opened:
                    constraint.constant = -self.drawerWidth
                    self.overlayView.backgroundColor = UIColor(white: 0, alpha: self.dimmingAlpha)
                }
                self.view.layoutIfNeeded()
        }, completion: { _ in
            switch state {
            case .closed:
                self.overlayView.isHidden = true
            case .opened: break
            }
            completion?()
        })
    }

    @objc final private func handlePan(sender: UIGestureRecognizer) {
        if sender.state == .began {
            panStartLocation = sender.location(in: view)
            panningOffset = state == .opened ? -drawerWidth : 0
        }

        overlayView.isHidden = false

        let delta = CGFloat(sender.location(in: view).x - panStartLocation.x)
        let constant = max(panningOffset + delta, -drawerWidth)
        let backGroundAlpha: CGFloat = min(dimmingAlpha, dimmingAlpha*(abs(constant)/drawerWidth))
        let drawerState: Drawer.State = panDelta >= 0 ? .closed : .opened

        panningOffset = constant
        contraint.constant = min(0, constant)
        overlayView.backgroundColor = UIColor(white: 0, alpha: backGroundAlpha)

        switch sender.state {
        case .changed:
            panStartLocation = sender.location(in: view)
            panDelta = delta
        case .ended, .cancelled:
            set(drawerState, animated: true)
        default:
            break
        }
    }

    @objc final private func didTapOverlay() {
        set(.closed, animated: true)
    }
}

extension Drawer: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        switch gestureRecognizer {
        case panGesture:
            return state == .opened
        case screenEdgePanGesture:
            return state == .closed
        default:
            return touch.view == gestureRecognizer.view
        }
    }
}
