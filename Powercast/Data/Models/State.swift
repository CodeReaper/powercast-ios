import Foundation

struct State: AutoCopy {
    let setupCompleted: Bool
    let selectedZone: Zone?
}

extension State {
    init() {
        setupCompleted = false
        selectedZone = nil
    }
}
