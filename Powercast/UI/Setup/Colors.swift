import UIKit

extension UIColor {
    private static let notHexadecimalSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF").inverted

    static func from(hex: String, alpha: Double = 1.0) -> UIColor {
        let string = hex.trimmingCharacters(in: notHexadecimalSet).uppercased()
        if string.count != 6 {
            fatalError("Supplied '\(hex)' as an incorrect hex value for a color.")
        }

        var rgbValue: UInt64 = 0; Scanner(string: string).scanHexInt64(&rgbValue)
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0, blue: CGFloat(rgbValue & 0x0000FF) / 255.0, alpha: alpha)
    }
}
