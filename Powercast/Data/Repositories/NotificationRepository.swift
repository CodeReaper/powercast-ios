import Foundation
import UserNotifications

class NotificationRepository: NSObject {
    func register() {
        UNUserNotificationCenter.current().delegate = self
    }

    func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, error in
            if let error = error {
                Humio.error(error.localizedDescription)
            }
        }
    }

    func show(message: Message, after seconds: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Humio.error(error.localizedDescription)
            }
        }
    }

    struct Message {
        let title: String
        let body: String
    }
}

extension NotificationRepository: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}
