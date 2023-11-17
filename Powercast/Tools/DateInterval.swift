import Foundation

extension DateInterval {
    func combine(with interval: DateInterval) -> DateInterval {
        DateInterval(start: min(start, interval.start), end: max(end, interval.end))
    }

    func dates() -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: start)
        guard var date = calendar.date(from: components) else { return [] }

        var dates: [Date] = []
        repeat {
            if end >= start {
                dates.append(date)
            }
            guard let newDate = calendar.date(byAdding: .day, value: 1, to: date) else { return dates }
            date = newDate
        } while date <= end

        return dates
    }
}
