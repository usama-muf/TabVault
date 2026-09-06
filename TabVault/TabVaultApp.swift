import AppKit
import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

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
        // Make tooltips appear almost instantly (30ms) instead of the default ~1s delay
        UserDefaults.standard.set(30, forKey: "NSInitialToolTipDelay")
        
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
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        HotKeyManager.shared.action = { [weak self] in
            DispatchQueue.main.async {
                self?.showPopover()
            }
        }
        HotKeyManager.shared.register()
        
        // Listen for export requests from the ViewModel
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TabVaultExport"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let markdown = notification.userInfo?["markdown"] as? String else { return }
            self?.handleExport(markdown: markdown)
        }
    }
    
    func handleExport(markdown: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = formatter.string(from: Date())
        
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent("TabVault_Backup_\(timestamp).md")
        
        // Close the popover so the alert is visible
        popover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        do {
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            let alert = NSAlert()
            alert.messageText = "Backup Saved"
            alert.informativeText = "TabVault_Backup_\(timestamp).md has been saved to your Desktop."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Show in Finder")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    @objc func openFromMenu() {
        showPopover()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            let menu = NSMenu()
            
            let infoItem = NSMenuItem(title: "Tab Vault", action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
            
            menu.addItem(NSMenuItem.separator())
            
            menu.addItem(NSMenuItem(title: "Open Tab Vault", action: #selector(openFromMenu), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem.popUpMenu(menu)
            return
        }
        
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
