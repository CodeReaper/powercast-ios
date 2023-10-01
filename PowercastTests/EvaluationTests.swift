import XCTest
@testable import Powercast

final class EvaluationTests: XCTestCase {
    private let charges = Charges()

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

            let results = Evaluation.of(items, after: date, using: charges)

            XCTContext.runActivity(named: "Test making \(count) items staring \(offset) hours ago and expecting to get \(expected) relevant evaluations") { _ in
                XCTAssertEqual(results.count, expected)
            }
        }
    }

    func testPropertiesAreCorrectForExactSamePrices() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(10, startingAt: date)

        let results = Evaluation.of(items, after: date, using: charges)

        XCTAssertEqual(results.count, 10)
        for result in results {
            XCTAssertTrue(does(result, have: [.cheapestAvailable, .priciestAvailable, .belowAverage, .belowAvailableAverage]))
        }
    }

    func testNegativelyPricedPropertyIsCalulatedCorrectly() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(1, startingAt: date, costing: 1) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 1), costing: 0) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 1), costing: -1)

        let results = Evaluation.of(items, after: date, using: charges)

        XCTAssertEqual(results.count, 3)

        XCTAssertTrue(does(results[0], have: [.priciestAvailable, .mostlyFees, .belowAverage, .belowAvailableAverage]))
        XCTAssertTrue(does(results[1], have: [.mostlyFees, .belowAverage, .belowAvailableAverage]))
        XCTAssertTrue(does(results[2], have: [.cheapestAvailable, .mostlyFees, .negativelyPriced, .belowAverage, .belowAvailableAverage]))
    }

    func testCheapestPropertyIsCalulatedCorrectlyInSimpleCase() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(9, startingAt: date, costing: 100) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 9), costing: 50)

        var results = Evaluation.of(items, after: date, using: charges)
        let last = results.popLast()!

        XCTAssertEqual(results.count, 9)

        XCTAssertTrue(does(last, have: [.cheapestAvailable, .belowAverage, .belowAvailableAverage]))

        for result in results {
            XCTAssertTrue(does(result, have: [.priciestAvailable, .aboveAverage, .aboveAvailableAverage]))
        }
    }

    func testCheapestPropertyIsCalulatedCorrectlyWithNegativePrices() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(8, startingAt: date, costing: 100) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 8), costing: -10) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 9), costing: -15)

        var results = Evaluation.of(items, after: date, using: charges)
        let last = results.popLast()!
        let penultimate = results.popLast()!

        XCTAssertEqual(results.count, 8)

        XCTAssertTrue(does(last, have: [.cheapestAvailable, .negativelyPriced, .mostlyFees, .belowAverage, .belowAvailableAverage]))
        XCTAssertTrue(does(penultimate, have: [.negativelyPriced, .mostlyFees, .belowAverage, .belowAvailableAverage]))

        for result in results {
            XCTAssertTrue(does(result, have: [.priciestAvailable, .aboveAverage, .aboveAvailableAverage]))
        }
    }

    func testPriciestPropertyIsCalulatedCorrectlyInSimpleCase() {
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)
        let items = EnergyPrices.make(9, startingAt: date, costing: 100) + EnergyPrices.make(1, startingAt: date.date(byAdding: .hour, value: 9), costing: 150)

        var results = Evaluation.of(items, after: date, using: charges)
        let last = results.popLast()!

        XCTAssertEqual(results.count, 9)

        XCTAssertTrue(does(last, have: [.priciestAvailable, .aboveAverage, .aboveAvailableAverage]))

        for result in results {
            XCTAssertTrue(does(result, have: [.cheapestAvailable, .belowAverage, .belowAvailableAverage]))
        }
    }

    func testMostlyFeesPropertyIsCalulatedCorrectly() {
        let cases = [
            (true, -0.1, Charges(conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityTarrif: 0, lowLoadTarrif: 0, highLoadTarrif: 0, highLoadHours: [], highLoadMonths: [])),
            (false, 0.0, Charges(conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityTarrif: 0, lowLoadTarrif: 0, highLoadTarrif: 0, highLoadHours: [], highLoadMonths: [])),
            (false, 1.0, Charges(conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityTarrif: 0, lowLoadTarrif: 0, highLoadTarrif: 0, highLoadHours: [], highLoadMonths: [])),
            (true, 124.9, Charges(conversionRate: 100, valueAddedTax: 1, transmissionTarrif: 10, systemTarrif: 10, electricityTarrif: 5, lowLoadTarrif: 0, highLoadTarrif: 10, highLoadHours: [], highLoadMonths: [])),
            (false, 125.0, Charges(conversionRate: 100, valueAddedTax: 1, transmissionTarrif: 10, systemTarrif: 10, electricityTarrif: 5, lowLoadTarrif: 0, highLoadTarrif: 10, highLoadHours: [], highLoadMonths: [])),
            (false, 125.1, Charges(conversionRate: 100, valueAddedTax: 1, transmissionTarrif: 10, systemTarrif: 10, electricityTarrif: 5, lowLoadTarrif: 0, highLoadTarrif: 10, highLoadHours: [], highLoadMonths: []))
        ]

        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)

        for (expected, cost, charges) in cases {
            let items = EnergyPrices.make(1, startingAt: date, costing: cost)

            let results = Evaluation.of(items, after: date, using: charges)

            XCTContext.runActivity(named: "Test calculating fees property against \(cost) as price to get expected result") { _ in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].properties.contains(.mostlyFees), expected)
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

        let charges = Charges(conversionRate: 750, valueAddedTax: 0, transmissionTarrif: 0, systemTarrif: 0, electricityTarrif: 0, lowLoadTarrif: 0, highLoadTarrif: 0, highLoadHours: [], highLoadMonths: [])
        let date = Date.now.date(bySetting: .second, value: 0).date(bySetting: .minute, value: 0).date(bySetting: .hour, value: 0)

        for (expected, cost) in cases {
            let items = EnergyPrices.make(1, startingAt: date, costing: cost)

            let results = Evaluation.of(items, after: date, using: charges)

            XCTContext.runActivity(named: "Test calculating if negative price exceeds fees for \(cost) as price") { _ in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].properties.contains(.free), expected)
            }
        }
    }

    private func does(_ item: Evaluation.Result, have properties: [Evaluation.Property]) -> Bool {
        properties.allSatisfy { item.properties.contains($0) } && item.properties.count == properties.count
    }
}
