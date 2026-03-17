import Foundation
import SwiftUI

/// ViewModel managing the alias list, undo/redo, tag filtering, and usage stats.
@MainActor
final class AliasViewModel: ObservableObject {

    // MARK: - Published State

    @Published var aliases: [AliasItem] = []
    @Published var searchText: String = ""
    @Published var selectedAlias: AliasItem?
    @Published var isShowingAddForm: Bool = false
    @Published var isShowingEditForm: Bool = false
    @Published var editingAlias: AliasItem?
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var sortOrder: SortOrder = .name
    @Published var isLoading: Bool = false
    @Published var selectedTag: String? = nil   // nil = all aliases

    // MARK: - Undo / Redo

    private struct HistoryEntry {
        let action: String
        let aliases: [AliasItem]
    }

    private var undoStack: [HistoryEntry] = []
    private var redoStack: [HistoryEntry] = []

    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    @Published var lastUndoAction: String = ""

    // MARK: - Enums

    enum SortOrder: String, CaseIterable {
        case name    = "Name"
        case command = "Command"
        case status  = "Status"
        case usage   = "Most Used"
        case recent  = "Recently Used"
        case manual  = "Manual"
    }

    // MARK: - Dependencies

    private let service: ZshrcService
    private let metadata = MetadataStore.shared

    // MARK: - Init

    init(service: ZshrcService = ZshrcService()) {
        self.service = service
    }

    // MARK: - Computed: Filtering + Sorting

    /// Tags derived from current alias list (for sidebar).
    var availableTags: [String] {
        let tags = aliases.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }

    /// Aliases filtered by active tag and search text, then sorted.
    var filteredAliases: [AliasItem] {
        var result = aliases

        // Tag filter
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { alias in
                alias.name.lowercased().contains(query) ||
                alias.command.lowercased().contains(query) ||
                alias.comment.lowercased().contains(query) ||
                alias.tags.joined(separator: " ").lowercased().contains(query)
            }
        }

