import Foundation

struct Charges: AutoCopy {
    let conversionRate: Double
    let valueAddedTax: Double
    let transmissionTarrif: Double
    let systemTarrif: Double
    let electricityTarrif: Double
    let lowLoadTarrif: Double
    let highLoadTarrif: Double
    let highLoadHours: [Int]
    let highLoadMonths: [Int]

    private let hourFormatter = DateFormatter.with(format: "HH") // sourcery:skip
    private let monthFormatter = DateFormatter.with(format: "MM") // sourcery:skip

    func isHighLoad(at date: Date) -> Bool {
        return highLoadMonths.contains(Int(monthFormatter.string(from: date))!) && highLoadHours.contains(Int(hourFormatter.string(from: date))!)
    }

    func fees(at date: Date) -> Double {
        var charge = transmissionTarrif
        charge += systemTarrif
        charge += electricityTarrif
        charge += isHighLoad(at: date) ? highLoadTarrif : lowLoadTarrif
        charge = charge * valueAddedTax * 1000 / conversionRate
        return charge
    }

    func format(_ value: Double, at date: Date) -> Double {
        var dkr = value / 1000 * conversionRate
        dkr += transmissionTarrif
        dkr += systemTarrif
        dkr += electricityTarrif
        dkr += isHighLoad(at: date) ? highLoadTarrif : lowLoadTarrif
        dkr *= 1 + (dkr > 0 ? valueAddedTax : 0)
        return dkr
    }
}

extension Charges {
    init() {
        conversionRate = 750

        valueAddedTax = 0.25
        transmissionTarrif = 5.8
        systemTarrif = 5.4
        electricityTarrif = 69.7

        lowLoadTarrif = 32.68
        highLoadTarrif = 84.09
        highLoadHours = [17, 18, 19]
        highLoadMonths = [1, 2, 3, 10, 11, 12]
    }
}
