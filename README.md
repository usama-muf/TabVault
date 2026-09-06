# Tab Vault 🔖

## The Problem
As developers, students, and researchers, we constantly suffer from "tab fatigue." We leave dozens of tabs open across multiple browsers (Chrome, Brave, Safari) because we are afraid of losing our context. Keeping these tabs open indefinitely drains Mac memory (RAM), hogs CPU cycles, and kills battery life. 

Traditional bookmark managers are too slow and clunky for temporary tasks, and heavy "read-it-later" apps break our immediate workflow. There is a missing middle ground for tabs that you don't need *right now*, but definitely need *later today*.

## The Solution
**Tab Vault** is a lightning-fast, native macOS menu bar utility designed to cure tab clutter. 

It allows you to instantly "park" your active browser tab into custom workspaces (e.g., "LeetCode", "Research", "Documentation") using a global system hotkey (`⌘⌥V`). By parking tabs, you can safely close them in your browser, saving massive amounts of system resources, while knowing they are securely stored for 1-click resumption.

### Key Features
- **Cross-Browser Intelligence:** Seamlessly detects and extracts URLs from Safari, Google Chrome, and Brave.
- **Global Hotkey:** Press `⌘⌥V` from anywhere on your Mac to instantly pop open the vault.
- **Native & Lightweight:** Built in pure Swift/SwiftUI. It consumes ~25MB of RAM, whereas a single open Chrome tab can consume 500MB+.
- **Privacy First:** 100% offline. Uses a highly optimized local SQLite database (GRDB). No tracking, no cloud syncing.
- **Auto-Start:** Integrates directly into macOS Login Items to run silently in the background on boot.
