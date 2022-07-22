import UIKit
import MapKit

class RegionSelectionViewController: ViewController {
    private let mapView = MKMapView(frame: .zero)
    private let fillColor  = UIColor.blue.withAlphaComponent(0.05)
    private let strokeColor  = UIColor.black.withAlphaComponent(0.2)
    private let selectedFillColor  = UIColor.blue.withAlphaComponent(0.1)
    private let selectedStrokeColor  = UIColor.black.withAlphaComponent(0.2)

    private var overlays: [PolygonWrapper] = []

    private var selectedRegion: String? {
        didSet {
            if selectedRegion == nil {
                navigationItem.rightBarButtonItem = nil
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Translations.REGION_SELECTION_TITLE

        view.backgroundColor = .white

        mapView.delegate = self
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMap)))
        mapView.setup(in: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let url = Bundle.main.url(forResource: "regions", withExtension: "geojson") else {
            fatalError("unable to get geojson")
        }

        let geoJson: [MKGeoJSONObject]
        do {
            geoJson = try MKGeoJSONDecoder().decode(Data(contentsOf: url))
        } catch {
            fatalError("Unable to decode JSON")
        }

        for item in geoJson {
            guard
                let feature = item as? MKGeoJSONFeature,
                let propertyData = feature.properties,
                let regionCode = (try? JSONDecoder().decode(Properties.self, from: propertyData))?.REGIONKODE,
                let polygons = Optional.some(feature.geometry.compactMap({ $0 as? MKPolygon }))
            else {
                continue
            }

            for item in polygons {
                overlays.append(PolygonWrapper(region: regionCode, polygon: item))
            }
        }

        mapView.addOverlays(overlays)
    }

    @objc private func didTapMap(_ sender: UITapGestureRecognizer) {
        let coordinate = MKMapPoint(mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView))

        for item in overlays {
            let render = MKPolygonRenderer(overlay: item.polygon)
            if render.path.contains(render.point(for: coordinate)) {
                if selectedRegion == item.region {
                    selectedRegion = nil
                } else {
                    selectedRegion = item.region
                }
                mapView.removeOverlays(overlays)
                mapView.addOverlays(overlays)
                break
            }
        }
    }

    @objc private func didTapSave() {
        // TODO: convert region to zone and persist it

        navigation.navigate(to: .loadData)
    }
}

extension RegionSelectionViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? PolygonWrapper {
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
}

private struct Properties: Codable {
    let REGIONKODE: String
}

private class PolygonWrapper: NSObject, MKOverlay {
    let region: String
    let polygon: MKPolygon

    var coordinate: CLLocationCoordinate2D { polygon.coordinate }
    var boundingMapRect: MKMapRect { polygon.boundingMapRect }

    init(region: String, polygon: MKPolygon) {
        self.region = region
        self.polygon = polygon
    }
}
