import Foundation
import UserNotifications
import Flogger

class NotificationScheduler {
    private let delegate: Delegate
    private let charges: ChargesRepository
    private let prices: EnergyPriceRepository
    private let state: StateRepository

    init(charges: ChargesRepository, prices: EnergyPriceRepository, state: StateRepository) {
        self.delegate = Delegate(state: state)
        self.charges = charges
        self.prices = prices
        self.state = state
        state.add(observer: self)
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

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        await center.deliveredNotifications().forEach { notification in
            delegate.mark(shown: notification)
        }

        Flog.info("Delivered notifications has been registered and pending notifications cleared.")

        do {
            for date in [Date.now, .now.endOfDay] {
                for notification in state.notifications {
                    if let request = notification.create(at: date, in: network, using: prices, and: charges) {
                        try await center.add(request)
                    }
                }
            }
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
                let epoch = notification.request.content.userInfo[Notification.DATE] as? TimeInterval,
                let id = notification.request.content.userInfo[Notification.ID] as? String,
                let notification = state.notification(by: id)
            else { return }

            let date = Date(timeIntervalSince1970: epoch)
            if date > notification.lastDelivery {
                state.update(notification: notification.copy(lastDelivery: date))
            }
        }
    }
}

extension NotificationScheduler.Delegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        mark(shown: notification)
        completionHandler([.banner, .badge, .sound])
    }
}

extension NotificationScheduler: Observer {
    func updated() {
        Task { await schedule() }
    }
}
