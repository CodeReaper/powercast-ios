import Foundation

extension DateFormatter {
    static func with(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
    }

    static func with(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
}

extension NumberFormatter {
    static func with(style: NumberFormatter.Style, fractionDigits: Int? = nil) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        if let fractionDigits = fractionDigits {
            formatter.minimumFractionDigits = fractionDigits
            formatter.maximumFractionDigits = fractionDigits
        }
        return formatter
    }
}
