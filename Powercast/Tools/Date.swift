import Foundation

extension Date {
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

    static var year2000: Date {
        return Date(timeIntervalSince1970: 946684800)
    }
}
