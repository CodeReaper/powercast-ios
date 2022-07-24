import Foundation
import Combine
import GRDB

class StateRepository {
    private let store: UserDefaults

    private(set) var state = State()

    init(store: UserDefaults = .standard) {
        self.store = store
        state = load()
    }

    func erase() {
        store.dictionaryRepresentation().keys.forEach { key in
            store.removeObject(forKey: key)
        }
        store.synchronize()
        state = State()
    }

    func setupCompleted() {
        state = state.copy(setupCompleted: true)
        persist(state)
    }

    func select(_ zone: Zone) {
        state = state.copy(selectedZone: zone)
        persist(state)
    }

    private let keySetupCompleted = "keySetupCompleted"
    private let keySelectedZone = "keySelectedZone"
    private func persist(_ state: State) {
        store.set(state.setupCompleted, forKey: keySetupCompleted)
        store.set(state.selectedZone?.rawValue, forKey: keySelectedZone)
    }

    private func load() -> State {
        var state = State()
        state = state.copy(setupCompleted: store.bool(forKey: keySetupCompleted))
        state = state.copy(selectedZone: Zone(rawValue: store.string(forKey: keySelectedZone) ?? ""))

        if state.setupCompleted && state.selectedZone == nil {
            state = state.copy(setupCompleted: false)
        }
        return state
    }
}
