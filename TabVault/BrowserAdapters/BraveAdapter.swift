import Foundation

struct BraveAdapter: BrowserAdapter {
    private let bundleId = "com.brave.Browser"
    private let appName = "Brave Browser"
    
    func getOpenTabs() throws -> [OpenTab] {
        guard AppleScriptRunner.isBrowserRunning(bundleIdentifier: bundleId) else {
            throw BrowserAdapterError.browserNotRunning
        }
        
        let script = """
        tell application "Brave Browser"
            set tabList to {}
            repeat with w in windows
                repeat with t in tabs of w
                    set end of tabList to {URL of t, title of t}
                end repeat
            end repeat
            return tabList
        end tell
        """
        
        let descriptor = try AppleScriptRunner.run(script)
        return parseTabs(from: descriptor)
    }
    
    func openTab(url: String) throws {
        let script = """
        tell application "Brave Browser"
            activate
            if (count of windows) = 0 then
                make new window
            end if
            set newTab to make new tab at end of tabs of front window
            set URL of newTab to "\(url)"
        end tell
        """
        _ = try AppleScriptRunner.run(script)
    }
    
    func closeTab(matchingUrl url: String) throws {
        guard AppleScriptRunner.isBrowserRunning(bundleIdentifier: bundleId) else {
            throw BrowserAdapterError.browserNotRunning
        }
        
        let script = """
        tell application "Brave Browser"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t is "\(url)" then
                        close t
                        return true
                    end if
                end repeat
            end repeat
            return false
        end tell
        """
        _ = try AppleScriptRunner.run(script)
    }
    
    func getActiveTab() throws -> OpenTab? {
        guard AppleScriptRunner.isBrowserRunning(bundleIdentifier: bundleId) else {
            throw BrowserAdapterError.browserNotRunning
        }
        
        let script = """
        tell application "Brave Browser"
            if (count of windows) > 0 then
                set currentTab to active tab of front window
                return {{URL of currentTab, title of currentTab}}
            end if
            return {}
        end tell
        """
        
        let descriptor = try AppleScriptRunner.run(script)
        let tabs = parseTabs(from: descriptor)
        return tabs.first
    }
    
    private func parseTabs(from descriptor: NSAppleEventDescriptor) -> [OpenTab] {
        var tabs: [OpenTab] = []
        let numberOfItems = descriptor.numberOfItems
        
        for i in 1...numberOfItems {
            guard let item = descriptor.atIndex(i) else { continue }
            
            if item.numberOfItems == 2, let url = item.atIndex(1)?.stringValue, let title = item.atIndex(2)?.stringValue {
                tabs.append(OpenTab(url: url, title: title, browser: "brave"))
            } else if item.numberOfItems > 0 {
                tabs.append(contentsOf: parseTabs(from: item))
            }
        }
        return tabs
    }
}
