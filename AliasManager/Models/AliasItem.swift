import Foundation

/// Represents a single terminal alias.
/// Example: alias gs='git status'
struct AliasItem: Identifiable, Hashable, Codable {

    let id: UUID
    var name: String       // e.g. "gs"
    var command: String    // e.g. "git status"
    var isEnabled: Bool    // whether the alias is active
    var comment: String    // optional description

    // MARK: - Metadata (persisted via MetadataStore, not in .zshrc)
    var tags: [String]     // e.g. ["git", "workflow"]
    var usageCount: Int    // number of times used from the app
    var lastUsed: Date?    // last used date

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        isEnabled: Bool = true,
        comment: String = "",
        tags: [String] = [],
        usageCount: Int = 0,
        lastUsed: Date? = nil
    ) {
        self.id         = id
        self.name       = name
        self.command    = command
        self.isEnabled  = isEnabled
        self.comment    = comment
        self.tags       = tags
        self.usageCount = usageCount
        self.lastUsed   = lastUsed
    }

    // MARK: - Hashable (identity by id)

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AliasItem, rhs: AliasItem) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - .zshrc serialization

    /// Returns the line(s) to be written to .zshrc.
    var zshrcLine: String {
        var lines: [String] = []
        if !comment.isEmpty {
            lines.append("# \(comment)")
        }
        let escapedCommand = command.replacingOccurrences(of: "'", with: "'\\''")
        if isEnabled {
            lines.append("alias \(name)='\(escapedCommand)'")
        } else {
            lines.append("# alias \(name)='\(escapedCommand)'")
        }
        return lines.joined(separator: "\n")
    }

    /// One-line alias preview string.
    var preview: String {
        "alias \(name)='\(command)'"
    }
}
