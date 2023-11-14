import Foundation
import GRDB

struct EmissionDatabase: Migratable {
    let queue: DatabaseQueue
    let configuration: AppConfiguration

    func migrate() throws {
        var migrator = DatabaseMigrator()

        if configuration.allowDatabaseErasure {
            migrator.eraseDatabaseOnSchemaChange = true
        }

        migrator.registerMigration("v1") { db in
            try db.create(table: "co2") { table in
                table.primaryKey(["timestamp", "zone"], onConflict: .replace)
                table.column("zone", .text).notNull().indexed()
                table.column("timestamp", .integer).notNull().indexed()
                table.column("amount", .double).notNull()
            }
        }

        try migrator.migrate(queue)
    }
}
