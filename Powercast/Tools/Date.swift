import Foundation

extension Date {
    func date(byAdding component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self)!
    }

    func date(bySetting component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(bySetting: component, value: value, of: self)!
    }

    func dates(until end: Date) -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        guard var date = calendar.date(from: components) else { return [] }

        var dates: [Date] = []
        repeat {
            if date >= self {
                dates.append(date)
            }
            guard let newDate = calendar.date(byAdding: .day, value: 1, to: date) else { return dates }
            date = newDate
        } while date <= end

        return dates
    }

    var startOfDay: Date {
        Calendar.current.nextDate(after: self.date(byAdding: .day, value: -1), matching: DateComponents(hour: 0), matchingPolicy: .nextTime)!
    }

    var endOfDay: Date {
        Calendar.current.nextDate(after: self, matching: DateComponents(hour: 0), matchingPolicy: .nextTime)!
    }

    static var year2000: Date {
        return Date(timeIntervalSince1970: 946684800)
    }
}
