import UIKit
import UserNotifications

protocol DataLoadingState: Observerable {
    func select(network: Network)
}

protocol LaunchState {
    var network: Network { get }
    var configuration: Configuration { get }
    func save(configuration: Configuration)
}

class StateRepository: Observerable, DataLoadingState, LaunchState {
    private let store: UserDefaults

    var configuration: Configuration {
        Configuration(minimumBuildVersion: store.integer(forKey: keyMinimumBuild))
    }

    var notifications: [Notification] { Array(notificationMap.values) }
    var network = Network.empty { didSet { notifyObservers() } }
    var notificationStatus = UNAuthorizationStatus.denied { didSet { notifyObservers() } }
    var backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus { didSet { notifyObservers() } }

    private var notificationMap = [String: Notification]() { didSet { notifyObservers() } }

    init(store: UserDefaults = .standard) {
        self.store = store
        network = Network(
            id: store.integer(forKey: keySelectedNetworkId),
            name: store.string(forKey: keySelectedNetworkName) ?? "",
            zone: Zone(rawValue: store.string(forKey: keySelectedNetworkName) ?? "") ?? .dk1
        )
        super.init()
        for key in store.stringArray(forKey: keyNotificationKeys) ?? [] {
            notificationMap[key] = load(notification: key)
        }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationStatus = settings.authorizationStatus
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(backgroundRefreshStatusDidChange),
            name: UIApplication.backgroundRefreshStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.backgroundRefreshStatusDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func erase() {
        store.dictionaryRepresentation().keys.forEach { key in
            store.removeObject(forKey: key)
        }
        store.synchronize()
    }

    func forgetNetwork() {
        store.removeObject(forKey: keySelectedNetworkId)
        store.removeObject(forKey: keySelectedNetworkName)
        store.removeObject(forKey: keySelectedNetworkZone)
        network = .empty
    }

    func select(network: Network) {
        store.set(network.id, forKey: keySelectedNetworkId)
        store.set(network.name, forKey: keySelectedNetworkName)
        store.set(network.zone.rawValue, forKey: keySelectedNetworkZone)
        self.network = network
    }

    func notification(by id: String) -> Notification? {
        notificationMap[id]
    }

    func update(notification: Notification) {
        var keys = store.stringArray(forKey: keyNotificationKeys) ?? []
        keys.append(notification.id)
        store.setValue(Array(Set(keys)), forKey: keyNotificationKeys)

        store.setValue(notification.enabled, forKey: id(of: notification, with: suffixNotificationEnabled))
        store.setValue(notification.fireOffset, forKey: id(of: notification, with: suffixNotificationFire))
        store.setValue(notification.dateOffset, forKey: id(of: notification, with: suffixNotificationDate))
        store.setValue(notification.durationOffset, forKey: id(of: notification, with: suffixNotificationDuration))
        store.setValue(notification.lastDelivery.timeIntervalSince1970, forKey: id(of: notification, with: suffixNotificationDelivery))

        notificationMap[notification.id] = notification
    }

    func forget(notification: Notification) {
        let keys = store.stringArray(forKey: keyNotificationKeys) ?? []
        store.setValue(keys.filter { $0 != notification.id }, forKey: keyNotificationKeys)

        store.removeObject(forKey: id(of: notification, with: suffixNotificationEnabled))
        store.removeObject(forKey: id(of: notification, with: suffixNotificationFire))
        store.removeObject(forKey: id(of: notification, with: suffixNotificationDate))
        store.removeObject(forKey: id(of: notification, with: suffixNotificationDuration))
        store.removeObject(forKey: id(of: notification, with: suffixNotificationDelivery))

        notificationMap.removeValue(forKey: notification.id)
    }

    func save(configuration: Configuration) {
        store.setValue(configuration.minimumBuildVersion, forKey: keyMinimumBuild)
    }

    private func id(of notification: Notification, with suffix: String) -> String {
        id(of: notification.id, with: suffix)
    }

    private func id(of notification: String, with suffix: String) -> String {
        "\(prefixNotification)-\(notification)-\(suffix)"
    }

    private func load(notification: String) -> Notification? {
        let enabled = store.bool(forKey: id(of: notification, with: suffixNotificationEnabled))
        let fireOffset = store.integer(forKey: id(of: notification, with: suffixNotificationFire))
        let dateOffset = store.integer(forKey: id(of: notification, with: suffixNotificationDate))
        let durationOffset = store.integer(forKey: id(of: notification, with: suffixNotificationDuration))
        let delivery = store.double(forKey: id(of: notification, with: suffixNotificationDelivery))
        guard fireOffset >= 0, dateOffset >= 0, durationOffset > 0, delivery >= 0 else { return nil }

        return Notification(
            id: notification,
            enabled: enabled,
            fireOffset: UInt(fireOffset),
            dateOffset: UInt(dateOffset),
            durationOffset: UInt(durationOffset),
            lastDelivery: Date(timeIntervalSince1970: delivery)
        )
    }

    private let keyMinimumBuild = "keyMinimumBuild"
    private let keySelectedNetworkId = "keySelectedNetworkId"
    private let keySelectedNetworkName = "keySelectedNetworkName"
    private let keySelectedNetworkZone = "keySelectedNetworkZone"
    private let keyNotificationKeys = "keyNotificationKeys"

    private let prefixNotification = "notification"

    private let suffixNotificationEnabled = "enabled"
    private let suffixNotificationFire = "fire"
    private let suffixNotificationDate = "date"
    private let suffixNotificationDuration = "duration"
    private let suffixNotificationDelivery = "delivery"

    @objc private func backgroundRefreshStatusDidChange(notification: NSNotification) {
        backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
    }

    @objc private func didEnterBackground(notification: NSNotification) {
        store.synchronize()
    }

    @objc private func didBecomeActive() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationStatus = settings.authorizationStatus
        }
    }
}

extension Network {
    static var empty: Network {
        Network(id: 0, name: "", zone: .dk1)
    }
}
