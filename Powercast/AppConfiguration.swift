import Foundation

struct AppConfiguration {
    let allowDatabaseErasure: Bool
    let traceDatabaseStatments: Bool

    init() {
        allowDatabaseErasure = true
        traceDatabaseStatments = false
    }
}
