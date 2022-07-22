import UIKit
import Combine

class DataLoadingViewController: ViewController {
    private let loadingView = View.buildLoadingView(color: UIColor.from(hex: "#96D4E7"))

    private let repository: EnergyPriceRepository

    private var statusSink: AnyCancellable?

    init(navigation: AppNavigation, repository: EnergyPriceRepository) {
        self.repository = repository
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadingView.play()

        statusSink = repository.status.receive(on: DispatchQueue.main).sink { [weak self] in
            switch $0 {
            case .updated:
                self?.navigation.navigate(to: .dashboard)
            case .failed:
                break // TODO: handle error
            default: break
            }
        }
        repository.refresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        loadingView.stop()
        statusSink = nil

        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.DATA_LOADING_TITLE

        view.backgroundColor = .white

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
    }
}
