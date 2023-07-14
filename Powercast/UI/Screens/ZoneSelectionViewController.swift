import UIKit
import MapKit
import SugarKit

class ZoneSelectionViewController: ViewController {
    struct Configuration {
        enum Behavior {
            case navigate(endpoint: Navigation)
            case pop
        }

        let behavior: Behavior
    }

    private let imageView = UIImageView()
    private let zones: [Zone] = [.dk1, .dk2]

    private let segmentedControl: UISegmentedControl
    private let configuration: Configuration
    private let repository: StateRepository

    init(navigation: AppNavigation, configuration: Configuration, repository: StateRepository) {
        self.configuration = configuration
        self.repository = repository

        segmentedControl = UISegmentedControl(items: zones.map { $0.name })

        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.ZONE_SELECTION_TITLE

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .red

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(didChangeIndex), for: .valueChanged)

        let button = RoundedButton(text: Translations.ZONE_SELECTION_CONFIRMATION_POSITIVE_BUTTON, backgroundColor: .white, target: self, action: #selector(didTapChoose))

        Stack.views(
            aligned: .center,
            on: .vertical,
            spacing: 22,
            inset: NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10),
            FlexibleSpace(),
            imageView,
            segmentedControl.set(height: 44),
            button.set(height: 44)
        ).fill().layout(in: view) { make, its in
            make(its.safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            make(its.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
            make(its.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
            make(its.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        }

        didChangeIndex()
    }

    @objc private func didTapChoose() {
        repository.select(zone: zones[segmentedControl.selectedSegmentIndex])
        switch configuration.behavior {
        case .navigate(let endpoint):
            navigation.navigate(to: endpoint)
        case .pop:
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func didChangeIndex() {
        update(image: zones[segmentedControl.selectedSegmentIndex])
    }

    private func update(image zone: Zone) {
        switch zone {
        case .dk1:
            imageView.image = Images.dk1
        case .dk2:
            imageView.image = Images.dk2
        }
    }
}
