import Foundation

protocol ChargesService {
    func `for`(_ date: Date) -> Charges
}

class ChargesServiceHardcoded: ChargesService {
    func `for`(_ date: Date) -> Charges { // swiftlint:disable:this function_body_length
        let charges = [
            Charges(
                validityPeriod: DateInterval(start: Date(timeIntervalSince1970: 1696118400), end: Date(timeIntervalSince1970: 1704067200 - 1)),
                conversionRate: 750,
                valueAddedTax: 0.25,
                transmissionTarrif: 5.8,
                systemTarrif: 5.4,
                electricityCharge: 69.7,
                loadTarrifs: [
                    0: 32.68,
                    1: 32.68,
                    2: 32.68,
                    3: 32.68,
                    4: 32.68,
                    5: 32.68,
                    6: 32.68,
                    7: 32.68,
                    8: 32.68,
                    9: 32.68,
                    10: 32.68,
                    11: 32.68,
                    12: 32.68,
                    13: 32.68,
                    14: 32.68,
                    15: 32.68,
                    16: 32.68,
                    17: 84.09,
                    18: 84.09,
                    19: 84.09,
                    20: 84.09,
                    21: 32.68,
                    22: 32.68,
                    23: 32.68
                ]
            ),
            Charges(
                validityPeriod: DateInterval(start: Date(timeIntervalSince1970: 1704067200), end: Date(timeIntervalSince1970: 1711922400 - 1)),
                conversionRate: 750,
                valueAddedTax: 0.25,
                transmissionTarrif: 5.8,
                systemTarrif: 5.4,
                electricityCharge: 69.7,
                loadTarrifs: [
                    0: 13.76,
                    1: 13.76,
                    2: 13.76,
                    3: 13.76,
                    4: 13.76,
                    5: 13.76,
                    6: 41.29,
                    7: 41.29,
                    8: 41.29,
                    9: 41.29,
                    10: 41.29,
                    11: 41.29,
                    12: 41.29,
                    13: 41.29,
                    14: 41.29,
                    15: 41.29,
                    16: 41.29,
                    17: 123.86,
                    18: 123.86,
                    19: 123.86,
                    20: 123.86,
                    21: 41.29,
                    22: 41.29,
                    23: 41.29
                ]
            )
        ]
        return charges.last(where: { $0.validityPeriod.contains(date) }) ?? charges.last!
    }
}
