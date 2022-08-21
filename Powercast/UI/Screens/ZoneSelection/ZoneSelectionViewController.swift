import UIKit
import MapKit

class ZoneSelectionViewController: ViewController {
    struct Configuration {
        enum Behavior {
            case navigate(endpoint: Navigation)
            case pop
        }

        let behavior: Behavior
    }

    private let mapView = MKMapView(frame: .zero)
    private let spinnerView = SpinnerView()
    private let fillColor  = UIColor.blue.withAlphaComponent(0.05)
    private let strokeColor  = UIColor.black.withAlphaComponent(0.2)
    private let selectedFillColor  = UIColor.blue.withAlphaComponent(0.1)
    private let selectedStrokeColor  = UIColor.black.withAlphaComponent(0.2)

    private let configuration: Configuration

    private var interactor: ZoneSelectionInteractor!

    private var selected: Int?

    init(navigation: AppNavigation, configuration: Configuration, repository: StateRepository) {
        self.configuration = configuration
        super.init(navigation: navigation)
        self.interactor = ZoneSelectionInteractor(navigation: navigation, delegate: self, repository: repository)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.ZONE_SELECTION_TITLE

        spinnerView.setup(centeredIn: view)

        mapView.delegate = self
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMap)))

        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        mapView.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        interactor.viewDidLoad()
    }

    @objc private func didTapMap(_ sender: UITapGestureRecognizer) {
        interactor.didTap(sender.location(in: mapView), in: mapView)
    }

    @objc private func didTapSave() {
        interactor.didTapSave()
    }

    class Polygon: NSObject, MKOverlay {
        let code: Int
        let polygon: MKMultiPolygon

        var coordinate: CLLocationCoordinate2D { polygon.coordinate }
        var boundingMapRect: MKMapRect { polygon.boundingMapRect }

        init(code: Int, polygon: MKMultiPolygon) {
            self.code = code
            self.polygon = polygon
        }
    }
}

extension ZoneSelectionViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? Polygon {
            let render = MKMultiPolygonRenderer(overlay: overlay.polygon)
            return render
        }
        fatalError("Received unknown overlay: \(overlay)")
    }

    func didSelect(zone: Zone) {
        switch configuration.behavior {
        case .navigate(let endpoint):
            navigation.navigate(to: endpoint)
        case .pop:
            navigationController?.popViewController(animated: true)
        }
    }
}

extension ZoneSelectionViewController: ZoneSelectionDelegate {
    func show(overlays: [MKOverlay], selected: Int?) {
        self.selected = selected
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)
    }

    func show(loading: Bool) {
        if loading {
            spinnerView.startAnimating().isHidden = false
            mapView.isHidden = true
        } else {
            spinnerView.stopAnimating().isHidden = true
            mapView.isHidden = false
        }
    }
}
