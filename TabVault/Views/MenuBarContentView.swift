import SwiftUI

struct MenuBarContentView: View {
    @StateObject private var viewModel = VaultViewModel()
    @State private var newWorkspaceName = ""
    @State private var editingWorkspaceId: Int64? = nil
    @State private var editingWorkspaceName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Tab Vault").font(.headline)
                
                Text("⌘⌥V")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 8)
                
                Button(action: { 
                    viewModel.promptExport()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
                .help("Export Backup (.md)")
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            List {
                ForEach(viewModel.filteredWorkspaces) { workspace in
                    if let workspaceId = workspace.id {
                        DisclosureGroup {
                            let allTabs = viewModel.tabsByWorkspace[workspaceId] ?? []
                            let tabs = viewModel.searchText.isEmpty ? allTabs : allTabs.filter { 
                                $0.title.localizedCaseInsensitiveContains(viewModel.searchText) || 
                                $0.url.localizedCaseInsensitiveContains(viewModel.searchText) 
                            }
                            
                            HStack {
                                Button("Resume All") {
                                    viewModel.resumeWorkspace(workspace)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                
                                Spacer()
                                
                                Button("Park Active Tab Here") {
                                    viewModel.parkActiveTab(workspaceId: workspaceId)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 4)
                            
                            if tabs.isEmpty {
                                Text("No tabs parked.").font(.caption).foregroundColor(.gray)
                            }
                            
                            ForEach(tabs) { tab in
                                TabRowView(tab: tab, viewModel: viewModel)
                            }
                        } label: {
                            HStack {
                                if editingWorkspaceId == workspace.id {
                                    TextField("Workspace Name", text: $editingWorkspaceName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onSubmit {
                                            if let id = workspace.id {
                                                viewModel.renameWorkspace(id: id, to: editingWorkspaceName)
                                            }
                                            editingWorkspaceId = nil
                                        }
                                    Button("Save") {
                                        if let id = workspace.id {
                                            viewModel.renameWorkspace(id: id, to: editingWorkspaceName)
                                        }
                                        editingWorkspaceId = nil
                                    }
                                } else {
                                    Text(workspace.name).font(.headline)
                                    Spacer()
                                    if workspace.name != "Unsorted" {
                                        Button(action: {
                                            editingWorkspaceId = workspace.id
                                            editingWorkspaceName = workspace.name
                                        }) {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: { viewModel.deleteWorkspace(workspace) }) {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 350)
            
            Divider()
            
            HStack {
                TextField("New Workspace", text: $newWorkspaceName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        viewModel.createWorkspace(name: newWorkspaceName)
                        newWorkspaceName = ""
                    }
                Button("Create") {
                    viewModel.createWorkspace(name: newWorkspaceName)
                    newWorkspaceName = ""
                }
                .disabled(newWorkspaceName.isEmpty)
            }
            .padding()
        }
        .frame(width: 450)
    }
}

struct TabRowView: View {
    let tab: Tab
    @ObservedObject var viewModel: VaultViewModel
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: browserIconName(for: tab.browser))
                .foregroundColor(.secondary)
                .font(.system(size: 16))
                .frame(width: 24)
                
            VStack(alignment: .leading) {
                Text(tab.title.isEmpty ? tab.url : tab.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(tab.status == .resumed ? .gray : .primary)
                Text(tab.url)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .help("\(tab.title.isEmpty ? tab.url : tab.title)\n\(tab.url)")
            
            Spacer()
            Button(tab.status == .resumed ? "Re-open" : "Resume") {
                viewModel.resumeTab(tab)
            }
            .controlSize(.small)
            Button(action: { viewModel.deleteTab(tab) }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Delete") // Optional: Give the delete button its own specific tooltip
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            isHovered ? Color.secondary.opacity(0.15) :
            (viewModel.highlightedTabId == tab.id ? Color.accentColor.opacity(0.3) : Color.clear)
        )
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tab.url, forType: .string)
            }) {
                Label("Copy Link", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tab.title.isEmpty ? tab.url : tab.title, forType: .string)
            }) {
                Label("Copy Title", systemImage: "text.quote")
            }
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.highlightedTabId)
    }
    
    private func browserIconName(for browser: String) -> String {
        switch browser.lowercased() {
        case "safari": return "safari"
        case "brave": return "b.circle" // B for Brave
        case "chrome": return "globe" // Universal web icon for Chrome
        default: return "globe"
        }
    }
}
