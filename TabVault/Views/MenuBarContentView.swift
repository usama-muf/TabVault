import SwiftUI

struct MenuBarContentView: View {
    @StateObject private var viewModel = VaultViewModel()
    @State private var newWorkspaceName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tab Vault").font(.headline)
                
                Text("⌘⌥V")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    
                Spacer()
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            List {
                ForEach(viewModel.workspaces) { workspace in
                    if let workspaceId = workspace.id {
                        DisclosureGroup {
                            let tabs = viewModel.tabsByWorkspace[workspaceId] ?? []
                            
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
                                HStack {
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
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(viewModel.highlightedTabId == tab.id ? Color.accentColor.opacity(0.3) : Color.clear)
                                .cornerRadius(6)
                                .animation(.easeInOut(duration: 0.5), value: viewModel.highlightedTabId)
                            }
                        } label: {
                            HStack {
                                Text(workspace.name).font(.headline)
                                Spacer()
                                if workspace.name != "Unsorted" {
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
