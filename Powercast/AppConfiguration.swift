import Foundation

struct AppConfiguration {
    let isRunningOnSimulator: Bool
    let isRunningUnitTests: Bool
    let allowDatabaseErasure: Bool
    let traceDatabaseStatments: Bool

    init() {
#if targetEnvironment(simulator)
        isRunningOnSimulator = true
#else
        isRunningOnSimulator = false
#endif
        isRunningUnitTests = NSClassFromString("XCTest") != nil
        allowDatabaseErasure = true
        traceDatabaseStatments = false
    }
}
