// swiftlint:disable all
import Foundation
struct Translations {
	static let ABOUT_TITLE = NSLocalizedString("ABOUT_TITLE", comment: "")
	static let DASHBOARD_TITLE = NSLocalizedString("DASHBOARD_TITLE", comment: "")
	static let DATA_LOADING_TITLE = NSLocalizedString("DATA_LOADING_TITLE", comment: "")
	static let INTRO_TITLE = NSLocalizedString("INTRO_TITLE", comment: "")
	static func INTRO_WELCOME_MESSAGE(_ p1: String) -> String { return NSLocalizedString("INTRO_WELCOME_MESSAGE", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static let INTRO_WELCOME_TITLE = NSLocalizedString("INTRO_WELCOME_TITLE", comment: "")
	static let LICENSES_TITLE = NSLocalizedString("LICENSES_TITLE", comment: "")
	static let REGION_SELECTION_TITLE = NSLocalizedString("REGION_SELECTION_TITLE", comment: "")
	static let SETTINGS_TITLE = NSLocalizedString("SETTINGS_TITLE", comment: "")
}
