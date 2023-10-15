import XCTest
@testable import Powercast

final class EvaluationTests: XCTestCase {
    struct ChargesServiceMock: ChargesService {
        let charges: Charges

        func `for`(_ date: Date) -> Powercast.Charges {
            return charges
        }
    }

    private let service = ChargesServiceMock(charges: Charges(validityPeriod: DateInterval(), conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 10, systemTarrif: 10, electricityCharge: 10, loadTarrifs: [:]))

    func testOnlyRelevantEvaluationsAreReturned() {
        let cases = [
            (0, -1, 0),
            (0, -10, 0),
            (2, -10, 0),
            (2, -2, 0),
            (2, -1, 1),
            (200, -199, 1),
            (10, 0, 10),
            (10, 10, 10)
        ]
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)

        for (count, offset, expected) in cases {
            let items = EnergyPrices.make(count, startingAt: date.date(byAdding: .hour, value: offset))

            let results = Evaluation.of(items, after: date, using: service)

            XCTContext.runActivity(named: "Test making \(count) items staring \(offset) hours ago and expecting to get \(expected) relevant evaluations") { _ in
                XCTAssertEqual(results.count, expected)
            }
        }
    }

    func testPropertiesAreCorrectForExactSamePrices() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(10, startingAt: date)

        let results = Evaluation.of(items, after: date, using: service)

        XCTAssertEqual(results.count, 10)
        for result in results {
            XCTAssertTrue(result.cheapestAvailable)
            XCTAssertTrue(result.priciestAvailable)
            XCTAssertTrue(result.belowAverage)
            XCTAssertTrue(result.belowAvailableAverage)
        }
    }

    func testNegativelyPricedPropertyIsCalulatedCorrectly() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(1, startingAt: date, costing: 1) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 1), costing: 0) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 1), costing: -1)

        let results = Evaluation.of(items, after: date, using: service)

        XCTAssertEqual(results.count, 3)

        XCTAssertTrue(results[0].priciestAvailable)
        XCTAssertTrue(results[0].mostlyFees)

        XCTAssertTrue(results[1].mostlyFees)
        XCTAssertTrue(results[1].belowAverage)
        XCTAssertTrue(results[1].belowAvailableAverage)

        XCTAssertTrue(results[2].cheapestAvailable)
        XCTAssertTrue(results[2].mostlyFees)
        XCTAssertTrue(results[2].negativelyPriced)
        XCTAssertTrue(results[2].belowAverage)
        XCTAssertTrue(results[2].belowAvailableAverage)
    }

    func testCheapestPropertyIsCalulatedCorrectlyInSimpleCase() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(9, startingAt: date, costing: 100) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 9), costing: 50)

        var results = Evaluation.of(items, after: date, using: service)
        let last = results.popLast()!

        XCTAssertEqual(results.count, 9)

        XCTAssertTrue(last.cheapestAvailable)
        XCTAssertTrue(last.belowAverage)
        XCTAssertTrue(last.belowAvailableAverage)

        for result in results {
            XCTAssertTrue(result.priciestAvailable)
            XCTAssertTrue(result.aboveAverage)
            XCTAssertTrue(result.aboveAvailableAverage)
        }
    }

    func testCheapestPropertyIsCalulatedCorrectlyWithNegativePrices() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(8, startingAt: date, costing: 100) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 8), costing: -10) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 9), costing: -15)

        var results = Evaluation.of(items, after: date, using: service)
        let last = results.popLast()!
        let penultimate = results.popLast()!

        XCTAssertEqual(results.count, 8)

        XCTAssertTrue(last.cheapestAvailable)
        XCTAssertTrue(last.negativelyPriced)
        XCTAssertTrue(last.mostlyFees)
        XCTAssertTrue(last.belowAverage)
        XCTAssertTrue(last.belowAvailableAverage)

        XCTAssertTrue(penultimate.negativelyPriced)
        XCTAssertTrue(penultimate.mostlyFees)
        XCTAssertTrue(penultimate.belowAverage)
        XCTAssertTrue(penultimate.belowAvailableAverage)

        for result in results {
            XCTAssertTrue(result.priciestAvailable)
            XCTAssertTrue(result.aboveAverage)
            XCTAssertTrue(result.aboveAvailableAverage)
        }
    }

    func testPriciestPropertyIsCalulatedCorrectlyInSimpleCase() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(9, startingAt: date, costing: 100) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 9), costing: 150)

        var results = Evaluation.of(items, after: date, using: service)
        let last = results.popLast()!

        XCTAssertEqual(results.count, 9)

        XCTAssertTrue(last.priciestAvailable)
        XCTAssertTrue(last.aboveAverage)
        XCTAssertTrue(last.aboveAvailableAverage)

        for result in results {
            XCTAssertTrue(result.cheapestAvailable)
            XCTAssertTrue(result.belowAverage)
            XCTAssertTrue(result.belowAvailableAverage)
        }
    }

    func testMostlyFeesPropertyIsCalulatedCorrectly() {
        let cases = [
            (true, -0.1, Charges(validityPeriod: DateInterval(), conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityCharge: 0, loadTarrifs: [:])),
            (false, 0.0, Charges(validityPeriod: DateInterval(), conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityCharge: 0, loadTarrifs: [:])),
            (false, 1.0, Charges(validityPeriod: DateInterval(), conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityCharge: 0, loadTarrifs: [:])),
            (true, 249.9, Charges(validityPeriod: DateInterval(), conversionRate: 100, valueAddedTax: 1, transmissionTarrif: 10, systemTarrif: 10, electricityCharge: 5, loadTarrifs: [:])),
            (false, 250.0, Charges(validityPeriod: DateInterval(), conversionRate: 100, valueAddedTax: 1, transmissionTarrif: 10, systemTarrif: 10, electricityCharge: 5, loadTarrifs: [:])),
            (false, 250.1, Charges(validityPeriod: DateInterval(), conversionRate: 100, valueAddedTax: 1, transmissionTarrif: 10, systemTarrif: 10, electricityCharge: 5, loadTarrifs: [:]))
        ]

        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)

        for (expected, cost, charges) in cases {
            let items = EnergyPrices.make(1, startingAt: date, costing: cost)

            let service = ChargesServiceMock(charges: charges)
            let results = Evaluation.of(items, after: date, using: service)

            XCTContext.runActivity(named: "Test calculating fees property against \(cost) as price to get expected result") { _ in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].mostlyFees, expected)
            }
        }
    }

    func testFreePropertyIsCalulatedCorrectly() {
        let cases = [
            (false, 0.0),
            (false, 1.0),
            (false, 10.0),
            (false, 100.0),
            (true, -0.1),
            (true, -1.0),
            (true, -10.0),
            (true, -100.0)
        ]

        let charges = ChargesServiceMock(charges: Charges(validityPeriod: DateInterval(), conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityCharge: 0, loadTarrifs: [:]))
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)

        for (expected, cost) in cases {
            let items = EnergyPrices.make(1, startingAt: date, costing: cost)

            let results = Evaluation.of(items, after: date, using: charges)

            XCTContext.runActivity(named: "Test calculating if negative price exceeds fees for \(cost) as price") { _ in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].free, expected)
            }
        }
    }
}
