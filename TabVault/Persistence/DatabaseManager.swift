import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()
    let dbPool: DatabasePool

    private init() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let directoryURL = appSupportURL.appendingPathComponent("com.usama.TabVault", isDirectory: true)
            
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let databaseURL = directoryURL.appendingPathComponent("tabvault.sqlite")
            dbPool = try DatabasePool(path: databaseURL.path)
            
            try migrator.migrate(dbPool)
        } catch {
            // Fatal error is the standard approach here, as the app fundamentally cannot function without its local database.
            fatalError("Failed to initialize database: \(error)")
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { db in
            try db.create(table: "workspace") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique()
                t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updatedAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }
            
            try db.create(table: "tab") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("workspaceId", .integer).notNull().references("workspace", onDelete: .cascade)
                t.column("url", .text).notNull()
                t.column("title", .text).notNull().defaults(to: "")
                t.column("browser", .text).notNull().check { $0 == "safari" || $0 == "brave" || $0 == "chrome" }
                t.column("status", .text).notNull().defaults(to: "parked").check { $0 == "parked" || $0 == "resumed" }
                t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("lastVisitedAt", .datetime)
            }
            
            try db.execute(sql: "INSERT INTO workspace (name) VALUES (?)", arguments: ["Unsorted"])
        }
        
        return migrator
    }
}
