# Tab Vault 🔖

![Tab Vault Preview](assets/preview.png)

## The Problem
As developers, students, and researchers, we constantly suffer from "tab fatigue." We leave dozens of tabs open across multiple browsers (Chrome, Brave, Safari) because we are afraid of losing our context. Keeping these tabs open indefinitely drains Mac memory (RAM), hogs CPU cycles, and kills battery life. 

Traditional bookmark managers are too slow and clunky for temporary tasks, and heavy "read-it-later" apps break our immediate workflow. There is a missing middle ground for tabs that you don't need *right now*, but definitely need *later today*.

## The Solution
**Tab Vault** is a lightning-fast, native macOS menu bar utility designed to cure tab clutter. 

It allows you to instantly "park" your active browser tab into custom workspaces (e.g., "LeetCode", "Research", "Documentation") using a global system hotkey (`⌘⌥V`). By parking tabs, you can safely close them in your browser, saving massive amounts of system resources, while knowing they are securely stored for 1-click resumption.

## ✨ Key Features
- **Cross-Browser Intelligence:** Seamlessly detects and extracts URLs & titles from Safari, Google Chrome, and Brave Browser.
- **Global Hotkey (`⌘⌥V`):** Press `⌘⌥V` from anywhere on your Mac to instantly pop open the vault.
- **Right-Click Context Menu:** Right-click any parked tab row to instantly **Copy Link** or **Copy Title** to your clipboard.
- **1-Click Markdown Export:** Export your entire vault as a formatted Markdown backup (`TabVault_Backup_<timestamp>.md`) straight to your Desktop with 1 click.
- **Real-Time Search:** Search across all workspaces and parked tabs by title or URL instantly.
- **Duplicate Prevention:** Intelligently detects duplicate tabs when parking and highlights existing entries.
- **Native & Lightweight:** Built in pure Swift & SwiftUI with GRDB SQLite storage. It consumes ~25MB of RAM, whereas a single open Chrome tab can consume 500MB+.
- **Auto-Start at Login:** Integrates directly into macOS Login Items via `ServiceManagement` to run silently in your menu bar on boot.

## ⚙️ System Requirements
- **OS:** macOS 13.0 (Ventura) or later.
- **Supported Browsers:** Safari, Google Chrome, Brave Browser.
- *(Note: Tab Vault uses native Apple Events to securely communicate with your browser. When you run it for the first time, macOS will ask for permission to control your browser.)*

## 🚀 How to Use
1. **Launch the App:** Open Tab Vault. You will see a small Bookmark icon appear in your Mac's top Menu Bar.
2. **Pop the Vault:** While browsing the web, press **`⌘⌥V`** (Command + Option + V) to instantly open the vault menu.
3. **Create a Workspace:** Type a category name (e.g., "LeetCode", "Reading List", "Project X") and press Enter to create a new Workspace.
4. **Park a Tab:** Click **"Park Active Tab Here"** under your desired workspace. The app will securely save the link and title.
5. **Copy Links / Titles:** Right-click any parked tab row to open the context menu and select **"Copy Link"** or **"Copy Title"**.
6. **Resume Tabs:** Whenever you are ready to pick up where you left off, open the vault and click **"Re-open"** or **"Resume All"**.
7. **Export Backup:** Click the export icon (`📤`) in the top bar to save a Markdown backup file to your Desktop.

## 🛠️ How to Build (For Developers)
This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to manage the Xcode project file.
1. Clone the repository.
2. Run `xcodegen generate` in the root directory.
3. Open `TabVault.xcodeproj` in Xcode 14+ and hit Run (`⌘R`).

## 🤖 Built with AI
This entire application was pair-programmed and built from scratch with the help of **Google Gemini** (Advanced Agentic Coding). From designing the native macOS architecture and SQLite database to writing custom AppleScript browser integrations, App Sandbox rules, and right-click context menus, Tab Vault serves as a showcase of what AI-assisted software engineering can accomplish!
