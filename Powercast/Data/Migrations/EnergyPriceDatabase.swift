import Foundation
import GRDB

struct EnergyPriceDatabase {
    let queue: DatabaseQueue
    let configuration: AppConfiguration

    func migrate() throws {
        var migrator = DatabaseMigrator()

        if configuration.allowDatabaseErasure {
            migrator.eraseDatabaseOnSchemaChange = true
        }

        migrator.registerMigration("v1") { db in
            try db.create(table: "energyPrice") { table in
                table.primaryKey(["timestamp", "zone"], onConflict: .replace)
                table.column("zone", .text).notNull().indexed()
                table.column("timestamp", .integer).notNull().indexed()
                table.column("price", .double).notNull()
            }
        }

        try migrator.migrate(queue)
    }
}
