import Foundation
import Combine
import GRDB

class StateRepository {
    private let store: UserDefaults

    private var observers: [Observer] = []

    var network = Network.empty { didSet { updated() } }
    var deliveredNotification: Date = Date(timeIntervalSince1970: 0) { didSet { updated() } }

    init(store: UserDefaults = .standard) {
        self.store = store
        network = Network(
            id: store.integer(forKey: keySelectedNetworkId),
            name: store.string(forKey: keySelectedNetworkName) ?? "",
            zone: Zone(rawValue: store.string(forKey: keySelectedNetworkName) ?? "") ?? .dk1
        )
        deliveredNotification = Date(timeIntervalSince1970: store.double(forKey: keyLastDeliveredNotification))
    }

    func add(observer: Observer) {
        observers.append(observer)
    }

    func remove(observer: Observer) {
        observers.removeAll(where: { $0 === observer })
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

    func deliveredNotification(at date: Date) {
        store.set(date.timeIntervalSince1970, forKey: keyLastDeliveredNotification)
        deliveredNotification = date
    }

    private let keySelectedNetworkId = "keySelectedNetworkId"
    private let keySelectedNetworkName = "keySelectedNetworkName"
    private let keySelectedNetworkZone = "keySelectedNetworkZone"
    private let keyLastDeliveredNotification = "keyLastDeliveredNotification"

    private func updated() {
        for observer in observers {
            Task {
                observer.updated()
            }
        }
    }
}

extension Network {
    static var empty: Network {
        Network(id: 0, name: "", zone: .dk1)
    }
}

protocol Observer: AnyObject {
    func updated()
}
