import Foundation
import GRDB

extension App {
    // swiftlint:disable function_body_length superfluous_disable_command
    class func setup(energyPriceDatabase databaseQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            try db.create(table: "energyPrice") { table in
                table.primaryKey(["timestamp", "zone"], onConflict: .replace)
                table.column("zone", .text).notNull().indexed()
                table.column("timestamp", .integer).notNull().indexed()
                table.column("price", .double).notNull()
            }
        }

        try migrator.migrate(databaseQueue)
    }
}
