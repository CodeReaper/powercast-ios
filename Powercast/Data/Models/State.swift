import Foundation

struct State: AutoCopy {
    let setupCompleted: Bool
    let selectedZone: Zone
    let lastDeliveredNotification: TimeInterval
}

extension State {
    init() {
        setupCompleted = false
        selectedZone = Zone.dk1
        lastDeliveredNotification = 0
    }
}
