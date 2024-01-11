import UIKit
import SugarKit

class DataLoadingViewController: ViewController {
    private let loadingView = AnimationView.Loading(color: .spinner)
    private let progressView = UIProgressView()

    private var interactor: DataLoadingInteractor!

    init(navigation: AppNavigation, prices: EnergyPriceRepository, charges: ChargesRepository, emission: EmissionRepository, state: NetworkState, network: Network) {
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

        progressView.progressTintColor = .gaugeProgress
        progressView.trackTintColor = .gaugeTint
        progressView.progress = 0

        Stack.views(
            aligned: .center,
            on: .vertical,
            FlexibleSpace(),
            Stack.views(
                on: .vertical,
                loadingView.set(width: 150).set(height: 150),
                progressView
            ),
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

    func display(progress: Float) {
        progressView.setProgress(progress, animated: true)
    }
}
