import Foundation
import SwiftUI

/// ViewModel managing the alias list business logic.
@MainActor
final class AliasViewModel: ObservableObject {

    // MARK: - Published Properties

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

    // MARK: - Enums

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case command = "Command"
        case status = "Status"
        case manual = "Manual"
    }

    // MARK: - Private

    private let service: ZshrcService

    // MARK: - Computed

    /// Filtered and sorted alias list
    var filteredAliases: [AliasItem] {
        var result = aliases

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { alias in
                alias.name.lowercased().contains(query) ||
                alias.command.lowercased().contains(query) ||
                alias.comment.lowercased().contains(query)
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
        case .manual:
            break // preserve insertion order in aliases array
        }

        return result
    }

    /// Number of active aliases
    var activeCount: Int {
        aliases.filter(\.isEnabled).count
    }

    /// Number of disabled aliases
    var disabledCount: Int {
        aliases.filter { !$0.isEnabled }.count
    }

    // MARK: - Init

    init(service: ZshrcService = ZshrcService()) {
        self.service = service
    }

    // MARK: - CRUD Operations

    /// Loads aliases from .zshrc.
    func loadAliases() {
        isLoading = true
        do {
            aliases = try service.loadAliases()
        } catch {
            showError("Failed to load aliases: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Saves aliases to .zshrc.
    func saveAliases() {
        do {
            try service.saveAliases(aliases)
            service.sourceZshrc()
        } catch {
            showError("Failed to save aliases: \(error.localizedDescription)")
        }
    }

    /// Adds a new alias.
    func addAlias(name: String, command: String, comment: String = "") {
        guard !name.isEmpty else {
            showError("Alias name cannot be empty.")
            return
        }

        guard !command.isEmpty else {
            showError("Command cannot be empty.")
            return
        }

        // Check for duplicate name
        if aliases.contains(where: { $0.name == name }) {
            showError("An alias named '\(name)' already exists.")
            return
        }

        // Validate alias name characters
        let validNamePattern = #"^[a-zA-Z_][a-zA-Z0-9_-]*$"#
        guard name.range(of: validNamePattern, options: .regularExpression) != nil else {
            showError("Alias name can only contain letters, numbers, underscores, and hyphens.")
            return
        }

        let newAlias = AliasItem(
            name: name,
            command: command,
            isEnabled: true,
            comment: comment
        )

        aliases.append(newAlias)
        saveAliases()
        selectedAlias = newAlias
    }

    /// Updates an existing alias.
    func updateAlias(_ alias: AliasItem, name: String, command: String, comment: String) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }

        // Check if the new name conflicts with another alias
        if name != alias.name && aliases.contains(where: { $0.name == name }) {
            showError("An alias named '\(name)' already exists.")
            return
        }

        aliases[index].name = name
        aliases[index].command = command
        aliases[index].comment = comment
        saveAliases()

        // Update selection
        if selectedAlias?.id == alias.id {
            selectedAlias = aliases[index]
        }
    }

    /// Deletes an alias.
    func deleteAlias(_ alias: AliasItem) {
        aliases.removeAll { $0.id == alias.id }
        if selectedAlias?.id == alias.id {
            selectedAlias = nil
        }
        saveAliases()
    }

    /// Deletes multiple aliases.
    func deleteAliases(_ aliasIDs: Set<UUID>) {
        aliases.removeAll { aliasIDs.contains($0.id) }
        if let sel = selectedAlias, aliasIDs.contains(sel.id) {
            selectedAlias = nil
        }
        saveAliases()
    }

    /// Toggles an alias between enabled and disabled.
    func toggleAlias(_ alias: AliasItem) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }
        aliases[index].isEnabled.toggle()
        saveAliases()

        if selectedAlias?.id == alias.id {
            selectedAlias = aliases[index]
        }
    }

    /// Duplicates an alias.
    func duplicateAlias(_ alias: AliasItem) {
        var newName = alias.name + "_copy"
        var counter = 1
        while aliases.contains(where: { $0.name == newName }) {
            counter += 1
            newName = alias.name + "_copy\(counter)"
        }

        let duplicate = AliasItem(
            name: newName,
            command: alias.command,
            isEnabled: alias.isEnabled,
            comment: alias.comment
        )

        aliases.append(duplicate)
        saveAliases()
        selectedAlias = duplicate
    }

    /// Moves aliases for drag & drop reordering.
    /// Works correctly regardless of the current sort mode or active search filter.
    func moveAliases(fromOffsets: IndexSet, toOffset: Int) {
        // Capture the current displayed list before we mutate anything
        let filtered = filteredAliases

        // Items being moved (in their original order)
        let movingItems = fromOffsets.sorted().map { filtered[$0] }

        // Remaining items in the filtered display order (not being moved)
        let remainingFiltered = filtered.indices
            .filter { !fromOffsets.contains($0) }
            .map { filtered[$0] }

        // Where to insert in the remaining list
        // toOffset counts positions in the original filtered array, so we
        // subtract how many "from" indices are before it.
        let destInRemaining = toOffset - fromOffsets.filter { $0 < toOffset }.count

        // Rebuild the full aliases array:
        // 1. Remove moved items
        let movingIDs = Set(movingItems.map(\.id))
        var newAliases = aliases.filter { !movingIDs.contains($0.id) }

        // 2. Find the insertion point using the anchor item
        let insertionIndex: Int
        if destInRemaining < remainingFiltered.count {
            let anchor = remainingFiltered[destInRemaining]
            insertionIndex = newAliases.firstIndex(where: { $0.id == anchor.id }) ?? newAliases.count
        } else {
            insertionIndex = newAliases.count
        }

        // 3. Insert moved items at the right position
        newAliases.insert(contentsOf: movingItems, at: insertionIndex)

        // Switch to manual order so the custom order is preserved
        sortOrder = .manual
        aliases = newAliases
        saveAliases()
    }

    // MARK: - Backup

    /// Creates a .zshrc backup.
    func createBackup() -> String? {
        do {
            let path = try service.createBackup()
            return path
        } catch {
            showError("Failed to create backup: \(error.localizedDescription)")
            return nil
        }
    }

    /// Restores from a backup.
    func restoreFromBackup(_ path: String) {
        do {
            try service.restoreFromBackup(path)
            loadAliases()
        } catch {
            showError("Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Export / Import

    /// Exports aliases as JSON.
    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(aliases)
    }

    /// Imports aliases from JSON.
    func importFromJSON(_ data: Data) {
        let decoder = JSONDecoder()
        guard let imported = try? decoder.decode([AliasItem].self, from: data) else {
            showError("Failed to read JSON file.")
            return
        }

        // Skip aliases with conflicting names
        var added = 0
        for alias in imported {
            if !aliases.contains(where: { $0.name == alias.name }) {
                aliases.append(alias)
                added += 1
            }
        }

        if added > 0 {
            saveAliases()
        }

        showInfo("\(added) alias(es) imported. \(imported.count - added) skipped (already exist).")
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func showInfo(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
