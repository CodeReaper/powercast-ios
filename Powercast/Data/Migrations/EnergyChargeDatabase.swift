import Foundation
import GRDB

struct EnergyChargesDatabase: Migratable {
    let queue: DatabaseQueue
    let configuration: AppConfiguration

    func migrate() throws {
        var migrator = DatabaseMigrator()

        if configuration.allowDatabaseErasure {
            migrator.eraseDatabaseOnSchemaChange = true
        }

        migrator.registerMigration("v1") { db in
            try db.create(table: "energyCharges") { table in
                // FIXME: configure tables
                table.primaryKey(["timestamp", "zone"], onConflict: .replace)
                table.column("zone", .text).notNull().indexed()
                table.column("timestamp", .integer).notNull().indexed()
                table.column("price", .double).notNull()
            }
        }

        try migrator.migrate(queue)
    }
}
