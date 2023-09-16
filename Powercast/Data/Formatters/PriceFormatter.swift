import Foundation

struct PriceFormatter {
    private let conversionRate: Double

    let charges: Charges

    init(charges: Charges, conversionRate: Double = 750) {
        self.charges = charges
        self.conversionRate = conversionRate
    }

    func format(_ value: Double, at date: Date) -> Double {
        var dkr = value / 1000 * conversionRate
        dkr += charges.transmissionTarrif
        dkr += charges.systemTarrif
        dkr += charges.electricityTarrif
        dkr += charges.isHighLoad(at: date) ? charges.highLoadTarrif : charges.lowLoadTarrif
        dkr *= 1 + (dkr > 0 ? charges.valueAddedTax : 0)
        return dkr
    }
}
