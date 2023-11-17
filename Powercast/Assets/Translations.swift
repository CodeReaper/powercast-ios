// swiftlint:disable all
import Foundation
struct Translations {
	static let DASHBOARD_CO2_LABEL = NSLocalizedString("DASHBOARD_CO2_LABEL", comment: "")
	static func DASHBOARD_CO2_SPAN(_ p1: String, _ p2: String) -> String { return NSLocalizedString("DASHBOARD_CO2_SPAN", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let DASHBOARD_CO2_UNIT = NSLocalizedString("DASHBOARD_CO2_UNIT", comment: "")
	static let DASHBOARD_COST_UNIT = NSLocalizedString("DASHBOARD_COST_UNIT", comment: "")
	static func DASHBOARD_DAY_PRICE_SPAN(_ p1: String, _ p2: String) -> String { return NSLocalizedString("DASHBOARD_DAY_PRICE_SPAN", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static func DASHBOARD_HOUR_TIME(_ p1: String, _ p2: String) -> String { return NSLocalizedString("DASHBOARD_HOUR_TIME", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let DASHBOARD_REFRESH_CONTROL_MESSAGE = NSLocalizedString("DASHBOARD_REFRESH_CONTROL_MESSAGE", comment: "")
	static let DASHBOARD_REFRESH_FAILED_MESSAGE = NSLocalizedString("DASHBOARD_REFRESH_FAILED_MESSAGE", comment: "")
	static let DASHBOARD_TITLE = NSLocalizedString("DASHBOARD_TITLE", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_MESSAGE = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_MESSAGE", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_TITLE = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_TITLE", comment: "")
	static let DATA_LOADING_TITLE = NSLocalizedString("DATA_LOADING_TITLE", comment: "")
	static let LICENSES_ASSETS_TITLE = NSLocalizedString("LICENSES_ASSETS_TITLE", comment: "")
	static let LICENSES_PACKAGES_TITLE = NSLocalizedString("LICENSES_PACKAGES_TITLE", comment: "")
	static let LICENSES_TITLE = NSLocalizedString("LICENSES_TITLE", comment: "")
	static let NETWORK_DETAILS_HOURS_LABEL = NSLocalizedString("NETWORK_DETAILS_HOURS_LABEL", comment: "")
	static let NETWORK_DETAILS_PRICE_LABEL = NSLocalizedString("NETWORK_DETAILS_PRICE_LABEL", comment: "")
	static let NETWORK_DETAILS_TITLE = NSLocalizedString("NETWORK_DETAILS_TITLE", comment: "")
	static let NETWORK_DETAILS_UNSPECIFICED_END = NSLocalizedString("NETWORK_DETAILS_UNSPECIFICED_END", comment: "")
	static let NETWORK_SELECTION_DK1_ZIP_LIST = NSLocalizedString("NETWORK_SELECTION_DK1_ZIP_LIST", comment: "")
	static let NETWORK_SELECTION_DK2_ZIP_LIST = NSLocalizedString("NETWORK_SELECTION_DK2_ZIP_LIST", comment: "")
	static let NETWORK_SELECTION_EMPTY_BUTTON = NSLocalizedString("NETWORK_SELECTION_EMPTY_BUTTON", comment: "")
	static let NETWORK_SELECTION_EMPTY_TITLE = NSLocalizedString("NETWORK_SELECTION_EMPTY_TITLE", comment: "")
	static let NETWORK_SELECTION_HELP_BUTTON_NEGATIVE = NSLocalizedString("NETWORK_SELECTION_HELP_BUTTON_NEGATIVE", comment: "")
	static let NETWORK_SELECTION_HELP_BUTTON_POSITIVE = NSLocalizedString("NETWORK_SELECTION_HELP_BUTTON_POSITIVE", comment: "")
	static let NETWORK_SELECTION_HELP_MESSAGE = NSLocalizedString("NETWORK_SELECTION_HELP_MESSAGE", comment: "")
	static let NETWORK_SELECTION_HELP_TITLE = NSLocalizedString("NETWORK_SELECTION_HELP_TITLE", comment: "")
	static let NETWORK_SELECTION_TITLE = NSLocalizedString("NETWORK_SELECTION_TITLE", comment: "")
	static func NOTIFICATION_TEMPLATE_BODY(_ p1: String, _ p2: String, _ p3: String) -> String { return NSLocalizedString("NOTIFICATION_TEMPLATE_BODY", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2).replacingOccurrences(of: "%3", with: p3) }
	static func NOTIFICATION_TEMPLATE_FREE_BODY(_ p1: String, _ p2: String, _ p3: String) -> String { return NSLocalizedString("NOTIFICATION_TEMPLATE_FREE_BODY", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2).replacingOccurrences(of: "%3", with: p3) }
	static func NOTIFICATION_TEMPLATE_RANGE(_ p1: String, _ p2: String) -> String { return NSLocalizedString("NOTIFICATION_TEMPLATE_RANGE", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let NOTIFICATION_TEMPLATE_SEPARATOR = NSLocalizedString("NOTIFICATION_TEMPLATE_SEPARATOR", comment: "")
	static let NOTIFICATION_TITLE = NSLocalizedString("NOTIFICATION_TITLE", comment: "")
	static let NOTIFICATION_VALUE_STATUS_HIGH = NSLocalizedString("NOTIFICATION_VALUE_STATUS_HIGH", comment: "")
	static let NOTIFICATION_VALUE_STATUS_LOW = NSLocalizedString("NOTIFICATION_VALUE_STATUS_LOW", comment: "")
	static let NOTIFICATION_VALUE_TOD_AFTERNOON = NSLocalizedString("NOTIFICATION_VALUE_TOD_AFTERNOON", comment: "")
	static let NOTIFICATION_VALUE_TOD_EVENING = NSLocalizedString("NOTIFICATION_VALUE_TOD_EVENING", comment: "")
	static let NOTIFICATION_VALUE_TOD_MORNING = NSLocalizedString("NOTIFICATION_VALUE_TOD_MORNING", comment: "")
	static let NOTIFICATION_VALUE_TOD_NIGHT = NSLocalizedString("NOTIFICATION_VALUE_TOD_NIGHT", comment: "")
	static let SETTINGS_NETWORK_TITLE = NSLocalizedString("SETTINGS_NETWORK_TITLE", comment: "")
	static let SETTINGS_NOTIFICATIONS_ITEM_AFTERNOON = NSLocalizedString("SETTINGS_NOTIFICATIONS_ITEM_AFTERNOON", comment: "")
	static let SETTINGS_NOTIFICATIONS_ITEM_EVENING = NSLocalizedString("SETTINGS_NOTIFICATIONS_ITEM_EVENING", comment: "")
	static let SETTINGS_NOTIFICATIONS_ITEM_FREE = NSLocalizedString("SETTINGS_NOTIFICATIONS_ITEM_FREE", comment: "")
	static let SETTINGS_NOTIFICATIONS_ITEM_MORNING = NSLocalizedString("SETTINGS_NOTIFICATIONS_ITEM_MORNING", comment: "")
	static let SETTINGS_NOTIFICATIONS_ITEM_NIGHT = NSLocalizedString("SETTINGS_NOTIFICATIONS_ITEM_NIGHT", comment: "")
	static let SETTINGS_NOTIFICATIONS_TITLE = NSLocalizedString("SETTINGS_NOTIFICATIONS_TITLE", comment: "")
	static let SETTINGS_STATE_DISABLED = NSLocalizedString("SETTINGS_STATE_DISABLED", comment: "")
	static let SETTINGS_STATE_ENABLED = NSLocalizedString("SETTINGS_STATE_ENABLED", comment: "")
	static let SETTINGS_STATE_UNKNOWN = NSLocalizedString("SETTINGS_STATE_UNKNOWN", comment: "")
	static let SETTINGS_SYSTEM_BACKGROUND_REFRESH = NSLocalizedString("SETTINGS_SYSTEM_BACKGROUND_REFRESH", comment: "")
	static let SETTINGS_SYSTEM_NOTIFICATIONS = NSLocalizedString("SETTINGS_SYSTEM_NOTIFICATIONS", comment: "")
	static let SETTINGS_SYSTEM_TITLE = NSLocalizedString("SETTINGS_SYSTEM_TITLE", comment: "")
	static let SETTINGS_TITLE = NSLocalizedString("SETTINGS_TITLE", comment: "")
	static let ZONE_DK1 = NSLocalizedString("ZONE_DK1", comment: "")
	static let ZONE_DK2 = NSLocalizedString("ZONE_DK2", comment: "")
}
