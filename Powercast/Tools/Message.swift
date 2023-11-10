import Foundation

struct Message {
    let body: String
    let fireDate: Date

    static func of(_ evaluations: [Evaluation], using charges: ChargesRepository, at date: Date = .now) -> [Message] {
        let startOfDay = date.startOfDay
        let tomorrow = date.endOfDay
        let boundaries = [
            Boundary(timeOfDay: .night, date: startOfDay, start: 0, end: 6, fire: -3),
            Boundary(timeOfDay: .morning, date: startOfDay, start: 6, end: 12, fire: -3),
            Boundary(timeOfDay: .afternoon, date: startOfDay, start: 12, end: 18, fire: 9),
            Boundary(timeOfDay: .evening, date: startOfDay, start: 18, end: 24, fire: 13),
            Boundary(timeOfDay: .night, date: tomorrow, start: 0, end: 6, fire: -3),
            Boundary(timeOfDay: .morning, date: tomorrow, start: 6, end: 12, fire: -3),
            Boundary(timeOfDay: .afternoon, date: tomorrow, start: 12, end: 18, fire: 9),
            Boundary(timeOfDay: .evening, date: tomorrow, start: 18, end: 24, fire: 13)
        ]
        var messages: [Message] = []
        for boundary in boundaries where boundary.period.end > date {
            if let message = Message(for: boundary, with: evaluations, using: charges) {
                messages.append(message)
            }
        }
        return messages
    }

    private init?(for boundary: Boundary, with evaluations: [Evaluation], using charges: ChargesRepository) {
        let evaluations = evaluations.filter { boundary.period.contains($0.model.timestamp) }
        guard evaluations.count > 0 else {
            return nil
        }

        let time: String
        switch boundary.timeOfDay {
        case .night:
            time = Translations.NOTIFICATION_VALUE_TOD_NIGHT
        case .morning:
            time = Translations.NOTIFICATION_VALUE_TOD_MORNING
        case .afternoon:
            time = Translations.NOTIFICATION_VALUE_TOD_AFTERNOON
        case .evening:
            time = Translations.NOTIFICATION_VALUE_TOD_EVENING
        }

        let status: String
        if evaluations.filter({ $0.belowAverage }).count * 2 >= evaluations.count {
            status = Translations.NOTIFICATION_VALUE_STATUS_LOW
        } else {
            status = Translations.NOTIFICATION_VALUE_STATUS_HIGH
        }

        var high = evaluations.first!
        var low = evaluations.first!
        for item in evaluations {
            if low.model.price > item.model.price {
                low = item
            }
            if high.model.price < item.model.price {
                high = item
            }
        }

        let lowPrice = NumberFormatter.with(style: .decimal, fractionDigits: 0).string(from: low.charges.format(low.model.price, at: low.model.timestamp) as NSNumber)!
        let highPrice = NumberFormatter.with(style: .decimal, fractionDigits: 0).string(from: high.charges.format(high.model.price, at: high.model.timestamp) as NSNumber)!
        let range = Translations.NOTIFICATION_TEMPLATE_RANGE("\(lowPrice)", "\(highPrice)")

        self.body = Translations.NOTIFICATION_TEMPLATE_BODY("\(time)", "\(status)", "\(range)")
        self.fireDate = boundary.firingDate
    }

    private enum TimeOfDay {
        case night, morning, afternoon, evening
    }

    private struct Boundary {
        let timeOfDay: TimeOfDay
        let firingDate: Date
        let period: DateInterval

        init(timeOfDay: TimeOfDay, date: Date, start: Int, end: Int, fire: Int) {
            self.timeOfDay = timeOfDay
            self.firingDate = date.startOfDay.date(byAdding: .hour, value: fire)
            self.period = DateInterval(start: date.startOfDay.date(byAdding: .hour, value: start), end: date.startOfDay.date(byAdding: .hour, value: end))
        }
    }
}
