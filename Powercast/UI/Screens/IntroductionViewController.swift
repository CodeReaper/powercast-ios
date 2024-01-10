import UIKit
import Lottie
import SugarKit

class IntroductionViewController: ViewController {
    // FIXME: colors, translations
    private let animation = View.buildQuestionMarkView(color: .white)
//    private let animation = LottieAnimationView(name: Animations.locationSelection)

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        animation.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        animation.pause()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .viewBackground
        animation.layout(in: view) { (make, its) in
            make(its.heightAnchor.constraint(equalToConstant: 300))
            make(its.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor))
            make(its.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor))
            make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        }

        let sequence = "Your **location**\nAffects\nYour **price**".components(separatedBy: "**").enumerated()
        let text = sequence.reduce(into: NSMutableAttributedString(), { string, pair in
//            let font = !pair.offset.isMultiple(of: 2) ? UIFont.boldSystemFont(ofSize: 55) : UIFont.systemFont(ofSize: 40)
            let font = !pair.offset.isMultiple(of: 2) ? UIFont.boldSystemFont(ofSize: 48) : UIFont.italicSystemFont(ofSize: 40)
            string.append(NSAttributedString(string: pair.element, attributes: [NSAttributedString.Key.font: font]))
        })

        Label(attributedString: text).setup(centeredIn: view)

        Button(text: "Continue", target: self, action: #selector(didTapNext)).layout(in: view) { (make, its) in
            make(its.heightAnchor.constraint(equalToConstant: 44))
            make(its.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor))
            make(its.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor))
            make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        }
    }

    @objc private func didTapNext() {
        navigate(to: .networkSelection(forceSelection: false))
    }
}
