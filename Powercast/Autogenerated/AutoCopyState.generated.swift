// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//

import Foundation

extension State {
	func copy() -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone,
			selectedNetwork: selectedNetwork,
			lastDeliveredNotification: lastDeliveredNotification
		)
	}

	func copy(setupCompleted: Bool) -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone,
			selectedNetwork: selectedNetwork,
			lastDeliveredNotification: lastDeliveredNotification
		)
	}
	func copy(selectedZone: Zone) -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone,
			selectedNetwork: selectedNetwork,
			lastDeliveredNotification: lastDeliveredNotification
		)
	}
	func copy(selectedNetwork: Int) -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone,
			selectedNetwork: selectedNetwork,
			lastDeliveredNotification: lastDeliveredNotification
		)
	}
	func copy(lastDeliveredNotification: TimeInterval) -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone,
			selectedNetwork: selectedNetwork,
			lastDeliveredNotification: lastDeliveredNotification
		)
	}
}
