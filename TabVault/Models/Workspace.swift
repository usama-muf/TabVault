import Foundation
import GRDB

struct Workspace: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(id: Int64? = nil, name: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
