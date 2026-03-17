import SwiftUI

/// Main app view — three-pane NavigationSplitView.
struct ContentView: View {
    @StateObject private var viewModel     = AliasViewModel()
    @StateObject private var menuBar       = MenuBarController()
    @ObservedObject private var settings   = AppSettings.shared

    @State private var showDeleteConfirm  = false
    @State private var aliasToDelete: AliasItem?
    @State private var showQuickSearch    = false
    @State private var showPacksSheet     = false
    @State private var showStatsSheet     = false

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 230, ideal: 280)
        } detail: {
            detailContent
        }
        .navigationTitle("AliasManager")
        .searchable(text: $viewModel.searchText, prompt: "Search aliases…")
        .onAppear {
            viewModel.loadAliases()
            menuBar.setup(viewModel: viewModel)
        }
        // Rebuild menu bar when aliases change
        .onChange(of: viewModel.aliases) { _, _ in
            menuBar.rebuild()
        }
        // Notifications
        .onReceive(NotificationCenter.default.publisher(for: .showQuickSearch)) { _ in
            showQuickSearch = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarNeedsRebuild)) { note in
            let enabled = note.userInfo?["enabled"] as? Bool ?? true
            if enabled { menuBar.setup(viewModel: viewModel) }
            else { menuBar.remove() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAliases)) { _ in
            viewModel.loadAliases()
        }
        // Alerts
        .alert("Notice", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Delete Alias", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let alias = aliasToDelete { viewModel.deleteAlias(alias) }
            }
        } message: {
            if let alias = aliasToDelete {
                Text("Are you sure you want to delete '\(alias.name)'?")
            }
        }
        // Sheets
        .sheet(isPresented: $viewModel.isShowingAddForm) {
            AliasFormView(isEditing: false) { name, command, comment, tags in
                viewModel.addAlias(name: name, command: command, comment: comment, tags: tags)
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditForm) {
            if let editing = viewModel.editingAlias {
                AliasFormView(isEditing: true, existingAlias: editing) { name, command, comment, tags in
                    viewModel.updateAlias(editing, name: name, command: command, comment: comment, tags: tags)
                }
            }
        }
        .sheet(isPresented: $showPacksSheet) {
            AliasPacksView(viewModel: viewModel)
        }
        .sheet(isPresented: $showStatsSheet) {
            StatsView(viewModel: viewModel)
        }
        // Quick Search overlay
        .overlay {
            if showQuickSearch {
                quickSearchOverlay
            }
        }
        .toolbar { toolbarContent }
    }

    // MARK: - Quick Search Overlay

    private var quickSearchOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { showQuickSearch = false }

            QuickSearchView(viewModel: viewModel, isPresented: $showQuickSearch)
                .frame(maxWidth: 520)
                .padding(.top, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.15), value: showQuickSearch)
        .zIndex(100)
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        if viewModel.isLoading {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $viewModel.selectedAlias) {
                // All Aliases section
                allAliasesSection

                // Tag sections
                if !viewModel.availableTags.isEmpty {
                    tagSections
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) { statusBar }
        }
    }

    @ViewBuilder
    private var allAliasesSection: some View {
        let isAllSelected = viewModel.selectedTag == nil

        Section {
            if viewModel.filteredAliases.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.filteredAliases) { alias in
                    AliasRowView(
                        alias: alias,
                        isDraggable: viewModel.sortOrder == .manual && viewModel.searchText.isEmpty,
                        onToggle:    { viewModel.toggleAlias(alias) },
                        onDelete: {
                            aliasToDelete = alias
                            showDeleteConfirm = true
                        },
                        onDuplicate: { viewModel.duplicateAlias(alias) }
                    )
                    .tag(alias)
                }
                .onMove { from, to in viewModel.moveAliases(fromOffsets: from, toOffset: to) }
            }
        } header: {
            Button {
                viewModel.selectedTag = nil
            } label: {
                HStack {
                    Label("All Aliases", systemImage: "terminal")
                        .foregroundColor(isAllSelected ? .accentColor : .primary)
                    Spacer()
                    Text("\(viewModel.aliases.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var tagSections: some View {
        Section {
            ForEach(viewModel.availableTags, id: \.self) { tag in
                let count = viewModel.aliases.filter { $0.tags.contains(tag) }.count
                let isSelected = viewModel.selectedTag == tag

                Button {
                    viewModel.selectedTag = isSelected ? nil : tag
                } label: {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                            .font(.caption)
                        Text(tag)
                            .foregroundColor(isSelected ? .accentColor : .primary)
                        Spacer()
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 1)
                }
                .buttonStyle(.plain)
                .listRowBackground(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            }
        } header: {
            Text("By Tag")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.searchText.isEmpty ? "terminal" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            if viewModel.searchText.isEmpty {
                if let tag = viewModel.selectedTag {
                    Text("No aliases tagged \"\(tag)\"")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Text("No aliases yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Click + to add your first alias.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No results for \"\(viewModel.searchText)\"")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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
                onToggle:       { viewModel.toggleAlias(selected) },
                onDelete: {
                    aliasToDelete = selected
                    showDeleteConfirm = true
                },
                onDuplicate:    { viewModel.duplicateAlias(selected) },
                onRecordUsage:  { viewModel.recordUsage(for: selected) }
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
        HStack(spacing: 8) {
            if let tag = viewModel.selectedTag {
                Label(tag, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Text("·").foregroundColor(.secondary)
            }
            Text("\(viewModel.activeCount) active")
                .foregroundColor(.green)
            Text("·").foregroundColor(.secondary)
            Text("\(viewModel.disabledCount) disabled")
                .foregroundColor(.secondary)
            Text("·").foregroundColor(.secondary)
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
            // Undo
            Button {
                viewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!viewModel.canUndo)
            .help(viewModel.canUndo ? "Undo: \(viewModel.lastUndoAction)" : "Nothing to undo")
            .keyboardShortcut("z", modifiers: .command)

            // Redo
            Button {
                viewModel.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!viewModel.canRedo)
            .help("Redo")
            .keyboardShortcut("z", modifiers: [.command, .shift])

            Divider()

            // Sort menu
            Menu {
                ForEach(AliasViewModel.SortOrder.allCases.filter { $0 != .manual }, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if viewModel.sortOrder == order { Image(systemName: "checkmark") }
                        }
                    }
                }
                Divider()
                Button {
                    viewModel.sortOrder = .manual
                } label: {
                    HStack {
                        Text("Manual Order")
                        if viewModel.sortOrder == .manual { Image(systemName: "checkmark") }
                    }
                }
            } label: {
                Image(systemName: viewModel.sortOrder == .manual ? "hand.draw" : "arrow.up.arrow.down")
            }
            .help("Sort")

            // Refresh
            Button { viewModel.loadAliases() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")
            .keyboardShortcut("r", modifiers: .command)

            // Add
            Button { viewModel.isShowingAddForm = true } label: {
                Image(systemName: "plus")
            }
            .help("Add New Alias (⌘N)")
            .keyboardShortcut("n", modifiers: .command)
        }

        ToolbarItemGroup(placement: .secondaryAction) {
            // Quick Search
            Button {
                showQuickSearch = true
            } label: {
                Label("Quick Search", systemImage: "magnifyingglass")
            }
            .keyboardShortcut("k", modifiers: .command)

            // Alias Packs
            Button {
                showPacksSheet = true
            } label: {
                Label("Alias Packs", systemImage: "tray.and.arrow.down")
            }

            // Stats
            Button {
                showStatsSheet = true
            } label: {
                Label("Statistics", systemImage: "chart.bar")
            }

            Divider()

            // Backup
            Button {
                if let path = viewModel.createBackup() {
                    viewModel.alertMessage = "Backup created:\n\(path)"
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

// MARK: - Stats View (inline here for simplicity)

struct StatsView: View {
    @ObservedObject var viewModel: AliasViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Usage Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Summary cards
                    summaryCards

                    // Top used
                    topUsedSection

                    // Never used
                    unusedSection
                }
                .padding(24)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 520, height: 560)
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            statCard("\(viewModel.aliases.count)", "Total Aliases",    "terminal",        .accentColor)
            statCard("\(viewModel.activeCount)",   "Active",          "circle.fill",     .green)
            statCard("\(viewModel.topAliases(limit: 100).count)", "Used",  "chart.bar.fill", .blue)
            statCard("\(viewModel.unusedAliases.count)", "Unused",    "zzz",             .secondary)
        }
    }

    private func statCard(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var topUsedSection: some View {
        let top = viewModel.topAliases(limit: 10)
        if !top.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Most Used")
                    .font(.headline)

                ForEach(Array(top.enumerated()), id: \.element.id) { rank, alias in
                    HStack(spacing: 12) {
                        Text("\(rank + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .trailing)

                        Text(alias.name)
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .frame(width: 120, alignment: .leading)

                        // Usage bar
                        let maxCount = top.first?.usageCount ?? 1
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.accentColor.opacity(0.2))
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentColor)
                                        .frame(width: geo.size.width * CGFloat(alias.usageCount) / CGFloat(maxCount))
                                }
                        }
                        .frame(height: 6)

                        Text("\(alias.usageCount)×")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                            .frame(width: 40, alignment: .trailing)

                        if let last = alias.lastUsed {
                            Text(last.relativeString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var unusedSection: some View {
        let unused = viewModel.unusedAliases
        if !unused.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Never Used (\(unused.count))")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("These aliases have never been copied or run from AliasManager.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(unused.prefix(15)) { alias in
                    HStack {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text(alias.name)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(alias.command)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                if unused.count > 15 {
                    Text("… and \(unused.count - 15) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private extension Date {
    var relativeString: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    ContentView()
}
