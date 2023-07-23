// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//

import Foundation

extension Charges {
	func copy() -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}

	func copy(valueAddedTax: Double) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
	func copy(transmissionTarrif: Double) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
	func copy(networkTarrif: Double) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
	func copy(systemTarrif: Double) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
	func copy(electricityTarrif: Double) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
	func copy(lowLoadTarrif: Double) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
	func copy(highLoadTarrif: Double) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
	func copy(highLoadHours: [Int]) -> Charges {
		return Charges(
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			networkTarrif: networkTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours
		)
	}
}
