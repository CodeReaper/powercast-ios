// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//

import Foundation

extension Notification {
	func copy() -> Notification {
		return Notification(
			id: id,
			enabled: enabled,
			fireOffset: fireOffset,
			dateOffset: dateOffset,
			durationOffset: durationOffset,
			lastDelivery: lastDelivery
		)
	}

	func copy(id: String) -> Notification {
		return Notification(
			id: id,
			enabled: enabled,
			fireOffset: fireOffset,
			dateOffset: dateOffset,
			durationOffset: durationOffset,
			lastDelivery: lastDelivery
		)
	}
	func copy(enabled: Bool) -> Notification {
		return Notification(
			id: id,
			enabled: enabled,
			fireOffset: fireOffset,
			dateOffset: dateOffset,
			durationOffset: durationOffset,
			lastDelivery: lastDelivery
		)
	}
	func copy(fireOffset: UInt) -> Notification {
		return Notification(
			id: id,
			enabled: enabled,
			fireOffset: fireOffset,
			dateOffset: dateOffset,
			durationOffset: durationOffset,
			lastDelivery: lastDelivery
		)
	}
	func copy(dateOffset: UInt) -> Notification {
		return Notification(
			id: id,
			enabled: enabled,
			fireOffset: fireOffset,
			dateOffset: dateOffset,
			durationOffset: durationOffset,
			lastDelivery: lastDelivery
		)
	}
	func copy(durationOffset: UInt) -> Notification {
		return Notification(
			id: id,
			enabled: enabled,
			fireOffset: fireOffset,
			dateOffset: dateOffset,
			durationOffset: durationOffset,
			lastDelivery: lastDelivery
		)
	}
	func copy(lastDelivery: Date) -> Notification {
		return Notification(
			id: id,
			enabled: enabled,
			fireOffset: fireOffset,
			dateOffset: dateOffset,
			durationOffset: durationOffset,
			lastDelivery: lastDelivery
		)
	}
}
