import Foundation
import UserNotifications
import Flogger

struct NotificationRepository {
    private let delegate = Delegate()

    private let zone: Zone
    private let charges: Charges
    private let prices: EnergyPriceRepository

    init(zone: Zone, charges: Charges, prices: EnergyPriceRepository) {
        self.zone = zone
        self.charges = charges
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
        guard
            let prices = try? await self.prices.data(for: zone, in: DateInterval(start: Date.now.startOfDay.date(byAdding: .day, value: -1), end: Date.now.startOfDay.date(byAdding: .day, value: 2)))
        else {
            Flog.error("Wanted to setup notification, but could not look up local prices")
            return
        }

        let evaluations = Evaluation.of(prices, using: charges)

        guard
            evaluations.count > 0
        else {
            Flog.error("Wanted to setup notification, but no relevant evaluations could be made")
            return
        }

        show(message: Message(evaluations, using: charges))
    }

    private func show(message: Message, at date: Date = .now) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        // FIXME: todays date in content.threadIdentifier?
        let seconds = date.timeIntervalSince(Date.now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
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

        init(_ evaluations: [Evaluation.Result], using charges: Charges) {
            let model = evaluations.first!.model

            let time = DateFormatter.with(format: "HH").string(from: model.timestamp)
            let value = NumberFormatter.with(style: .decimal, fractionDigits: 0).string(from: charges.format(model.price, at: model.timestamp) as NSNumber)!

            title = "Cheap power at \(time)"
            body = "The price is going to be \(value) øre/kWh"
        }
    }

    class Delegate: NSObject { }
}

extension NotificationRepository.Delegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}
