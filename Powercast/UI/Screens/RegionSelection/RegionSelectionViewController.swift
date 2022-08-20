import UIKit
import MapKit

class RegionSelectionViewController: ViewController {
    struct Configuration {
        enum Behavior {
            case navigate(endpoint: Navigation)
            case pop
        }

        let behavior: Behavior
    }

    private let mapView = MKMapView(frame: .zero)
    private let fillColor  = UIColor.blue.withAlphaComponent(0.05)
    private let strokeColor  = UIColor.black.withAlphaComponent(0.2)
    private let selectedFillColor  = UIColor.blue.withAlphaComponent(0.1)
    private let selectedStrokeColor  = UIColor.black.withAlphaComponent(0.2)

    private let configuration: Configuration

    private var interactor: RegionSelectionInteractor!

    private var selectedRegion: String?

    init(navigation: AppNavigation, configuration: Configuration, repository: StateRepository) {
        self.configuration = configuration
        super.init(navigation: navigation)
        self.interactor = RegionSelectionInteractor(navigation: navigation, delegate: self, repository: repository)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.REGION_SELECTION_TITLE

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
        let region: String
        let polygon: MKPolygon

        var coordinate: CLLocationCoordinate2D { polygon.coordinate }
        var boundingMapRect: MKMapRect { polygon.boundingMapRect }

        init(region: String, polygon: MKPolygon) {
            self.region = region
            self.polygon = polygon
        }
    }
}

extension RegionSelectionViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? Polygon {
            let render = MKPolygonRenderer(overlay: overlay.polygon)
            if overlay.region == selectedRegion {
                render.fillColor = selectedFillColor
                render.strokeColor = selectedStrokeColor
            } else {
                render.fillColor = fillColor
                render.strokeColor = strokeColor
            }
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

extension RegionSelectionViewController: RegionSelectionDelegate {
    func show(overlays: [MKOverlay], selectedRegion: String?) {
        self.selectedRegion = selectedRegion
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)
    }
}
