import Foundation
import UserNotifications
import Flogger

struct Notification: AutoCopy, Equatable {
    static let ID = "id"
    static let DATE = "date"
    static let formatter = DateFormatter.with(dateStyle: .none, timeStyle: .short)

    let id: String
    let enabled: Bool
    let fireOffset: UInt
    let dateOffset: UInt
    let durationOffset: UInt
    let lastDelivery: Date

    var action: String? {
        enabled ? Translations.NOTIFICATION_MESSAGE_ACTION_ENABLED(Notification.formatter.string(from: Date.now.startOfDay.date(byAdding: .second, value: Int(fireOffset)))) : Translations.NOTIFICATION_MESSAGE_ACTION_DISABLED
    }

    var description: String {
        Translations.NOTIFICATION_MESSAGE_DESCRIPTION(
            Notification.formatter.string(from: Date.now.startOfDay.date(byAdding: .second, value: Int(dateOffset))),
            Notification.formatter.string(from: Date.now.startOfDay.date(byAdding: .second, value: Int(dateOffset + durationOffset)))
        )
    }

    var fullDescription: String {
        Translations.NOTIFICATION_MESSAGE_FULL_DESCRIPTION(
            Notification.formatter.string(from: Date.now.startOfDay.date(byAdding: .second, value: Int(fireOffset))),
            Notification.formatter.string(from: Date.now.startOfDay.date(byAdding: .second, value: Int(dateOffset))),
            Notification.formatter.string(from: Date.now.startOfDay.date(byAdding: .second, value: Int(dateOffset + durationOffset)))
        )
    }

    init(id: String, enabled: Bool, fireOffset: UInt, dateOffset: UInt, durationOffset: UInt, lastDelivery: Date) {
        self.id = id
        self.enabled = enabled
        self.fireOffset = fireOffset
        self.dateOffset = dateOffset
        self.durationOffset = durationOffset
        self.lastDelivery = lastDelivery
    }

    func create(at date: Date, in network: Network, using price: EnergyPriceRepository, and charges: ChargesLookup) -> UNNotificationRequest? {
        let start = date.startOfDay.date(byAdding: .second, value: Int(dateOffset))
        let firingDate = date.startOfDay.date(byAdding: .second, value: Int(fireOffset))
        let period = DateInterval(start: start, duration: TimeInterval(durationOffset) - 1)

        guard
            let prices = try? price.data(for: network.zone, in: period),
            let model = prices.first,
            let priceSpan = Price.map(prices, at: model.timestamp, in: network, using: charges)?.priceSpan,
            firingDate > lastDelivery,
            firingDate >= Date.now.date(byAdding: .minute, value: -2)
        else {
            return nil
        }

        let numberFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)
        let dateFormatter = DateFormatter.with(dateStyle: .none, timeStyle: .short)

        let content = UNMutableNotificationContent()
        content.title = Translations.NOTIFICATION_MESSAGE_TITLE
        content.body = Translations.NOTIFICATION_MESSAGE_TEMPLATE_BODY(
            dateFormatter.string(from: period.start),
            dateFormatter.string(from: period.end + 1),
            numberFormatter.string(with: priceSpan.lowerBound),
            numberFormatter.string(with: priceSpan.upperBound)
        )
        content.userInfo = [
            Notification.DATE: firingDate.timeIntervalSince1970,
            Notification.ID: id
        ]

        Flog.info("Prepared notification \(id) in \(firingDate.timeIntervalSince(Date.now) / 3600) hours with message: \(content.body)")

        let seconds = firingDate.timeIntervalSince(Date.now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        return UNNotificationRequest(identifier: "\(id)-\(firingDate.timeIntervalSince1970)", content: content, trigger: trigger)
    }
}
