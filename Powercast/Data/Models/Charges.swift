import Foundation

struct Charges {
    /// Conversion rate of 1 Euro to DK øre
    let exchangeRate: Double = 746
    /// Source: `moms` expressed as a fraction between 0 and 1
    let valueAddedTax: Double = 0.25
    /// Source: `nettarif` in DK øre
    let transmissionTariff: Double
    /// Source: `systemtarif` in DK øre
    let systemTariff: Double
    /// Source: `Elafgift` in DK øre
    let electricityCharge: Double
    /// Source: `nettarif C` in DK øre keyed by the local time hour
    let loadTariffs: [Int: Double]

    private let hourFormatter = DateFormatter.with(format: "HH")

    private func loadTariff(at date: Date) -> Double {
        if loadTariffs.isEmpty { return 0 }
        return loadTariffs[Int(hourFormatter.string(from: date))!] ?? 0
    }

    /// Returns the variable rate fees amount in DK øre per kWh
    ///
    /// - Parameters:
    ///     - date: The time of the price point the fees should apply to
    func variableFees(at date: Date) -> Double {
        var charge = loadTariff(at: date)
        charge *= 1 + (charge > 0 ? valueAddedTax : 0)
        return charge
    }

    /// Returns the fixed rate fees amount in DK øre per kWh
    ///
    /// - Parameters:
    ///     - date: The time of the price point the fees should apply to
    func fixedFees(at date: Date) -> Double {
        var charge = transmissionTariff
        charge += systemTariff
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
        return (fixedFees(at: date) + variableFees(at: date)) * 1000 / exchangeRate
    }

    /// Returns a price in DK øre per kWh including taxes, fees, charges and tariffs
    ///
    /// - Parameters:
    ///     - value: The raw MWh price in Euros
    ///     - date: The time at which the price point is active
    func format(_ value: Double, at date: Date) -> Double {
        var dkr = value / 1000 * exchangeRate
        dkr += transmissionTariff
        dkr += systemTariff
        dkr += electricityCharge
        dkr += loadTariff(at: date)
        dkr *= 1 + (dkr > 0 ? valueAddedTax : 0)
        return dkr
    }

    /// Converts a MWh price in Euros to a price in DK øre per kWh
    ///
    /// - Parameters:
    ///     - value: The raw MWh price in Euros
    ///     - date: The time at which the price point is active
    func convert(_ value: Double, at date: Date) -> Double {
        return value / 1000 * exchangeRate
    }

    static func from(_ grid: GridPrice, and network: NetworkPrice) -> Charges {
        return Charges(
            transmissionTariff: grid.transmissionTariff,
            systemTariff: grid.systemTariff,
            electricityCharge: grid.electricityCharge,
            loadTariffs: Dictionary(uniqueKeysWithValues: network.loadTariff.enumerated().map { ($0.offset, $0.element) })
        )
    }
}
