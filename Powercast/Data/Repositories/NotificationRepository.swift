import Foundation
import UserNotifications
import Flogger

class NotificationRepository {
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

        guard
            let prices = try? self.prices.data(for: network.zone, in: DateInterval(start: Date.now.startOfDay.date(byAdding: .weekOfYear, value: -1), end: Date.now.startOfDay.date(byAdding: .day, value: 2)))
        else {
            Flog.error("Wanted to setup notification, but could not look up local prices")
            return
        }

        let evaluations = Evaluation.of(prices, using: charges, and: network)

        guard
            evaluations.count > 0
        else {
            Flog.error("Wanted to setup notification, but no relevant evaluations could be made")
            return
        }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await UNUserNotificationCenter.current().deliveredNotifications().forEach { notification in
            delegate.mark(shown: notification)
        }

        for message in Message.of(evaluations, using: charges) {
            guard
                state.notifications(for: message.kind),
                message.fireDate > state.deliveredNotification(for: message.kind)
            else { continue }

            Flog.info("Prepared this message: \(message.body) in \(message.fireDate.timeIntervalSince(Date.now) / 3600) hours.")
            await show(message: message, at: message.fireDate)
        }
    }

    private static let keyEpoch = "keyEpoch"
    private static let keyKind = "keyKind"

    private func show(message: Message, at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = Translations.NOTIFICATION_TITLE
        content.body = message.body
        content.userInfo = [
            NotificationRepository.keyEpoch: date.timeIntervalSince1970,
            NotificationRepository.keyKind: message.kind.rawValue
        ]
        let seconds = date.timeIntervalSince(Date.now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Flog.error(error.localizedDescription)
        }
    }

    class Delegate: NSObject {
        private let state: StateRepository

        init(state: StateRepository) {
            self.state = state
        }

        fileprivate func mark(shown notification: UNNotification) {
            guard
                let epoch = notification.request.content.userInfo[NotificationRepository.keyEpoch] as? TimeInterval,
                let kind = Message.Kind(rawValue: notification.request.content.userInfo[NotificationRepository.keyKind] as? Int ?? -1)
            else { return }

            let date = Date(timeIntervalSince1970: epoch)
            if state.deliveredNotification(for: kind) > date {
                state.deliveredNotification(at: date, for: kind)
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
