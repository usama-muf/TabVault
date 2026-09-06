import Foundation

protocol BrowserAdapter {
    func getOpenTabs() throws -> [OpenTab]
    func openTab(url: String) throws
    func closeTab(matchingUrl url: String) throws
    func getActiveTab() throws -> OpenTab?
}

struct OpenTab: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let title: String
    let browser: String
}

enum BrowserAdapterError: Error {
    case browserNotRunning
    case appleScriptFailed(String)
    case tabNotFound
}
