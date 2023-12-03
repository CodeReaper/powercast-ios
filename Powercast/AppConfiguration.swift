import Foundation

struct AppConfiguration {
    let isReleaseBuild: Bool
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
#if DEBUG
        isReleaseBuild = false
#else
        isReleaseBuild = true
#endif
        isRunningUnitTests = NSClassFromString("XCTest") != nil
        allowDatabaseErasure = true
        traceDatabaseStatments = false
    }
}
