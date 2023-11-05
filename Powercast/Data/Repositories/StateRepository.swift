import Foundation
import Combine
import GRDB

class StateRepository {
    private let store: UserDefaults

    private var stateSubject = CurrentValueSubject<State, Never>(State())

    lazy var publishedState = stateSubject.eraseToAnyPublisher()

    var state: State { stateSubject.value }

    init(store: UserDefaults = .standard) {
        self.store = store
        stateSubject.value = load()
    }

    func erase() {
        store.dictionaryRepresentation().keys.forEach { key in
            store.removeObject(forKey: key)
        }
        store.synchronize()
        stateSubject.send(State())
    }

    func setupCompleted() {
        stateSubject.send(stateSubject.value.copy(setupCompleted: true))
        persist(stateSubject.value)
    }

    func select(zone: Zone) {
        stateSubject.send(stateSubject.value.copy(selectedZone: zone))
        persist(stateSubject.value)
    }

    func select(network: Int) {
        stateSubject.send(stateSubject.value.copy(selectedNetwork: network))
        persist(stateSubject.value)
    }

    func deliveredNotification(at date: Date) {
        stateSubject.send(stateSubject.value.copy(lastDeliveredNotification: date.timeIntervalSince1970))
        persist(stateSubject.value)
    }

    private let keySetupCompleted = "keySetupCompleted"
    private let keySelectedZone = "keySelectedZone"
    private let keySelectedNetwork = "keySelectedNetwork"
    private let keyLastDeliveredNotification = "keyLastDeliveredNotification"
    private func persist(_ state: State) {
        store.set(state.setupCompleted, forKey: keySetupCompleted)
        store.set(state.selectedZone.rawValue, forKey: keySelectedZone)
        store.set(state.selectedNetwork, forKey: keySelectedNetwork)
        store.set(state.lastDeliveredNotification, forKey: keyLastDeliveredNotification)
    }

    private func load() -> State {
        var state = State()
        state = state.copy(setupCompleted: store.bool(forKey: keySetupCompleted))
        state = state.copy(selectedZone: Zone(rawValue: store.string(forKey: keySelectedZone) ?? "") ?? .dk1)
        state = state.copy(selectedNetwork: store.integer(forKey: keySelectedNetwork))
        state = state.copy(lastDeliveredNotification: store.double(forKey: keyLastDeliveredNotification))
        return state
    }
}
