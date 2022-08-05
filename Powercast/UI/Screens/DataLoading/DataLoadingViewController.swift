import UIKit

class DataLoadingViewController: ViewController {
    private let loadingView = View.buildLoadingView(color: .white)
    private let loadingLabel = Label(text: "")

    private var interactor: DataLoadingInteractor!

    init(navigation: AppNavigation, energyPriceRepository: EnergyPriceRepository, stateRepository: StateRepository) {
        super.init(navigation: navigation)
        interactor = DataLoadingInteractor(navigation: navigation, delegate: self, energyPriceRepository: energyPriceRepository, stateRepository: stateRepository)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.DATA_LOADING_TITLE

        Stack.views(
            aligned: .center,
            on: .vertical,
            FlexibleSpace(),
            loadingView,
            loadingLabel,
            Label(text: Translations.DATA_LOADING_TITLE),
            FlexibleSpace()
        )
        .apply(flexible: .fillEqual)
        .setup(in: view)

        interactor.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingView.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        loadingView.stop()
        super.viewWillDisappear(animated)
    }
}

extension DataLoadingViewController: DataLoadingDelegate {
    func display(progress: String) {
        loadingLabel.text = progress
    }

    func displayFailed() {
        navigation.navigate(to: .actionSheet(options: [
            ActionSheetOption.title(text: Translations.DATA_LOADING_REFRESH_FAILED_TITLE),
            .message(text: Translations.DATA_LOADING_REFRESH_FAILED_MESSAGE),
            .style(preference: .alert),
            .cancel(text: Translations.DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON, action: { self.navigationController?.popViewController(animated: true) }),
            .button(text: Translations.DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON, action: { self.interactor.retry() })
        ]))
    }
}