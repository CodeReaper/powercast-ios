import UIKit

class IntroViewController: ViewController {
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

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    @objc private func didTap() {
        navigation.navigate(to: .regionSelection)
    }
}
