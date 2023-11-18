import Foundation

struct Emission {
    struct Co2 {
        let amounts: ClosedRange<Double>
        let amountSpan: ClosedRange<Double>
        let zone: Zone
        let duration: ClosedRange<Date>
        let data: [Date: Double]
    }
}
