import Foundation

extension NumberFormatter {
    func string(with value: Double) -> String {
        return string(from: value as NSNumber)!
    }
    func string(with value: Int) -> String {
        return string(from: value as NSNumber)!
    }
}
