import Foundation

struct Charges: AutoCopy {
    let valueAddedTax: Double
    let transmissionTarrif: Double
    let networkTarrif: Double
    let systemTarrif: Double
    let electricityTarrif: Double
    let lowLoadTarrif: Double
    let highLoadTarrif: Double
    let highLoadHours: [Int]
}

extension Charges {
    init() {
        valueAddedTax = 0.25
        transmissionTarrif = 36.09
        networkTarrif = 5.8
        systemTarrif = 5.4
        electricityTarrif = 69.7
        lowLoadTarrif = 32.68
        highLoadTarrif = 84.09
        highLoadHours = [17, 18, 19]
    }
}
