import Foundation

struct Charges {
    /// The timespan these specific values apply
    let validityPeriod: DateInterval
    /// Conversion rate of 1 Euro to DK øre
    let conversionRate: Double
    /// Source: `moms` expressed as a fraction between 0 and 1
    let valueAddedTax: Double
    /// Source: `nettarif` in DK øre
    let transmissionTarrif: Double
    /// Source: `systemtarif` in DK øre
    let systemTarrif: Double
    /// Source: `Elafgift` in DK øre
    let electricityCharge: Double
    /// Source: `nettarif C` in DK øre keyed by the local time hour
    let loadTarrifs: [Int: Double]

    private let hourFormatter = DateFormatter.with(format: "HH")

    private func loadTarrif(at date: Date) -> Double {
        if loadTarrifs.isEmpty { return 0 }
        return loadTarrifs[Int(hourFormatter.string(from: date))!] ?? 0
    }

    /// Returns the variable rate fees amount in DK øre per kWh
    ///
    /// - Parameters:
    ///     - date: The time of the price point the fees should apply to
    func variableFees(at date: Date) -> Double {
        var charge = loadTarrif(at: date)
        charge *= 1 + (charge > 0 ? valueAddedTax : 0)
        return charge
    }

    /// Returns the fixed rate fees amount in DK øre per kWh
    ///
    /// - Parameters:
    ///     - date: The time of the price point the fees should apply to
    func fixedFees(at date: Date) -> Double {
        var charge = transmissionTarrif
        charge += systemTarrif
        charge += electricityCharge
        charge *= 1 + (charge > 0 ? valueAddedTax : 0)
        return charge
    }

    /// Returns the total fees amount in DK øre per kWh
    ///
    /// - Parameters:
    ///     - date: The time of the price point the fees should apply to
    func fees(at date: Date) -> Double {
        return fixedFees(at: date) + variableFees(at: date)
    }

    /// Returns the total fees amount in Euro per MWh
    ///
    /// - Parameters:
    ///     - date: The time of the price point the fees should apply to
    func convertedFees(at date: Date) -> Double {
        return (fixedFees(at: date) + variableFees(at: date)) * 1000 / conversionRate
    }

    /// Returns a price in DK øre per kWh
    ///
    /// - Parameters:
    ///     - value: The raw MWh price in Euros
    ///     - date: The time at which the price point is active
    func format(_ value: Double, at date: Date) -> Double {
        var dkr = value / 1000 * conversionRate
        dkr += transmissionTarrif
        dkr += systemTarrif
        dkr += electricityCharge
        dkr += loadTarrif(at: date)
        dkr *= 1 + (dkr > 0 ? valueAddedTax : 0)
        return dkr
    }
}
