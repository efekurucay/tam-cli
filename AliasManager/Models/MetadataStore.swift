import Foundation

/// Persists alias metadata (tags, usage stats) separately from .zshrc.
/// Stored at ~/.config/alias-manager/metadata.json
final class MetadataStore: ObservableObject {

    static let shared = MetadataStore()

    // MARK: - Entry

    struct Entry: Codable {
        var tags: [String]
        var usageCount: Int
        var lastUsed: Date?

        init(tags: [String] = [], usageCount: Int = 0, lastUsed: Date? = nil) {
            self.tags = tags
            self.usageCount = usageCount
            self.lastUsed = lastUsed
        }
    }

    // MARK: - State

    @Published private(set) var store: [String: Entry] = [:]

    private let storeURL: URL

    // MARK: - Init

    init() {
        let dir = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".config/alias-manager")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appendingPathComponent("metadata.json")
        load()
    }

    // MARK: - Read

    func entry(for name: String) -> Entry {
        store[name] ?? Entry()
    }

    /// All unique tags across all aliases, sorted.
    var allTags: [String] {
        Array(Set(store.values.flatMap { $0.tags })).sorted()
    }

    // MARK: - Write

    func setTags(_ tags: [String], for name: String) {
        var e = entry(for: name)
        e.tags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        store[name] = e
        save()
    }

    func recordUsage(for name: String) {
        var e = entry(for: name)
        e.usageCount += 1
        e.lastUsed = Date()
        store[name] = e
        save()
    }

    func deleteEntry(for name: String) {
        store.removeValue(forKey: name)
        save()
    }

    func renameEntry(from oldName: String, to newName: String) {
        guard let e = store[oldName] else { return }
        store[newName] = e
        store.removeValue(forKey: oldName)
        save()
    }

    // MARK: - Sync with AliasItem arrays

    /// Merges stored metadata into the alias list (call after loading from zshrc).
    func merge(into aliases: inout [AliasItem]) {
        for i in aliases.indices {
            let e = entry(for: aliases[i].name)
            aliases[i].tags = e.tags
            aliases[i].usageCount = e.usageCount
            aliases[i].lastUsed = e.lastUsed
        }
    }

    /// Syncs tags from the alias list back to the store (call before saving).
    func syncTags(from aliases: [AliasItem]) {
        for alias in aliases {
            var e = entry(for: alias.name)
            e.tags = alias.tags
            store[alias.name] = e
        }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        store = (try? decoder.decode([String: Entry].self, from: data)) ?? [:]
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(store) {
            try? data.write(to: storeURL)
        }
    }
}
