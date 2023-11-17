import Foundation

extension Date {
    func date(byAdding component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self)!
    }

    func date(bySetting component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(bySetting: component, value: value, of: self)!
    }

    var startOfDay: Date {
        Calendar.current.nextDate(after: self.date(byAdding: .day, value: -1), matching: DateComponents(hour: 0), matchingPolicy: .nextTime)!
    }

    var endOfDay: Date {
        Calendar.current.nextDate(after: self, matching: DateComponents(hour: 0), matchingPolicy: .nextTime)!
    }
}
