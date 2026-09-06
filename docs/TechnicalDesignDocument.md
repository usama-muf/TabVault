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

### 3.4 Data Persistence & Migration
The `DatabaseManager` manages a local SQLite database (`tabvault.sqlite`) in the user's Application Support directory using GRDB `DatabasePool`.
- **Tables:** `workspace` (ID, Name, Created At) and `parked_tab` (ID, WorkspaceID, URL, Title, Browser, Status, Created At).
- **Schema Migrations:** Database migrations safely evolve the SQLite schema (e.g. adding browser provenance tracking and status flags).
- **Cascading Constraints:** Foreign key constraints ensure that deleting a workspace automatically deletes its associated tabs.

### 3.5 Right-Click Context Menu & Clipboard Integration
To provide fast link manipulation without re-opening tabs:
- **SwiftUI `.contextMenu`:** Attached to `TabRowView` to present native macOS contextual menus on right-click.
- **NSPasteboard:** Interfacing directly with `NSPasteboard.general` to clear contents and copy plain-text string values for **Copy Link** (`tab.url`) and **Copy Title** (`tab.title`).

### 3.6 1-Click Markdown Export Engine
Tab Vault provides seamless backup and portability via an automated Markdown generator:
- **Decoupled Event Architecture:** The export trigger originates from the SwiftUI toolbar (`viewModel.promptExport()`), which generates formatted Markdown (`## Workspace \n - [Title](URL)`) and broadcasts a `TabVaultExport` notification via `NotificationCenter`.
- **AppDelegate File Writer:** `AppDelegate` listens for export notifications, closes the popover to prevent focus loss, writes the `.md` backup file atomically to `~/Desktop/TabVault_Backup_<timestamp>.md`, and presents a native `NSAlert` modal offering a 1-click "Show in Finder" action.

### 3.7 Real-Time Search & Filtering
`VaultViewModel` exposes a reactive `searchText` published property:
- **Dynamic ViewModel Filtering:** `filteredWorkspaces` dynamically filters workspaces and nested tabs matching query strings against titles and URLs using `localizedCaseInsensitiveContains`.
- **Disclosure Group Integration:** Empty workspaces during search are automatically hidden, and matching tabs are displayed in real-time.

### 3.8 Intelligent Duplicate Prevention & Highlighting
To prevent database clutter from accidental duplicate tab parking:
- **URL Deduplication:** `VaultViewModel.parkActiveTab` inspects existing tabs in the target workspace for identical URLs.
- **State & Visual Feedback:** If a duplicate exists, the app updates its status back to `.parked` if previously `.resumed`, sets `highlightedTabId` to trigger a SwiftUI accent color animation, and auto-dismisses the highlight after 1.5 seconds.

## 4. Security & App Sandbox
Tab Vault is designed to be Mac App Store (MAS) compliant. 
- **Sandbox Enabled:** The app is strictly sandboxed (`com.apple.security.app-sandbox`).
- **Apple Events Entitlements:** A sandboxed app cannot execute AppleScripts against other apps by default. We injected `com.apple.security.temporary-exception.apple-events` entitlements targeting `com.apple.Safari`, `com.google.Chrome`, and `com.brave.Browser`.
- **Desktop File Access Entitlement:** To allow 1-click Markdown exports directly to the user's Desktop without intrusive save panels, we configured `com.apple.security.temporary-exception.files.home-relative-path.read-write` for `/Desktop/`.
- **NSAppleEventsUsageDescription:** A strict privacy description is included in `Info.plist` explaining why the app requires AppleScript communication with web browsers.

## 5. Deployment & System Integration
- **XcodeGen:** Defines the entire build structure declaratively in `project.yml`, ensuring entitlements, Info.plist properties, and build targets remain perfectly reproducible.
- **Auto-Start at Login:** Integrated using macOS Ventura+ `SMAppService.mainApp.register()`, enabling automatic background launch on system boot.
- **Tooltip Responsiveness:** Configured `NSInitialToolTipDelay` to 30ms on launch for instant hover feedback throughout the UI.

## 6. Future Enhancements
- iCloud Syncing via CloudKit for cross-device tab parking.
- Browser extension counterpart for parking tabs directly within web browsers.
