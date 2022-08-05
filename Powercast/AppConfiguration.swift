import Foundation

struct AppConfiguration {
    let usesDemoData: Bool
    let allowDatabaseErasure: Bool
    let traceDatabaseStatments: Bool

    init() {
        usesDemoData = false
        allowDatabaseErasure = true
        traceDatabaseStatments = false
    }
}
