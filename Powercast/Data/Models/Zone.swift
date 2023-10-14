import Foundation
import UIKit

enum Zone: String, Codable, CaseIterable {
    case dk1 = "DK1"
    case dk2 = "DK2"
}

extension Zone {
    var name: String {
        switch self {
        case .dk1:
            return Translations.ZONE_DK1
        case .dk2:
            return Translations.ZONE_DK2
        }
    }
}
