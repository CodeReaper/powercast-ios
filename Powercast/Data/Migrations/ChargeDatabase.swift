import Foundation
import GRDB

struct ChargesDatabase: Migratable {
    let queue: DatabaseQueue
    let configuration: AppConfiguration

    func migrate() throws {
        var migrator = DatabaseMigrator()

        if configuration.allowDatabaseErasure {
            migrator.eraseDatabaseOnSchemaChange = true
        }

        migrator.registerMigration("v1") { db in
            try db.create(table: "gridPrice") { table in
                table.primaryKey(["validFrom", "zone"], onConflict: .replace)
                table.column("zone", .text).notNull().indexed()
                table.column("validFrom", .datetime).notNull().indexed()
                table.column("validTo", .datetime)
                table.column("transmissionTariff", .double).notNull()
                table.column("systemTariff", .double).notNull()
                table.column("electricityCharge", .double).notNull()
            }

            try db.create(table: "network") { table in
                table.primaryKey(["id"], onConflict: .replace)
                table.column("id", .integer).notNull().indexed()
                table.column("name", .text).notNull()
                table.column("zone", .text).notNull()
            }

            try db.create(table: "networkPrice") { table in
                table.primaryKey(["validFrom", "networkId"], onConflict: .replace)
                table.column("validFrom", .datetime).notNull().indexed()
                table.column("validTo", .datetime)
                table.column("loadTariff", .jsonText).notNull()
                table.column("networkId", .integer).indexed().references("network", onDelete: .restrict)
            }
        }

        try migrator.migrate(queue)
    }
}
