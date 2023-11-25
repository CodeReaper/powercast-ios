import Foundation
import UserNotifications
import Flogger

class NotificationRepository {
    struct Item {
        let id = "fixme-id"
        let firingDate: Date
        let period: DateInterval
        init(date: Date, fireOffset: UInt, dateOffset: UInt, durationOffset: UInt) {
            precondition(fireOffset < 12)
            precondition(dateOffset + durationOffset <= 24)
            precondition(durationOffset > 0)
            let start = date.startOfDay.date(byAdding: .hour, value: Int(dateOffset))
            self.firingDate = start.date(byAdding: .hour, value: -Int(fireOffset))
            self.period = DateInterval(start: start, end: start.date(byAdding: .hour, value: Int(durationOffset) - 1))
        }
    }

    private let delegate: Delegate
    private let charges: ChargesRepository
    private let prices: EnergyPriceRepository
    private let state: StateRepository

    init(charges: ChargesRepository, prices: EnergyPriceRepository, state: StateRepository) {
        self.delegate = Delegate(state: state)
        self.charges = charges
        self.prices = prices
        self.state = state
    }

    func register() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, error in
            if let error = error {
                Flog.error(error.localizedDescription)
            }
        }
    }

    func schedule() async {
        let network = state.network
        guard network.id != 0 else {
            Flog.info("Network could be resolved")
            return
        }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await UNUserNotificationCenter.current().deliveredNotifications().forEach { notification in
            delegate.mark(shown: notification)
        }

        let items = [
            Item(date: .now, fireOffset: 3, dateOffset: 0, durationOffset: 6),
            Item(date: .now, fireOffset: 9, dateOffset: 6, durationOffset: 6),
            Item(date: .now, fireOffset: 3, dateOffset: 12, durationOffset: 6),
            Item(date: .now, fireOffset: 5, dateOffset: 18, durationOffset: 6),
            Item(date: .now.endOfDay, fireOffset: 3, dateOffset: 0, durationOffset: 6),
            Item(date: .now.endOfDay, fireOffset: 9, dateOffset: 6, durationOffset: 6),
            Item(date: .now.endOfDay, fireOffset: 3, dateOffset: 12, durationOffset: 6),
            Item(date: .now.endOfDay, fireOffset: 5, dateOffset: 18, durationOffset: 6)
        ]

        let numberFormatter = NumberFormatter.with(style: .decimal, fractionDigits: 0)
        let dateFormatter = DateFormatter.with(dateStyle: .none, timeStyle: .short)

        for item in items {
            guard
                let prices = try? self.prices.data(for: network.zone, in: item.period),
                let price = prices.first,
                let priceSpan = Price.map(prices, at: price.timestamp, in: network, using: charges)?.priceSpan
            else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = Translations.NOTIFICATION_TITLE
            content.body = "Between \(dateFormatter.string(from: item.period.start)) and \(dateFormatter.string(from: item.period.end)) the prices range from \(numberFormatter.string(with: priceSpan.lowerBound)) to \(numberFormatter.string(with: priceSpan.upperBound)) øre/kWh"
            content.userInfo = [
                NotificationRepository.keyEpoch: item.firingDate.timeIntervalSince1970,
                NotificationRepository.keyKind: item.id
            ]

            Flog.info("Prepared this message: \(content.body) in \(item.firingDate.timeIntervalSince(Date.now) / 3600) hours.")

            let seconds = item.firingDate.timeIntervalSince(Date.now)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                Flog.error(error.localizedDescription)
            }
        }
    }

    private static let keyEpoch = "keyEpoch"
    private static let keyKind = "keyKind"

    class Delegate: NSObject {
        private let state: StateRepository

        init(state: StateRepository) {
            self.state = state
        }

        fileprivate func mark(shown notification: UNNotification) {
            guard
                let epoch = notification.request.content.userInfo[NotificationRepository.keyEpoch] as? TimeInterval,
                let id = notification.request.content.userInfo[NotificationRepository.keyKind] as? String
            else { return }

            let date = Date(timeIntervalSince1970: epoch)
            if date > state.deliveredNotification(for: id) {
                state.deliveredNotification(at: date, for: id)
            }
        }
    }
}

extension NotificationRepository.Delegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        mark(shown: notification)
        completionHandler([.banner, .badge, .sound])
    }
}
