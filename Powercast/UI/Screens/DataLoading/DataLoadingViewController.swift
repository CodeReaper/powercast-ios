import UIKit
import SugarKit

class DataLoadingViewController: ViewController {
    private let loadingView = View.buildLoadingView(color: .spinner)

    private var interactor: DataLoadingInteractor!

    init(navigation: AppNavigation, prices: EnergyPriceRepository, charges: ChargesRepository, emission: EmissionRepository, state: StateRepository, network: Network) {
        super.init(navigation: navigation)
        interactor = DataLoadingInteractor(
            navigation: navigation,
            delegate: self,
            prices: prices,
            charges: charges,
            emission: emission,
            state: state,
            network: network
        )
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
    func displayFailed() {
        navigate(to: .actionSheet(options: [
            ActionSheetOption.title(text: Translations.DATA_LOADING_REFRESH_FAILED_TITLE),
            .message(text: Translations.DATA_LOADING_REFRESH_FAILED_MESSAGE),
            .style(preference: .alert),
            .cancel(text: Translations.DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON, action: { _ in self.navigationController?.popViewController(animated: true) }),
            .button(text: Translations.DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON, action: { _ in self.interactor.retry() })
        ]))
    }
}
