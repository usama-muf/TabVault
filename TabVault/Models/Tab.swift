import Foundation
import GRDB

enum TabStatus: String, Codable, DatabaseValueConvertible {
    case parked
    case resumed
}

struct Tab: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var workspaceId: Int64
    var url: String
    var title: String
    var browser: String
    var status: TabStatus
    var createdAt: Date
    var lastVisitedAt: Date?

    init(id: Int64? = nil, workspaceId: Int64, url: String, title: String, browser: String, status: TabStatus = .parked, createdAt: Date = Date(), lastVisitedAt: Date? = nil) {
        self.id = id
        self.workspaceId = workspaceId
        self.url = url
        self.title = title
        self.browser = browser
        self.status = status
        self.createdAt = createdAt
        self.lastVisitedAt = lastVisitedAt
    }
}
