import UIKit

class DataLoadingViewController: ViewController {
    private let repository: EnergyPriceRepository

    init(navigation: AppNavigation, repository: EnergyPriceRepository) {
        self.repository = repository
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            do {
                try await repository.refresh()
            } catch {
                print(error)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.DATA_LOADING_TITLE

        view.backgroundColor = .white

        Stack.views(aligned: .center, on: .vertical, Label(text: Translations.DATA_LOADING_TITLE)).setup(in: view)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    @objc private func didTap() {
        navigation.navigate(to: .dashboard)
    }
}
