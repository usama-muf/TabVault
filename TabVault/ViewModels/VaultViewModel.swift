import Foundation
import AppKit
import GRDB
import Combine
import UniformTypeIdentifiers

class VaultViewModel: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var tabsByWorkspace: [Int64: [Tab]] = [:]
    
    private let dbPool: DatabasePool
    private let safari = SafariAdapter()
    private let brave = BraveAdapter()
    private let chrome = ChromeAdapter()
    
    @Published var lastActiveBrowser: String? = nil
    @Published var highlightedTabId: Int64? = nil
    
    @Published var searchText: String = ""
    
    var filteredWorkspaces: [Workspace] {
        if searchText.isEmpty {
            return workspaces
        } else {
            return workspaces.filter { workspace in
                guard let id = workspace.id, let tabs = tabsByWorkspace[id] else { return false }
                return tabs.contains { $0.title.localizedCaseInsensitiveContains(searchText) || $0.url.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    init() {
        // Ensure Database is initialized
        _ = DatabaseManager.shared
        self.dbPool = DatabaseManager.shared.dbPool
        
        // Check current frontmost app on launch
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            setLastActive(from: frontApp)
        }
        
        // Track app switches so we always know which browser was used right before clicking the menu bar
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.setLastActive(from: app)
            }
        }
        
        fetchData()
    }
    
    private func setLastActive(from app: NSRunningApplication) {
        if app.bundleIdentifier == "com.apple.Safari" {
            lastActiveBrowser = "safari"
        } else if app.bundleIdentifier == "com.brave.Browser" {
            lastActiveBrowser = "brave"
        } else if app.bundleIdentifier == "com.google.Chrome" {
            lastActiveBrowser = "chrome"
        }
    }
    
    func fetchData() {
        do {
            try dbPool.read { db in
                let fetchedWorkspaces = try Workspace.order(Column("name")).fetchAll(db)
                let allTabs = try Tab.fetchAll(db)
                
                DispatchQueue.main.async {
                    self.workspaces = fetchedWorkspaces
                    self.tabsByWorkspace = Dictionary(grouping: allTabs, by: { $0.workspaceId })
                }
            }
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    func createWorkspace(name: String) {
        guard !name.isEmpty else { return }
        do {
            try dbPool.write { db in
                let ws = Workspace(name: name)
                try ws.insert(db)
            }
            fetchData()
        } catch {
            print("Create workspace error: \(error)")
        }
    }
    
    func deleteWorkspace(_ workspace: Workspace) {
        guard workspace.id != nil else { return }
        do {
            try dbPool.write { db in
                _ = try workspace.delete(db)
            }
            fetchData()
        } catch {
            print("Delete workspace error: \(error)")
        }
    }
    
    func renameWorkspace(id: Int64, to newName: String) {
        guard !newName.isEmpty else { return }
        do {
            try DatabaseManager.shared.renameWorkspace(id: id, newName: newName)
            fetchData()
        } catch {
            print("Rename workspace error: \(error)")
        }
    }
    
    func parkActiveTab(workspaceId: Int64) {
        do {
            var activeTab: OpenTab? = nil
            var activeBrowser = ""
            
            // Prioritize the browser the user was literally just looking at
            let preferredBrowser = lastActiveBrowser ?? "safari"
            let checkOrder = [preferredBrowser] + ["safari", "brave", "chrome"].filter { $0 != preferredBrowser }
            
            for browser in checkOrder {
                if browser == "safari", let tab = try? safari.getActiveTab() {
                    activeTab = tab
                    activeBrowser = "safari"
                    break
                } else if browser == "brave", let tab = try? brave.getActiveTab() {
                    activeTab = tab
                    activeBrowser = "brave"
                    break
                } else if browser == "chrome", let tab = try? chrome.getActiveTab() {
                    activeTab = tab
                    activeBrowser = "chrome"
                    break
                }
            }
            
            guard let tab = activeTab else { return }
            
            // Duplicate Check
            if let existingTab = tabsByWorkspace[workspaceId]?.first(where: { $0.url == tab.url }) {
                DispatchQueue.main.async {
                    self.highlightedTabId = existingTab.id
                    // Auto-remove highlight after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if self.highlightedTabId == existingTab.id {
                            self.highlightedTabId = nil
                        }
                    }
                }
                
                // If the tab was previously marked as resumed, switch it back to parked
                if existingTab.status == .resumed {
                    try dbPool.write { db in
                        var updated = existingTab
                        updated.status = .parked
                        try updated.update(db)
                    }
                    fetchData()
                }
                
                return // Prevent duplication
            }
            
            try dbPool.write { db in
                var newTab = Tab(workspaceId: workspaceId, url: tab.url, title: tab.title, browser: activeBrowser)
                try newTab.insert(db)
            }
            
            // We no longer close the tab automatically per user request.
            // The user will close it manually.
            
            fetchData()
        } catch {
            print("Park error: \(error)")
        }
    }
    
    func resumeTab(_ tab: Tab) {
        do {
            if tab.browser == "safari" {
                try safari.openTab(url: tab.url)
            } else if tab.browser == "brave" {
                try brave.openTab(url: tab.url)
            } else {
                try chrome.openTab(url: tab.url)
            }
            
            try dbPool.write { db in
                var updatedTab = tab
                updatedTab.status = .resumed
                try updatedTab.update(db)
            }
            fetchData()
        } catch {
            print("Resume error: \(error)")
        }
    }
    
    func resumeWorkspace(_ workspace: Workspace) {
        guard let id = workspace.id, let tabs = tabsByWorkspace[id] else { return }
        
        let tabsToResume = searchText.isEmpty ? tabs : tabs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
        
        for tab in tabsToResume {
            resumeTab(tab)
        }
    }
    
    func deleteTab(_ tab: Tab) {
        do {
            try dbPool.write { db in
                _ = try tab.delete(db)
            }
            fetchData()
        } catch {
            print("Delete tab error: \(error)")
        }
    }
    
    func generateMarkdownExport() -> String {
        var markdown = ""
        for workspace in workspaces {
            markdown += "## \(workspace.name)\n"
            if let id = workspace.id, let tabs = tabsByWorkspace[id] {
                for tab in tabs {
                    markdown += "- [\(tab.title.isEmpty ? tab.url : tab.title)](\(tab.url))\n"
                }
            }
            markdown += "\n"
        }
        return markdown
    }
    
    func promptExport() {
        let markdown = generateMarkdownExport()
        
        // Post notification so AppDelegate can handle the export
        NotificationCenter.default.post(
            name: NSNotification.Name("TabVaultExport"),
            object: nil,
            userInfo: ["markdown": markdown]
        )
    }
}
