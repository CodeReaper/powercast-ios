// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//  StateCopy.generated.swift
//

// swiftlint:disable all
extension State {
	func copy() -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone
		)
	}

	func copy(setupCompleted: Bool) -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone
		)
	}
	func copy(selectedZone: Zone?) -> State {
		return State(
			setupCompleted: setupCompleted,
			selectedZone: selectedZone
		)
	}
}
