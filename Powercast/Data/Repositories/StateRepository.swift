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

    func select(_ zone: Zone) {
        stateSubject.send(stateSubject.value.copy(selectedZone: zone))
        persist(stateSubject.value)
    }

    private let keySetupCompleted = "keySetupCompleted"
    private let keySelectedZone = "keySelectedZone"
    private func persist(_ state: State) {
        store.set(state.setupCompleted, forKey: keySetupCompleted)
        store.set(state.selectedZone.rawValue, forKey: keySelectedZone)
    }

    private func load() -> State {
        var state = State()
        state = state.copy(setupCompleted: store.bool(forKey: keySetupCompleted))
        state = state.copy(selectedZone: Zone(rawValue: store.string(forKey: keySelectedZone) ?? "") ?? .dk1)
        return state
    }
}
