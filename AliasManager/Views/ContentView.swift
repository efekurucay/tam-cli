import SwiftUI

/// Main app view — Finder-style NavigationSplitView interface.
struct ContentView: View {
    @StateObject private var viewModel = AliasViewModel()
    @State private var showDeleteConfirm = false
    @State private var aliasToDelete: AliasItem?

    var body: some View {
        NavigationSplitView {
            // Sidebar: Alias list
            sidebarContent
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // Detail panel
            detailContent
        }
        .navigationTitle("AliasManager")
        .searchable(text: $viewModel.searchText, prompt: "Search aliases...")
        .onAppear {
            viewModel.loadAliases()
        }
        .alert("Notice", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Delete Alias", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let alias = aliasToDelete {
                    viewModel.deleteAlias(alias)
                }
            }
        } message: {
            if let alias = aliasToDelete {
                Text("Are you sure you want to delete '\(alias.name)'?")
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddForm) {
            AliasFormView(isEditing: false) { name, command, comment in
                viewModel.addAlias(name: name, command: command, comment: comment)
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditForm) {
            if let editing = viewModel.editingAlias {
                AliasFormView(isEditing: true, existingAlias: editing) { name, command, comment in
                    viewModel.updateAlias(editing, name: name, command: command, comment: comment)
                }
            }
        }
        .toolbar {
            toolbarContent
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredAliases.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: viewModel.searchText.isEmpty ? "terminal" : "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)

                if viewModel.searchText.isEmpty {
                    Text("No aliases yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Click the + button\nto add a new alias.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("No aliases matching '\(viewModel.searchText)'.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $viewModel.selectedAlias) {
                ForEach(viewModel.filteredAliases) { alias in
                    AliasRowView(
                        alias: alias,
                        isDraggable: viewModel.sortOrder == .manual && viewModel.searchText.isEmpty,
                        onToggle: { viewModel.toggleAlias(alias) },
                        onDelete: {
                            aliasToDelete = alias
                            showDeleteConfirm = true
                        },
                        onDuplicate: { viewModel.duplicateAlias(alias) }
                    )
                    .tag(alias)
                }
                // Disable reordering while a search filter is active
                .onMove { from, to in
                    viewModel.moveAliases(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                statusBar
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if let selected = viewModel.selectedAlias {
            AliasDetailView(
                alias: selected,
                onEdit: {
                    viewModel.editingAlias = selected
                    viewModel.isShowingEditForm = true
                },
                onToggle: { viewModel.toggleAlias(selected) },
                onDelete: {
                    aliasToDelete = selected
                    showDeleteConfirm = true
                },
                onDuplicate: { viewModel.duplicateAlias(selected) }
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "arrow.left.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("Select an alias from the list")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text("\(viewModel.activeCount) active")
                .foregroundColor(.green)
            Text("·")
                .foregroundColor(.secondary)
            Text("\(viewModel.disabledCount) disabled")
                .foregroundColor(.secondary)
            Text("·")
                .foregroundColor(.secondary)
            Text("\(viewModel.aliases.count) total")
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Sort menu
            Menu {
                ForEach(AliasViewModel.SortOrder.allCases.filter { $0 != .manual }, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if viewModel.sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    viewModel.sortOrder = .manual
                } label: {
                    HStack {
                        Text("Manual Order")
                        if viewModel.sortOrder == .manual {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Image(systemName: viewModel.sortOrder == .manual ? "hand.draw" : "arrow.up.arrow.down")
            }
            .help(viewModel.sortOrder == .manual ? "Manual Order — drag rows to reorder" : "Sort")

            // Refresh
            Button {
                viewModel.loadAliases()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")
            .keyboardShortcut("r", modifiers: .command)

            // Add new alias
            Button {
                viewModel.isShowingAddForm = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Add New Alias")
            .keyboardShortcut("n", modifiers: .command)
        }

        ToolbarItemGroup(placement: .secondaryAction) {
            // Backup
            Button {
                if let path = viewModel.createBackup() {
                    viewModel.alertMessage = "Backup created: \(path)"
                    viewModel.showAlert = true
                }
            } label: {
                Label("Backup", systemImage: "externaldrive.badge.plus")
            }

            // Export JSON
            Button {
                if let data = viewModel.exportToJSON() {
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.json]
                    panel.nameFieldStringValue = "aliases.json"
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            try? data.write(to: url)
                        }
                    }
                }
            } label: {
                Label("Export JSON", systemImage: "square.and.arrow.up")
            }

            // Import JSON
            Button {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.json]
                panel.begin { response in
                    if response == .OK, let url = panel.url,
                       let data = try? Data(contentsOf: url) {
                        viewModel.importFromJSON(data)
                    }
                }
            } label: {
                Label("Import JSON", systemImage: "square.and.arrow.down")
            }
        }
    }
}

#Preview {
    ContentView()
}
