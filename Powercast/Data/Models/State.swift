import Foundation

struct State: AutoCopy {
    let setupCompleted: Bool
    let selectedZone: Zone
    let selectedZipCode: Int
}

extension State {
    init() {
        setupCompleted = false
        selectedZone = Zone.dk1
        selectedZipCode = -1
    }
}
