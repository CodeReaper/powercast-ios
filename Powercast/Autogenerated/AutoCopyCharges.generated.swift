// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//

import Foundation

extension Charges {
	func copy() -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}

	func copy(conversionRate: Double) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(valueAddedTax: Double) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(transmissionTarrif: Double) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(systemTarrif: Double) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(electricityTarrif: Double) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(lowLoadTarrif: Double) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(highLoadTarrif: Double) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(highLoadHours: [Int]) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
	func copy(highLoadMonths: [Int]) -> Charges {
		return Charges(
			conversionRate: conversionRate,
			valueAddedTax: valueAddedTax,
			transmissionTarrif: transmissionTarrif,
			systemTarrif: systemTarrif,
			electricityTarrif: electricityTarrif,
			lowLoadTarrif: lowLoadTarrif,
			highLoadTarrif: highLoadTarrif,
			highLoadHours: highLoadHours,
			highLoadMonths: highLoadMonths
		)
	}
}
