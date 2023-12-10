import Foundation

// swiftlint:disable force_cast

extension Bundle {
    static var shortVersion: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    static var version: String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    static var commit: String = Bundle.main.infoDictionary!["COMMIT"] as! String
}
