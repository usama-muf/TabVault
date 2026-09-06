import Foundation
import AppKit

struct AppleScriptRunner {
    static func run(_ source: String) throws -> NSAppleEventDescriptor {
        guard let script = NSAppleScript(source: source) else {
            throw BrowserAdapterError.appleScriptFailed("Could not compile AppleScript")
        }
        
        var errorDict: NSDictionary? = nil
        let result = script.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            throw BrowserAdapterError.appleScriptFailed(message)
        }
        
        return result
    }
    
    static func isBrowserRunning(bundleIdentifier: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }
}
