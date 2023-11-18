import Foundation

extension TimeInterval {
    static var fiveMinutes: TimeInterval = 300
    static var oneHour: TimeInterval = 3600
}

extension Array where Element == TimeInterval {
    func span() -> ClosedRange<TimeInterval> {
        reduce(Double.infinity, { $0 > $1 ? $1 : $0 })...reduce(-Double.infinity, { $0 < $1 ? $1 : $0 })
    }
}
