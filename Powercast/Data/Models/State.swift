import Foundation

struct State: AutoCopy {
    let setupCompleted: Bool
    let selectedZone: Zone
    let selectedNetwork: Int
    let lastDeliveredNotification: TimeInterval
}

extension State {
    init() {
        setupCompleted = false
        selectedZone = Zone.dk1
        selectedNetwork = 0
        lastDeliveredNotification = 0
    }

    var network: Network {
        Network(id: selectedNetwork, name: "FIXME", zone: selectedZone)
    }
}
