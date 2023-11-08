import Foundation
import UserNotifications
import Flogger

struct NotificationRepository {
    private let delegate = Delegate()

    private let charges: ChargesRepository
    private let prices: EnergyPriceRepository
    private let state: StateRepository

    init(charges: ChargesRepository, prices: EnergyPriceRepository, state: StateRepository) {
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
            let prices = try? await self.prices.data(for: network.zone, in: DateInterval(start: Date.now.startOfDay.date(byAdding: .weekOfYear, value: -1), end: Date.now.startOfDay.date(byAdding: .day, value: 2)))
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

        let messages = Message.of(evaluations, using: charges)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        if let deliveryDate = await UNUserNotificationCenter.current().deliveredNotifications().map({ Date(timeIntervalSince1970: TimeInterval($0.request.identifier)!) }).max() {
            state.deliveredNotification(at: deliveryDate)
        }

        for message in messages where message.fireDate > state.deliveredNotification {
            Flog.info("Prepared this message: \(message.body) in \(message.fireDate.timeIntervalSince(Date.now) / 3600) hours.")
            await show(message: message, at: message.fireDate)
        }
    }

    private func show(message: Message, at date: Date) async {
        // TODO: update using https://developer.apple.com/documentation/usernotificationsui/customizing_the_appearance_of_notifications
        let content = UNMutableNotificationContent()
        content.title = Translations.NOTIFICATION_TITLE
        content.body = message.body
        let seconds = date.timeIntervalSince(Date.now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "\(date.timeIntervalSince1970)", content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Flog.error(error.localizedDescription)
        }
    }

    class Delegate: NSObject { }
}

extension NotificationRepository.Delegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}
