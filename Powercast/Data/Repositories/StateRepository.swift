import Foundation
import Combine
import GRDB

class StateRepository {
    private let store: UserDefaults

    private var stateSubject = CurrentValueSubject<State, Never>(State())

    lazy var statePublisher = stateSubject.eraseToAnyPublisher()

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

    func select(zone: Zone, zipCode: Int) {
        stateSubject.send(stateSubject.value.copy(selectedZone: zone).copy(selectedZipCode: zipCode))
        persist(stateSubject.value)
    }

    private let keySetupCompleted = "keySetupCompleted"
    private let keySelectedZone = "keySelectedZone"
    private let keySelectedZipCode = "keySelectedZipCode"
    private func persist(_ state: State) {
        store.set(state.setupCompleted, forKey: keySetupCompleted)
        store.set(state.selectedZone.rawValue, forKey: keySelectedZone)
        store.set(state.selectedZipCode, forKey: keySelectedZipCode)
    }

    private func load() -> State {
        var state = State()
        state = state.copy(setupCompleted: store.bool(forKey: keySetupCompleted))
        state = state.copy(selectedZone: Zone(rawValue: store.string(forKey: keySelectedZone) ?? "") ?? .dk1)
        state = state.copy(selectedZipCode: store.integer(forKey: keySelectedZipCode))
        return state
    }
}
