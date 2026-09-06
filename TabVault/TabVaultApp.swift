import AppKit
import SwiftUI
import ServiceManagement

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Automatically register to start at login
        if SMAppService.mainApp.status == .notRegistered {
            try? SMAppService.mainApp.register()
        }
        
        let contentView = MenuBarContentView()
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 450, height: 450)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bookmark", accessibilityDescription: "Tab Vault")
            button.action = #selector(togglePopover(_:))
        }
        
        HotKeyManager.shared.action = { [weak self] in
            DispatchQueue.main.async {
                self?.showPopover()
            }
        }
        HotKeyManager.shared.register()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
