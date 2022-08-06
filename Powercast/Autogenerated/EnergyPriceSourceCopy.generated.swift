// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//

// swiftlint:disable all
import Foundation

extension EnergyPriceSource {
	func copy() -> EnergyPriceSource {
		return EnergyPriceSource(
			fetched: fetched,
			zone: zone,
			timestamp: timestamp
		)
	}

	func copy(fetched: Bool) -> EnergyPriceSource {
		return EnergyPriceSource(
			fetched: fetched,
			zone: zone,
			timestamp: timestamp
		)
	}
	func copy(zone: Zone) -> EnergyPriceSource {
		return EnergyPriceSource(
			fetched: fetched,
			zone: zone,
			timestamp: timestamp
		)
	}
	func copy(timestamp: Date) -> EnergyPriceSource {
		return EnergyPriceSource(
			fetched: fetched,
			zone: zone,
			timestamp: timestamp
		)
	}
}
