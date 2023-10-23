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
                table.column("exchangeRate", .double).notNull()
                table.column("vat", .double).notNull()
                table.column("transmissionTariff", .double).notNull()
                table.column("systemTariff", .double).notNull()
                table.column("electricityCharge", .double).notNull()
            }

            try db.create(table: "networkPrice") { table in
                table.primaryKey(["validFrom", "zone", "id"], onConflict: .replace)
                table.column("zone", .text).notNull().indexed()
                table.column("validFrom", .datetime).notNull().indexed()
                table.column("validTo", .datetime)
                table.column("id", .integer).notNull().indexed()
                table.column("name", .text).notNull()
                table.column("loadTariff", .jsonText).notNull()
            }
        }

        try migrator.migrate(queue)
    }
}
