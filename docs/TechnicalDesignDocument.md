# Tab Vault: Technical Design Document (TDD)

## 1. Overview
Tab Vault is a macOS menu bar application designed to extract the active URL and Title from modern web browsers and securely store them in categorized local workspaces. It bridges the gap between transient active tabs and permanent bookmarks.

## 2. Architecture & Tech Stack Thought Process
When designing Tab Vault, the core constraint was **resource efficiency**.

- **Why Native Swift/AppKit vs Electron?**
  Many modern desktop apps use Electron (embedding Chromium). An Electron app simply listening for a hotkey would consume 150MB - 300MB of RAM. Because Tab Vault's entire value proposition is *saving* memory by closing tabs, building it in Electron would defeat the purpose. We chose 100% native Swift, SwiftUI, and AppKit, keeping the idle footprint under 25MB.
- **Why SQLite (GRDB) vs CoreData?**
  While CoreData is Apple's first-party ORM, it is notoriously heavy and complex for simple relational storage. GRDB provides direct, safe, and thread-safe access to raw SQLite, which is hyper-optimized for performance, guarantees thread-safety via `DatabasePool`, and keeps the application footprint incredibly light.

## 3. Core Components

### 3.1 App Entry & UI Layer (AppKit + SwiftUI)
Originally, the app utilized SwiftUI's `MenuBarExtra`. However, `MenuBarExtra` does not expose an API to programmatically force the menu to open. Because a core requirement was opening the menu via a global hotkey, the architecture was refactored:
- **`AppDelegate`:** Acts as the primary entry point.
- **`NSStatusItem` & `NSPopover`:** We construct a native Mac status item and attach a custom popover. This allows us to call `popover.show(relativeTo:)` programmatically whenever the hotkey is triggered.
- **`SwiftUI`:** Used inside an `NSHostingController` to render the popover UI rapidly and reactively.

### 3.2 Global Hotkey Manager (Carbon)
macOS restricts global event listening (`NSEvent.addGlobalMonitorForEvents`) to apps that have explicitly been granted Accessibility permissions by the user—a high friction request. 
To bypass this friction while remaining completely secure and Sandboxed, we utilized the legacy C-based **Carbon framework (`HIToolbox`)**.
- **`RegisterEventHotKey`:** Binds `⌘⌥V` (Command + Option + V) at the OS level. It routes the C-level callback back to Swift, triggering the UI popover without requiring any Accessibility permissions.

### 3.3 Browser Integrations (AppleScript & NSWorkspace)
To fetch the current URL and Title from a browser, the app uses Apple Events (AppleScript).
- **Target Browsers:** Safari, Google Chrome, Brave Browser.
- **State Tracking (`NSWorkspace`):** A user might have Safari open on one monitor, but Tab Vault open on another. To prevent Tab Vault from grabbing tabs from a minimized browser, we observe `NSWorkspace.didActivateApplicationNotification`. The app temporarily caches the bundle ID of the last active browser, ensuring we always extract from the user's *actual* active context.

### 3.4 Data Persistence
The `DatabaseManager` manages a local SQLite file (`tabvault.sqlite`) in the user's Application Support directory.
- **Tables:** `workspace` (ID, Name, Created At) and `parked_tab` (ID, WorkspaceID, URL, Title, Created At).
- **Constraints:** Foreign key cascading ensures that deleting a workspace automatically wipes its associated tabs.

## 4. Security & App Sandbox
Tab Vault is designed to be Mac App Store (MAS) compliant. 
- **Sandbox Enabled:** The app is strictly sandboxed.
- **Apple Events Entitlements:** A sandboxed app cannot execute AppleScripts against other apps by default. We specifically injected the `com.apple.security.temporary-exception.apple-events` entitlement into the build process (`project.yml`). We explicitly declared `com.apple.Safari`, `com.google.Chrome`, and `com.brave.Browser` as the only permitted targets.
- **NSAppleEventsUsageDescription:** A strict privacy description is injected into `Info.plist` explaining *why* the app needs to talk to the browser (to securely park tabs).

## 5. Deployment & System Integration
- **XcodeGen:** We bypassed Xcode's brittle GUI project files (`.xcodeproj`) by defining the entire build structure declaratively in `project.yml`. This ensures entitlements and plists are perfectly reproducible.
- **Auto-start:** To ensure the app is always available, we designed it to automatically launch on system boot. During development, we tested `SMAppService`, but ultimately relied on explicit Login Item injection to guarantee the service initializes correctly for the local user without requiring code-signing loop-holes. 

## 6. Future Enhancements
- iCloud Syncing via CloudKit for cross-device tab parking.
- Safari Extension counterpart to allow parking directly from a browser context menu.