        // Sort
        switch sortOrder {
        case .name:
            result.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .command:
            result.sort { $0.command.lowercased() < $1.command.lowercased() }
        case .status:
            result.sort { ($0.isEnabled ? 0 : 1) < ($1.isEnabled ? 0 : 1) }
        case .usage:
            result.sort { $0.usageCount > $1.usageCount }
        case .recent:
            result.sort {
                ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast)
            }
        case .manual:
            break
        }

        return result
    }

    var activeCount: Int   { aliases.filter(\.isEnabled).count }
    var disabledCount: Int { aliases.filter { !$0.isEnabled }.count }

    /// Top-used aliases for Menu Bar and Stats (up to N).
    func topAliases(limit: Int = 10) -> [AliasItem] {
        aliases
            .filter { $0.usageCount > 0 }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(limit)
            .map { $0 }
    }

    /// Aliases never used from the app.
    var unusedAliases: [AliasItem] {
        aliases.filter { $0.usageCount == 0 }
    }

    // MARK: - Load / Save

    func loadAliases() {
        isLoading = true
        do {
            var loaded = try service.loadAliases()
            metadata.merge(into: &loaded)
            aliases = loaded
        } catch {
            showError("Failed to load aliases: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func saveAliases() {
        metadata.syncTags(from: aliases)
        do {
            try service.saveAliases(aliases)
            service.sourceZshrc()
        } catch {
            showError("Failed to save aliases: \(error.localizedDescription)")
        }
    }

    // MARK: - Undo / Redo Support

    private func pushUndo(action: String) {
        undoStack.append(HistoryEntry(action: action, aliases: aliases))
        redoStack.removeAll()
        refreshUndoState()
    }

    private func refreshUndoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        lastUndoAction = undoStack.last?.action ?? ""
    }

    func undo() {
        guard let entry = undoStack.popLast() else { return }
        redoStack.append(HistoryEntry(action: entry.action, aliases: aliases))
        aliases = entry.aliases
        saveAliases()
        refreshUndoState()
        // Fix selection if needed
        if let sel = selectedAlias, !aliases.contains(where: { $0.id == sel.id }) {
            selectedAlias = nil
        }
    }

    func redo() {
        guard let entry = redoStack.popLast() else { return }
        undoStack.append(HistoryEntry(action: entry.action, aliases: aliases))
        aliases = entry.aliases
        saveAliases()
        refreshUndoState()
    }

    // MARK: - CRUD

    func addAlias(name: String, command: String, comment: String = "", tags: [String] = []) {
        guard !name.isEmpty else { showError("Alias name cannot be empty."); return }
        guard !command.isEmpty else { showError("Command cannot be empty."); return }

        if aliases.contains(where: { $0.name == name }) {
            showError("An alias named '\(name)' already exists.")
            return
        }

        let validNamePattern = #"^[a-zA-Z_][a-zA-Z0-9_-]*$"#
        guard name.range(of: validNamePattern, options: .regularExpression) != nil else {
            showError("Alias name can only contain letters, numbers, underscores, and hyphens.")
            return
        }

        pushUndo(action: "Add '\(name)'")
        let newAlias = AliasItem(name: name, command: command, isEnabled: true, comment: comment, tags: tags)
        aliases.append(newAlias)
        saveAliases()
        selectedAlias = newAlias
    }

    func updateAlias(_ alias: AliasItem, name: String, command: String, comment: String, tags: [String] = []) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }

        if name != alias.name && aliases.contains(where: { $0.name == name }) {
            showError("An alias named '\(name)' already exists.")
            return
        }

        pushUndo(action: "Edit '\(alias.name)'")
        aliases[index].name    = name
        aliases[index].command = command
        aliases[index].comment = comment
        aliases[index].tags    = tags
        saveAliases()

        if selectedAlias?.id == alias.id {
            selectedAlias = aliases[index]
        }
    }

    func deleteAlias(_ alias: AliasItem) {
        pushUndo(action: "Delete '\(alias.name)'")
        aliases.removeAll { $0.id == alias.id }
        metadata.deleteEntry(for: alias.name)
        if selectedAlias?.id == alias.id { selectedAlias = nil }
        saveAliases()
    }

    func deleteAliases(_ aliasIDs: Set<UUID>) {
        let names = aliases.filter { aliasIDs.contains($0.id) }.map(\.name)
        pushUndo(action: "Delete \(aliasIDs.count) alias(es)")
        aliases.removeAll { aliasIDs.contains($0.id) }
        names.forEach { metadata.deleteEntry(for: $0) }
        if let sel = selectedAlias, aliasIDs.contains(sel.id) { selectedAlias = nil }
        saveAliases()
    }

    func toggleAlias(_ alias: AliasItem) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }
        pushUndo(action: "\(aliases[index].isEnabled ? "Disable" : "Enable") '\(alias.name)'")
        aliases[index].isEnabled.toggle()
        saveAliases()
        if selectedAlias?.id == alias.id { selectedAlias = aliases[index] }
    }

    func duplicateAlias(_ alias: AliasItem) {
        var newName = alias.name + "_copy"
        var counter = 1
        while aliases.contains(where: { $0.name == newName }) {
            counter += 1
            newName = "\(alias.name)_copy\(counter)"
        }
        pushUndo(action: "Duplicate '\(alias.name)'")
        let duplicate = AliasItem(
            name: newName, command: alias.command,
            isEnabled: alias.isEnabled, comment: alias.comment,
            tags: alias.tags
        )
        aliases.append(duplicate)
        saveAliases()
        selectedAlias = duplicate
    }

    // MARK: - Tag Operations

    func setTags(_ tags: [String], for alias: AliasItem) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }
        aliases[index].tags = tags
        saveAliases()
        if selectedAlias?.id == alias.id { selectedAlias = aliases[index] }
    }

    func addTagToAll(_ tag: String, matching filter: (AliasItem) -> Bool) {
        pushUndo(action: "Tag all as '\(tag)'")
        for i in aliases.indices where filter(aliases[i]) {
            if !aliases[i].tags.contains(tag) {
                aliases[i].tags.append(tag)
            }
        }
        saveAliases()
    }

    // MARK: - Usage Stats

    func recordUsage(for alias: AliasItem) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }
        aliases[index].usageCount += 1
        aliases[index].lastUsed   = Date()
        metadata.recordUsage(for: alias.name)
        // No undo for usage recording
        if selectedAlias?.id == alias.id { selectedAlias = aliases[index] }
    }

    // MARK: - Reorder

    func moveAliases(fromOffsets: IndexSet, toOffset: Int) {
        let filtered       = filteredAliases
        let movingItems    = fromOffsets.sorted().map { filtered[$0] }
        let remainingFiltered = filtered.indices
            .filter { !fromOffsets.contains($0) }
            .map { filtered[$0] }

        let destInRemaining = toOffset - fromOffsets.filter { $0 < toOffset }.count
        let movingIDs       = Set(movingItems.map(\.id))
        var newAliases      = aliases.filter { !movingIDs.contains($0.id) }

        let insertionIndex: Int
        if destInRemaining < remainingFiltered.count {
            let anchor = remainingFiltered[destInRemaining]
            insertionIndex = newAliases.firstIndex(where: { $0.id == anchor.id }) ?? newAliases.count
        } else {
            insertionIndex = newAliases.count
        }

        newAliases.insert(contentsOf: movingItems, at: insertionIndex)
        sortOrder = .manual
        aliases   = newAliases
        saveAliases()
    }

    // MARK: - Backup

    func createBackup() -> String? {
        do {
            return try service.createBackup()
        } catch {
            showError("Failed to create backup: \(error.localizedDescription)")
            return nil
        }
    }

    func restoreFromBackup(_ path: String) {
        do {
            try service.restoreFromBackup(path)
            loadAliases()
        } catch {
            showError("Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Export / Import

    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting    = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(aliases)
    }

    func importFromJSON(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let imported = try? decoder.decode([AliasItem].self, from: data) else {
            showError("Failed to read JSON file.")
            return
        }

        pushUndo(action: "Import \(imported.count) alias(es)")
        var added = 0
        for alias in imported {
            if !aliases.contains(where: { $0.name == alias.name }) {
                aliases.append(alias)
                added += 1
            }
        }
        if added > 0 { saveAliases() }
        showInfo("\(added) alias(es) imported. \(imported.count - added) skipped (already exist).")
    }

    // MARK: - Alias Pack Import

    func importPack(_ pack: AliasPack) -> (added: Int, skipped: Int) {
        pushUndo(action: "Import '\(pack.name)' pack")
        var added   = 0
        var skipped = 0
        for alias in pack.aliases {
            if !aliases.contains(where: { $0.name == alias.name }) {
                aliases.append(alias)
                added += 1
            } else {
                skipped += 1
            }
        }
        if added > 0 { saveAliases() }
        return (added, skipped)
    }

    // MARK: - Helpers

    func showError(_ message: String) {
        alertMessage = message
        showAlert    = true
    }

    private func showInfo(_ message: String) {
        alertMessage = message
        showAlert    = true
    }
}
