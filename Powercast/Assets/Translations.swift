// swiftlint:disable all
import Foundation
struct Translations {
	static func BUILD_LABEL(_ p1: String) -> String { return NSLocalizedString("BUILD_LABEL", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static func COMMIT_LABEL(_ p1: String) -> String { return NSLocalizedString("COMMIT_LABEL", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static let DASHBOARD_CO2_LABEL = NSLocalizedString("DASHBOARD_CO2_LABEL", comment: "")
	static func DASHBOARD_CO2_SPAN(_ p1: String, _ p2: String) -> String { return NSLocalizedString("DASHBOARD_CO2_SPAN", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let DASHBOARD_CO2_UNIT = NSLocalizedString("DASHBOARD_CO2_UNIT", comment: "")
	static let DASHBOARD_COST_UNIT = NSLocalizedString("DASHBOARD_COST_UNIT", comment: "")
	static func DASHBOARD_DAY_PRICE_SPAN(_ p1: String, _ p2: String) -> String { return NSLocalizedString("DASHBOARD_DAY_PRICE_SPAN", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static func DASHBOARD_HOUR_TIME(_ p1: String, _ p2: String) -> String { return NSLocalizedString("DASHBOARD_HOUR_TIME", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let DASHBOARD_REFRESH_CONTROL_MESSAGE = NSLocalizedString("DASHBOARD_REFRESH_CONTROL_MESSAGE", comment: "")
	static let DASHBOARD_REFRESH_FAILED_MESSAGE = NSLocalizedString("DASHBOARD_REFRESH_FAILED_MESSAGE", comment: "")
	static let DASHBOARD_TITLE = NSLocalizedString("DASHBOARD_TITLE", comment: "")
	static func DATA_DETAILS_EMISSION_CO2_SPAN(_ p1: String, _ p2: String) -> String { return NSLocalizedString("DATA_DETAILS_EMISSION_CO2_SPAN", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static let DATA_DETAILS_EMISSION_CO2_UNIT = NSLocalizedString("DATA_DETAILS_EMISSION_CO2_UNIT", comment: "")
	static let DATA_DETAILS_FIXED_FEES_LABEL = NSLocalizedString("DATA_DETAILS_FIXED_FEES_LABEL", comment: "")
	static func DATA_DETAILS_PERCENTAGE(_ p1: String) -> String { return NSLocalizedString("DATA_DETAILS_PERCENTAGE", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static let DATA_DETAILS_PRICE_LABEL = NSLocalizedString("DATA_DETAILS_PRICE_LABEL", comment: "")
	static let DATA_DETAILS_PRICE_UNIT = NSLocalizedString("DATA_DETAILS_PRICE_UNIT", comment: "")
	static let DATA_DETAILS_RAW_PRICE_LABEL = NSLocalizedString("DATA_DETAILS_RAW_PRICE_LABEL", comment: "")
	static let DATA_DETAILS_TITLE_EMISSION = NSLocalizedString("DATA_DETAILS_TITLE_EMISSION", comment: "")
	static let DATA_DETAILS_TITLE_PRICE = NSLocalizedString("DATA_DETAILS_TITLE_PRICE", comment: "")
	static let DATA_DETAILS_VARIABLE_FEES_LABEL = NSLocalizedString("DATA_DETAILS_VARIABLE_FEES_LABEL", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_MESSAGE = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_MESSAGE", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_NEGATIVE_BUTTON", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_POSITIVE_BUTTON", comment: "")
	static let DATA_LOADING_REFRESH_FAILED_TITLE = NSLocalizedString("DATA_LOADING_REFRESH_FAILED_TITLE", comment: "")
	static let DATA_LOADING_TITLE = NSLocalizedString("DATA_LOADING_TITLE", comment: "")
	static let GRID_DETAILS_CHARGE_LABEL = NSLocalizedString("GRID_DETAILS_CHARGE_LABEL", comment: "")
	static let GRID_DETAILS_SYSTEM_LABEL = NSLocalizedString("GRID_DETAILS_SYSTEM_LABEL", comment: "")
	static let GRID_DETAILS_TITLE = NSLocalizedString("GRID_DETAILS_TITLE", comment: "")
	static let GRID_DETAILS_TRANSMISSION_LABEL = NSLocalizedString("GRID_DETAILS_TRANSMISSION_LABEL", comment: "")
	static let GRID_DETAILS_UNIT = NSLocalizedString("GRID_DETAILS_UNIT", comment: "")
	static let LICENSES_ASSETS_TITLE = NSLocalizedString("LICENSES_ASSETS_TITLE", comment: "")
	static let LICENSES_PACKAGES_TITLE = NSLocalizedString("LICENSES_PACKAGES_TITLE", comment: "")
	static let LICENSES_TITLE = NSLocalizedString("LICENSES_TITLE", comment: "")
	static let NETWORK_DETAILS_PRICE_LABEL = NSLocalizedString("NETWORK_DETAILS_PRICE_LABEL", comment: "")
	static let NETWORK_DETAILS_TITLE = NSLocalizedString("NETWORK_DETAILS_TITLE", comment: "")
	static func NETWORK_DETAILS_TITLE_TEMPLATE(_ p1: String) -> String { return NSLocalizedString("NETWORK_DETAILS_TITLE_TEMPLATE", comment: "").replacingOccurrences(of: "%1", with: p1) }
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
	static let NOTIFICATION_DELETE_BUTTON_DESTRUCTIVE = NSLocalizedString("NOTIFICATION_DELETE_BUTTON_DESTRUCTIVE", comment: "")
	static let NOTIFICATION_DELETE_BUTTON_NEGATIVE = NSLocalizedString("NOTIFICATION_DELETE_BUTTON_NEGATIVE", comment: "")
	static let NOTIFICATION_DELETE_MESSAGE = NSLocalizedString("NOTIFICATION_DELETE_MESSAGE", comment: "")
	static let NOTIFICATION_DELETE_TITLE = NSLocalizedString("NOTIFICATION_DELETE_TITLE", comment: "")
	static let NOTIFICATION_DESCRIPTION_TITLE = NSLocalizedString("NOTIFICATION_DESCRIPTION_TITLE", comment: "")
	static let NOTIFICATION_ENABLE_LABEL = NSLocalizedString("NOTIFICATION_ENABLE_LABEL", comment: "")
	static let NOTIFICATION_MESSAGE_ACTION_DISABLED = NSLocalizedString("NOTIFICATION_MESSAGE_ACTION_DISABLED", comment: "")
	static func NOTIFICATION_MESSAGE_ACTION_ENABLED(_ p1: String) -> String { return NSLocalizedString("NOTIFICATION_MESSAGE_ACTION_ENABLED", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static func NOTIFICATION_MESSAGE_DESCRIPTION(_ p1: String, _ p2: String) -> String { return NSLocalizedString("NOTIFICATION_MESSAGE_DESCRIPTION", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2) }
	static func NOTIFICATION_MESSAGE_FULL_DESCRIPTION(_ p1: String, _ p2: String, _ p3: String) -> String { return NSLocalizedString("NOTIFICATION_MESSAGE_FULL_DESCRIPTION", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2).replacingOccurrences(of: "%3", with: p3) }
	static func NOTIFICATION_MESSAGE_TEMPLATE_BODY(_ p1: String, _ p2: String, _ p3: String, _ p4: String) -> String { return NSLocalizedString("NOTIFICATION_MESSAGE_TEMPLATE_BODY", comment: "").replacingOccurrences(of: "%1", with: p1).replacingOccurrences(of: "%2", with: p2).replacingOccurrences(of: "%3", with: p3).replacingOccurrences(of: "%4", with: p4) }
	static let NOTIFICATION_MESSAGE_TITLE = NSLocalizedString("NOTIFICATION_MESSAGE_TITLE", comment: "")
	static let NOTIFICATION_PERIOD_DURATION_LABEL = NSLocalizedString("NOTIFICATION_PERIOD_DURATION_LABEL", comment: "")
	static let NOTIFICATION_PERIOD_START_LABEL = NSLocalizedString("NOTIFICATION_PERIOD_START_LABEL", comment: "")
	static let NOTIFICATION_PERIOD_TITLE = NSLocalizedString("NOTIFICATION_PERIOD_TITLE", comment: "")
	static let NOTIFICATION_TITLE = NSLocalizedString("NOTIFICATION_TITLE", comment: "")
	static let NOTIFICATION_TRIGGER_LABEL = NSLocalizedString("NOTIFICATION_TRIGGER_LABEL", comment: "")
	static let NOTIFICATION_TRIGGER_TITLE = NSLocalizedString("NOTIFICATION_TRIGGER_TITLE", comment: "")
	static let PRICE_ARCHIVE_FAILURE_MESSAGE = NSLocalizedString("PRICE_ARCHIVE_FAILURE_MESSAGE", comment: "")
	static let PRICE_ARCHIVE_TITLE = NSLocalizedString("PRICE_ARCHIVE_TITLE", comment: "")
	static let SETTINGS_NETWORK_TITLE = NSLocalizedString("SETTINGS_NETWORK_TITLE", comment: "")
	static let SETTINGS_NOTIFICATIONS_ADD_BUTTON = NSLocalizedString("SETTINGS_NOTIFICATIONS_ADD_BUTTON", comment: "")
	static let SETTINGS_NOTIFICATIONS_SYSTEM_DISABLED = NSLocalizedString("SETTINGS_NOTIFICATIONS_SYSTEM_DISABLED", comment: "")
	static let SETTINGS_NOTIFICATIONS_TITLE = NSLocalizedString("SETTINGS_NOTIFICATIONS_TITLE", comment: "")
	static let SETTINGS_STATE_DISABLED = NSLocalizedString("SETTINGS_STATE_DISABLED", comment: "")
	static let SETTINGS_STATE_ENABLED = NSLocalizedString("SETTINGS_STATE_ENABLED", comment: "")
	static let SETTINGS_STATE_UNKNOWN = NSLocalizedString("SETTINGS_STATE_UNKNOWN", comment: "")
	static let SETTINGS_SYSTEM_BACKGROUND_REFRESH = NSLocalizedString("SETTINGS_SYSTEM_BACKGROUND_REFRESH", comment: "")
	static let SETTINGS_SYSTEM_NOTIFICATIONS = NSLocalizedString("SETTINGS_SYSTEM_NOTIFICATIONS", comment: "")
	static let SETTINGS_SYSTEM_TITLE = NSLocalizedString("SETTINGS_SYSTEM_TITLE", comment: "")
	static let SETTINGS_TITLE = NSLocalizedString("SETTINGS_TITLE", comment: "")
	static let UPGRADE_IS_REQUIRED = NSLocalizedString("UPGRADE_IS_REQUIRED", comment: "")
	static func VERSION_LABEL(_ p1: String) -> String { return NSLocalizedString("VERSION_LABEL", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static let ZONE_DK1 = NSLocalizedString("ZONE_DK1", comment: "")
	static let ZONE_DK2 = NSLocalizedString("ZONE_DK2", comment: "")
}
