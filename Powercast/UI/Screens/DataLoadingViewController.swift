import UIKit
import Combine

class DataLoadingViewController: ViewController {
    private let loadingView = View.buildLoadingView(color: .white)
    private let loadingLabel = Label(text: "")

    private let repository: EnergyPriceRepository

    private var statusSink: AnyCancellable?
    private var refreshTask: Task<Void, Never>?

    init(navigation: AppNavigation, repository: EnergyPriceRepository) {
        self.repository = repository
        super.init(navigation: navigation)
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadingView.play()

        let dispatch = DispatchGroup()

        dispatch.enter()
        Task {
            try? await Task.sleep(seconds: 1.0)
            dispatch.leave()
        }

        dispatch.enter()
        statusSink = repository.status.receive(on: DispatchQueue.main).sink { [weak self] in
            switch $0 {
            case let .updating(progress):
                self?.loadingLabel.text = String(format: "%.0f%%", progress * 100)
            case .updated:
                dispatch.leave()
            case .failed:
                self?.navigation.navigate(to: .actionSheet(options: [
                    ActionSheetOption.title(text: Translations.DATA_LOADING_REFRESH_FAILED_TITLE),
                    .message(text: Translations.DATA_LOADING_REFRESH_FAILED_MESSAGE),
                    .style(preference: .alert),
                    .cancel(text: Translations.DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON, action: { self?.navigationController?.popViewController(animated: true) }),
                    .button(text: Translations.DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON, action: { self?.refreshTask = self?.repository.refresh() })
                ]))
            default: break
            }
        }
        refreshTask = repository.refresh()

        dispatch.notify(queue: .main) { [weak self] in
            self?.navigation.navigate(to: .dashboard)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        loadingView.stop()
        statusSink = nil
        refreshTask?.cancel()

        super.viewWillDisappear(animated)
    }
}
