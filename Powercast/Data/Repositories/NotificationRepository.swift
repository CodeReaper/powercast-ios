import Foundation
import UserNotifications
import Flogger

struct NotificationRepository {
    private let delegate = Delegate()

    private let prices: EnergyPriceRepository

    init(prices: EnergyPriceRepository) {
        self.prices = prices
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
        // TODO: look up settings schedule approiate notifications instead of this no-sense
        show(message: Message(title: "Powercast - updated", body: "Yay!"))
    }

    private func show(message: Message, after seconds: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Flog.error(error.localizedDescription)
            }
        }
    }

    private struct Message {
        let title: String
        let body: String
    }

    class Delegate: NSObject { }
}

extension NotificationRepository.Delegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}
