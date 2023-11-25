// FIXME: delete
//import Foundation
//
//struct Message {
//    let kind: Kind
//    let body: String
//    let fireDate: Date
//
//    static func of(_ evaluations: [Evaluation], using charges: ChargesRepository, at date: Date = .now) -> [Message] {
//        let startOfDay = date.startOfDay
//        let tomorrow = date.endOfDay
//        let boundaries = [
//            Boundary(type: .night, date: startOfDay, start: 0, end: 6, fire: -3),
//            Boundary(type: .morning, date: startOfDay, start: 6, end: 12, fire: -3),
//            Boundary(type: .afternoon, date: startOfDay, start: 12, end: 18, fire: 9),
//            Boundary(type: .evening, date: startOfDay, start: 18, end: 24, fire: 13),
//            Boundary(type: .night, date: tomorrow, start: 0, end: 6, fire: -3),
//            Boundary(type: .morning, date: tomorrow, start: 6, end: 12, fire: -3),
//            Boundary(type: .afternoon, date: tomorrow, start: 12, end: 18, fire: 9),
//            Boundary(type: .evening, date: tomorrow, start: 18, end: 24, fire: 13)
//        ]
//        var messages: [Message] = []
//        for boundary in boundaries where boundary.period.end > date {
//            if let message = Message(for: boundary, with: evaluations, using: charges) {
//                messages.append(message)
//            }
//        }
//        if let message = freeMessage(with: evaluations, at: date) {
//            messages.append(message)
//        }
//        return messages
//    }
//
//    init(kind: Kind, body: String, fireDate: Date) {
//        self.kind = kind
//        self.body = body
//        self.fireDate = fireDate
//    }
//
//    private init?(for boundary: Boundary, with evaluations: [Evaluation], using charges: ChargesRepository) {
//        let evaluations = evaluations.filter { boundary.period.contains($0.model.timestamp) }
//        guard evaluations.count > 0 else {
//            return nil
//        }
//
//        let time: String
//        switch boundary.type {
//        case .night:
//            time = Translations.NOTIFICATION_VALUE_TOD_NIGHT
//        case .morning:
//            time = Translations.NOTIFICATION_VALUE_TOD_MORNING
//        case .afternoon:
//            time = Translations.NOTIFICATION_VALUE_TOD_AFTERNOON
//        case .evening:
//            time = Translations.NOTIFICATION_VALUE_TOD_EVENING
//        case .free:
//            return nil
//        }
//
//        let status: String
//        if evaluations.filter({ $0.belowAverage }).count * 2 >= evaluations.count {
//            status = Translations.NOTIFICATION_VALUE_STATUS_LOW
//        } else {
//            status = Translations.NOTIFICATION_VALUE_STATUS_HIGH
//        }
//
//        var high = evaluations.first!
//        var low = evaluations.first!
//        for item in evaluations {
//            if low.model.price > item.model.price {
//                low = item
//            }
//            if high.model.price < item.model.price {
//                high = item
//            }
//        }
//
//        let lowPrice = NumberFormatter.with(style: .decimal, fractionDigits: 0).string(with: low.charges.format(low.model.price, at: low.model.timestamp))
//        let highPrice = NumberFormatter.with(style: .decimal, fractionDigits: 0).string(with: high.charges.format(high.model.price, at: high.model.timestamp))
//        let range = Translations.NOTIFICATION_TEMPLATE_RANGE("\(lowPrice)", "\(highPrice)")
//
//        self.body = Translations.NOTIFICATION_TEMPLATE_BODY("\(time)", "\(status)", "\(range)")
//        self.fireDate = boundary.firingDate
//        self.kind = boundary.type
//    }
//
//    private static func freeMessage(with evaluations: [Evaluation], at date: Date) -> Message? {
//        let dateOffset = date.date(byAdding: .day, value: 1)
//        let evaluations = evaluations.filter { $0.model.timestamp > date && $0.model.timestamp < dateOffset && $0.negativelyPriced }.sorted(by: { $0.model.timestamp < $1.model.timestamp })
//        guard evaluations.count > 0 else {
//            return nil
//        }
//
//        var high = evaluations.first!
//        var low = evaluations.first!
//        for item in evaluations {
//            if low.fees > item.fees {
//                low = item
//            }
//            if high.fees < item.fees {
//                high = item
//            }
//        }
//
//        let lowFees = NumberFormatter.with(style: .decimal, fractionDigits: 0).string(with: low.charges.convert(low.fees, at: low.model.timestamp))
//        let highFees = NumberFormatter.with(style: .decimal, fractionDigits: 0).string(with: high.charges.convert(high.fees, at: high.model.timestamp))
//        let formatter = DateFormatter.with(format: "HH")
//        let hours = evaluations.map { formatter.string(from: $0.model.timestamp) }.joined(separator: ", ")
//
//        return Message(kind: .free, body: Translations.NOTIFICATION_TEMPLATE_FREE_BODY(hours, lowFees, highFees), fireDate: evaluations.first?.model.timestamp ?? date)
//    }
//
//    enum Kind: Int, CaseIterable {
//        case night = 0
//        case morning = 1
//        case afternoon = 2
//        case evening = 3
//        case free = 4
//    }
//
//    private struct Boundary {
//        let type: Kind
//        let firingDate: Date
//        let period: DateInterval
//
//        init(type: Kind, date: Date, start: Int, end: Int, fire: Int) {
//            self.type = type
//            self.firingDate = date.startOfDay.date(byAdding: .hour, value: fire)
//            self.period = DateInterval(start: date.startOfDay.date(byAdding: .hour, value: start), end: date.startOfDay.date(byAdding: .hour, value: end))
//        }
//    }
//}
