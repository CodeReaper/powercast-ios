import Foundation

struct AppConfiguration {
    let usesDemoData: Bool
    let allowDatabaseErasure: Bool
    let inMemoryDatabase: Bool
    let traceDatabaseStatments: Bool

    init() {
        usesDemoData = false
        allowDatabaseErasure = true
        inMemoryDatabase = false
        traceDatabaseStatments = false
    }
}
