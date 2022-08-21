import Foundation
import MapKit

protocol ZoneSelectionDelegate: AnyObject {
    func show(loading: Bool)
    func show(overlays: [MKOverlay], selected: Int?)
    func didSelect(zone: Zone)
}

class ZoneSelectionInteractor {
    private let navigation: AppNavigation
    private let repository: StateRepository

    private var overlays: [ZoneSelectionViewController.Polygon] = []

    private var selected: Int?

    private weak var delegate: ZoneSelectionDelegate?

    init(navigation: AppNavigation, delegate: ZoneSelectionDelegate, repository: StateRepository) {
        self.navigation = navigation
        self.delegate = delegate
        self.repository = repository
    }

    func viewDidLoad() {
        delegate?.show(loading: true)

        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "postnumre", withExtension: "geojson") else {
                fatalError("Unable to find regions geojson in main bundle")
            }

            let geoJson: [MKGeoJSONObject]
            do {
                geoJson = try MKGeoJSONDecoder().decode(Data(contentsOf: url))
            } catch {
                fatalError("Unable to decode JSON: \(error)")
            }

            for item in geoJson {
                guard
                    let feature = item as? MKGeoJSONFeature,
                    let propertyData = feature.properties,
                    let number = (try? JSONDecoder().decode(Properties.self, from: propertyData))?.nr,
                    let code = Int(number),
                    let polygons = Optional.some(feature.geometry.compactMap({ $0 as? MKMultiPolygon }))
                else {
                    continue
                }

                for item in polygons {
                    self.overlays.append(ZoneSelectionViewController.Polygon(code: code, polygon: item))
                }
            }

            DispatchQueue.main.async {
                self.delegate?.show(overlays: self.overlays, selected: nil)
                self.delegate?.show(loading: false)
            }
        }
    }

    func didTap(_ location: CGPoint, in mapView: MKMapView) {
        let coordinate = MKMapPoint(mapView.convert(location, toCoordinateFrom: mapView))
        for item in overlays {
            let render = MKMultiPolygonRenderer(overlay: item.polygon)
            if render.path.contains(render.point(for: coordinate)) {
                selected = item.code
                delegate?.show(overlays: overlays, selected: item.code)

                navigation.navigate(to: .actionSheet(options: [
                    ActionSheetOption.message(text: Translations.ZONE_SELECTION_CONFIRMATION_MESSAGE("\(item.code)")),
                    .style(preference: .actionSheet),
                    .cancel(text: Translations.ZONE_SELECTION_CONFIRMATION_NEGATIVE_BUTTON, action: nil),
                    .button(text: Translations.ZONE_SELECTION_CONFIRMATION_POSITIVE_BUTTON, action: { self.didTapSave() }),
                    .source(view: mapView, rect: CGRect(origin: location, size: .zero))
                ]))
                break
            }
        }
    }

    func didTapSave() {
        guard let zip = selected, zip >= 1000 && zip <= 9999 else {
            return
        }

        let zone: Zone = zip > 5000 ? .dk1 : .dk2
        repository.select(zone: zone, zipCode: zip)
        delegate?.didSelect(zone: zone)
    }
}

private struct Properties: Codable {
    let nr: String // swiftlint:disable:this identifier_name
}
