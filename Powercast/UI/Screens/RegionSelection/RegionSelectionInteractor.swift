import Foundation
import MapKit

protocol RegionSelectionDelegate: AnyObject {
    func show(overlays: [MKOverlay], selectedRegion: String?)
    func didSelect(zone: Zone)
}

class RegionSelectionInteractor {
    private let navigation: AppNavigation
    private let repository: StateRepository

    private var overlays: [RegionSelectionViewController.Polygon] = []

    private var selectedRegion: Region?

    private weak var delegate: RegionSelectionDelegate?

    init(navigation: AppNavigation, delegate: RegionSelectionDelegate, repository: StateRepository) {
        self.navigation = navigation
        self.delegate = delegate
        self.repository = repository
    }

    func viewDidLoad() {
        guard let url = Bundle.main.url(forResource: "regions", withExtension: "geojson") else {
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
                let regionCode = (try? JSONDecoder().decode(Properties.self, from: propertyData))?.REGIONKODE,
                let polygons = Optional.some(feature.geometry.compactMap({ $0 as? MKPolygon }))
            else {
                continue
            }

            for item in polygons {
                overlays.append(RegionSelectionViewController.Polygon(region: regionCode, polygon: item))
            }
        }

        delegate?.show(overlays: overlays, selectedRegion: nil)
    }

    func didTap(_ location: CGPoint, in mapView: MKMapView) {
        let coordinate = MKMapPoint(mapView.convert(location, toCoordinateFrom: mapView))
        for item in overlays {
            let render = MKPolygonRenderer(overlay: item.polygon)
            if render.path.contains(render.point(for: coordinate)) {
                if let region = Region(rawValue: item.region) {
                    selectedRegion = region
                    delegate?.show(overlays: overlays, selectedRegion: selectedRegion?.rawValue)

                    navigation.navigate(to: .actionSheet(options: [
                        ActionSheetOption.title(text: region.name),
                        .message(text: Translations.REGION_SELECTION_CONFIRMATION_MESSAGE),
                        .style(preference: .actionSheet),
                        .cancel(text: Translations.REGION_SELECTION_CONFIRMATION_NEGATIVE_BUTTON, action: nil),
                        .button(text: Translations.REGION_SELECTION_CONFIRMATION_POSITIVE_BUTTON, action: { self.didTapSave() }),
                        .source(view: mapView, rect: CGRect(origin: location, size: .zero))
                    ]))
                }
                break
            }
        }
    }

    func didTapSave() {
        let zone: Zone
        switch selectedRegion {
        case .captial, .zealand:
            zone = .dk2
        case .central, .north, .south:
            zone = .dk1
        default:
            return
        }

        repository.select(zone)
        delegate?.didSelect(zone: zone)
    }
}

private struct Properties: Codable {
    let REGIONKODE: String
}

private enum Region: String {
    case north = "1081"
    case central = "1082"
    case south = "1083"
    case captial = "1084"
    case zealand = "1085"

    var name: String {
        switch self {
        case .captial: return Translations.REGION_NAME_CAPTIAL
        case .central: return Translations.REGION_NAME_CENTRAL
        case.north: return Translations.REGION_NAME_NORTH
        case .zealand: return Translations.REGION_NAME_ZEALAND
        case .south: return Translations.REGION_NAME_SOUTH
        }
    }
}
