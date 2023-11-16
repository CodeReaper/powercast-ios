import Foundation

struct Emission {
    struct Co2 {
        let amount: ClosedRange<Double>
        let amountSpan: ClosedRange<Double>
        let zone: Zone
        let duration: ClosedRange<Date>
    }
}
