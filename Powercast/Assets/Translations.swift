// swiftlint:disable all
import Foundation
struct Translations {
	static let DASHBOARD_GRAPH_LABEL_FORMAT = NSLocalizedString("DASHBOARD_GRAPH_LABEL_FORMAT", comment: "")
	static let DASHBOARD_TITLE = NSLocalizedString("DASHBOARD_TITLE", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_MESSAGE = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_MESSAGE", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_TITLE = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_TITLE", comment: "")
	static let DATA_LOADING_TITLE = NSLocalizedString("DATA_LOADING_TITLE", comment: "")
	static let INTRO_PAGES_BUTTON_DONE = NSLocalizedString("INTRO_PAGES_BUTTON_DONE", comment: "")
	static let INTRO_PAGES_BUTTON_NEXT = NSLocalizedString("INTRO_PAGES_BUTTON_NEXT", comment: "")
	static let INTRO_PAGE_DASHBOARD_MESSAGE = NSLocalizedString("INTRO_PAGE_DASHBOARD_MESSAGE", comment: "")
	static let INTRO_PAGE_DASHBOARD_TITLE = NSLocalizedString("INTRO_PAGE_DASHBOARD_TITLE", comment: "")
	static let INTRO_PAGE_NOTIFICATIONS_MESSAGE = NSLocalizedString("INTRO_PAGE_NOTIFICATIONS_MESSAGE", comment: "")
	static let INTRO_PAGE_NOTIFICATIONS_TITLE = NSLocalizedString("INTRO_PAGE_NOTIFICATIONS_TITLE", comment: "")
	static let INTRO_PAGE_READY_MESSAGE = NSLocalizedString("INTRO_PAGE_READY_MESSAGE", comment: "")
	static let INTRO_PAGE_READY_TITLE = NSLocalizedString("INTRO_PAGE_READY_TITLE", comment: "")
	static let INTRO_PAGE_ZIP_SELECTION_MESSAGE = NSLocalizedString("INTRO_PAGE_ZIP_SELECTION_MESSAGE", comment: "")
	static let INTRO_PAGE_ZIP_SELECTION_TITLE = NSLocalizedString("INTRO_PAGE_ZIP_SELECTION_TITLE", comment: "")
	static let INTRO_TITLE = NSLocalizedString("INTRO_TITLE", comment: "")
	static let LICENSES_ASSETS_TITLE = NSLocalizedString("LICENSES_ASSETS_TITLE", comment: "")
	static let LICENSES_PACKAGES_TITLE = NSLocalizedString("LICENSES_PACKAGES_TITLE", comment: "")
	static let LICENSES_TITLE = NSLocalizedString("LICENSES_TITLE", comment: "")
	static func NOTIFICATION_TEMPLATE_BODY(_ p1: String, _ p2: String, _ p3: String) -> String { return NSLocalizedString("NOTIFICATION_TEMPLATE_BODY", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2).replacingOccurrences(of: "%3", with: p3) }
	static func NOTIFICATION_TEMPLATE_RANGE(_ p1: String, _ p2: String) -> String { return NSLocalizedString("NOTIFICATION_TEMPLATE_RANGE", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let NOTIFICATION_VALUE_STATUS_HIGH = NSLocalizedString("NOTIFICATION_VALUE_STATUS_HIGH", comment: "")
	static let NOTIFICATION_VALUE_STATUS_LOW = NSLocalizedString("NOTIFICATION_VALUE_STATUS_LOW", comment: "")
	static let NOTIFICATION_VALUE_TOD_AFTERNOON = NSLocalizedString("NOTIFICATION_VALUE_TOD_AFTERNOON", comment: "")
	static let NOTIFICATION_VALUE_TOD_EVENING = NSLocalizedString("NOTIFICATION_VALUE_TOD_EVENING", comment: "")
	static let NOTIFICATION_VALUE_TOD_MORNING = NSLocalizedString("NOTIFICATION_VALUE_TOD_MORNING", comment: "")
	static let NOTIFICATION_VALUE_TOD_NIGHT = NSLocalizedString("NOTIFICATION_VALUE_TOD_NIGHT", comment: "")
	static func PRICES_DAY_PRICE_SPAN(_ p1: String, _ p2: String) -> String { return NSLocalizedString("PRICES_DAY_PRICE_SPAN", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static func PRICES_HOUR_COST(_ p1: String) -> String { return NSLocalizedString("PRICES_HOUR_COST", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static func PRICES_HOUR_TIME(_ p1: String, _ p2: String) -> String { return NSLocalizedString("PRICES_HOUR_TIME", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let PRICES_REFRESH_CONTROL_MESSAGE = NSLocalizedString("PRICES_REFRESH_CONTROL_MESSAGE", comment: "")
	static let PRICES_REFRESH_FAILED_MESSAGE = NSLocalizedString("PRICES_REFRESH_FAILED_MESSAGE", comment: "")
	static let PRICES_TITLE = NSLocalizedString("PRICES_TITLE", comment: "")
	static let SETTINGS_TITLE = NSLocalizedString("SETTINGS_TITLE", comment: "")
	static let SETTINGS_ZONE_TITLE = NSLocalizedString("SETTINGS_ZONE_TITLE", comment: "")
	static let SETTINGS_ZONE_ZONE_TITLE = NSLocalizedString("SETTINGS_ZONE_ZONE_TITLE", comment: "")
	static let ZONE_DK1 = NSLocalizedString("ZONE_DK1", comment: "")
	static let ZONE_DK2 = NSLocalizedString("ZONE_DK2", comment: "")
	static let ZONE_SELECTION_CONFIRMATION_POSITIVE_BUTTON = NSLocalizedString("ZONE_SELECTION_CONFIRMATION_POSITIVE_BUTTON", comment: "")
	static let ZONE_SELECTION_DK1_ZIP_LIST = NSLocalizedString("ZONE_SELECTION_DK1_ZIP_LIST", comment: "")
	static let ZONE_SELECTION_DK2_ZIP_LIST = NSLocalizedString("ZONE_SELECTION_DK2_ZIP_LIST", comment: "")
	static let ZONE_SELECTION_TITLE = NSLocalizedString("ZONE_SELECTION_TITLE", comment: "")
}
