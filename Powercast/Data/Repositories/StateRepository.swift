import UIKit
import UserNotifications

class StateRepository: Observerable {
    private let store: UserDefaults

    var network = Network.empty { didSet { notifyObservers() } }
    var notificationStatus = UNAuthorizationStatus.denied { didSet { notifyObservers() } }
    var backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus { didSet { notifyObservers() } }

    private var deliveredNotifications = [Message.Kind: Date]() { didSet { notifyObservers() } }
    private var disabledNotifications = [Message.Kind: Bool]() { didSet { notifyObservers() } }

    init(store: UserDefaults = .standard) {
        self.store = store
        network = Network(
            id: store.integer(forKey: keySelectedNetworkId),
            name: store.string(forKey: keySelectedNetworkName) ?? "",
            zone: Zone(rawValue: store.string(forKey: keySelectedNetworkName) ?? "") ?? .dk1
        )
        for type in Message.Kind.allCases {
            deliveredNotifications[type] = Date(timeIntervalSince1970: store.double(forKey: "\(keyLastDeliveredNotification)\(type.rawValue)"))
            disabledNotifications[type] = store.bool(forKey: "\(keyEnabledNotification)\(type.rawValue)")
        }
        super.init()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationStatus = settings.authorizationStatus
        }
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(backgroundRefreshStatusDidChange),
          name: UIApplication.backgroundRefreshStatusDidChangeNotification,
          object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.backgroundRefreshStatusDidChangeNotification, object: nil)
    }

    func erase() {
        store.dictionaryRepresentation().keys.forEach { key in
            store.removeObject(forKey: key)
        }
        store.synchronize()
    }

    func forgetNetwork() {
        store.set(0, forKey: keySelectedNetworkId)
        store.set("", forKey: keySelectedNetworkName)
        store.set("", forKey: keySelectedNetworkZone)
        network = .empty
    }

    func select(network: Network) {
        store.set(network.id, forKey: keySelectedNetworkId)
        store.set(network.name, forKey: keySelectedNetworkName)
        store.set(network.zone.rawValue, forKey: keySelectedNetworkZone)
        self.network = network
    }

    func deliveredNotification(for type: Message.Kind) -> Date {
        deliveredNotifications[type] ?? Date(timeIntervalSince1970: 0)
    }

    func deliveredNotification(at date: Date, for type: Message.Kind) {
        store.set(date.timeIntervalSince1970, forKey: "\(keyLastDeliveredNotification)\(type.rawValue)")
        deliveredNotifications[type] = date
    }

    func notifications(for type: Message.Kind) -> Bool {
        !(disabledNotifications[type] ?? true)
    }

    func notifications(enabled: Bool, for type: Message.Kind) {
        store.set(!enabled, forKey: "\(keyEnabledNotification)\(type.rawValue)")
        disabledNotifications[type] = !enabled
    }

    private let keySelectedNetworkId = "keySelectedNetworkId"
    private let keySelectedNetworkName = "keySelectedNetworkName"
    private let keySelectedNetworkZone = "keySelectedNetworkZone"
    private let keyEnabledNotification = "keyEnabledNotification-"
    private let keyLastDeliveredNotification = "keyLastDeliveredNotification-"

    @objc private func backgroundRefreshStatusDidChange(notification: NSNotification) {
        backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
    }
}

extension Network {
    static var empty: Network {
        Network(id: 0, name: "", zone: .dk1)
    }
}
