import Foundation
import UserNotifications
import Flogger

struct Notification: AutoCopy, Equatable {
    static let ID = "id"
    static let DATE = "date"

    let id: String
    let enabled: Bool
    let fireOffset: UInt
    let dateOffset: UInt
    let durationOffset: UInt
    let lastDelivery: Date

    // FIXME: translations
    var title: String {
        "Prices between \(dateOffset) and \(durationOffset)"
    }

    var subtitle: String? {
        if enabled {
            return "Will trigger at \(fireOffset / 3600)"
        } else {
            return "disabled"
        }
    }

    var description: String {
        "Display prices between \(dateOffset) and \(durationOffset) at \(fireOffset / 3600)\(enabled ? "" : ", but currently disabled")"
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
        let start = date.startOfDay.date(byAdding: .hour, value: Int(dateOffset))
        let firingDate = start.date(byAdding: .hour, value: -Int(fireOffset))
        let period = DateInterval(start: start, end: start.date(byAdding: .hour, value: Int(durationOffset) - 1))

        guard
            let prices = try? price.data(for: network.zone, in: period),
            let model = prices.first,
            let priceSpan = Price.map(prices, at: model.timestamp, in: network, using: charges)?.priceSpan
        else {
            return nil
        }

        let numberFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)
        let dateFormatter = DateFormatter.with(dateStyle: .none, timeStyle: .short)

        // FIXME: translations
        let content = UNMutableNotificationContent()
        content.title = Translations.NOTIFICATION_TITLE
        content.body = "Between \(dateFormatter.string(from: period.start)) and \(dateFormatter.string(from: period.end)) the prices range from \(numberFormatter.string(with: priceSpan.lowerBound)) to \(numberFormatter.string(with: priceSpan.upperBound)) øre/kWh"
        content.userInfo = [
            Notification.DATE: firingDate.timeIntervalSince1970,
            Notification.ID: id
        ]

        Flog.info("Prepared this message: \(content.body) in \(firingDate.timeIntervalSince(Date.now) / 3600) hours.")

        let seconds = firingDate.timeIntervalSince(Date.now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    }
}
