// swiftlint:disable all
import Foundation
struct Translations {
	static func SETUP_MESSAGE_TIME_IS(_ p1: String) -> String { return NSLocalizedString("SETUP_MESSAGE_TIME_IS", comment: "").replacingOccurrences(of: "%1", with: p1) }
	static let SETUP_TITLE_WELCOME = NSLocalizedString("SETUP_TITLE_WELCOME", comment: "")
}
