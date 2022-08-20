import Foundation
import UIKit

enum Zone: String, Codable, CaseIterable {
    case dk1 = "DK1"
    case dk2 = "DK2"
}

extension Zone {
    var color: UIColor {
        switch self {
        case .dk1:
            return Color.pastelGreen
        case .dk2:
            return Color.pastelRed
        }
    }

    var name: String {
        switch self {
        case .dk1:
            return Translations.ZONE_DK1
        case .dk2:
            return Translations.ZONE_DK2
        }
    }
}
