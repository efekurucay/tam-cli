import SwiftUI

/// A single alias row in the sidebar list.
struct AliasRowView: View {
    let alias: AliasItem
    var isDraggable: Bool = false
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        HStack(spacing: 10) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(isDraggable ? 0.45 : 0))
                .frame(width: 14)
                .help(isDraggable ? "Drag to reorder" : "")

            // Status indicator
            Circle()
                .fill(alias.isEnabled ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 8, height: 8)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(alias.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(alias.isEnabled ? .primary : .secondary)

                Text(alias.command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Tag chips
                if settings.showTagsInRow && !alias.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(alias.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.10))
                                .foregroundColor(.accentColor)
                                .clipShape(Capsule())
                        }
                        if alias.tags.count > 3 {
                            Text("+\(alias.tags.count - 3)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 1)
                }
            }

            Spacer()

            // Trailing indicators
            HStack(spacing: 6) {
                // Usage count badge
                if alias.usageCount > 0 {
                    Text("\(alias.usageCount)")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                        .help("Used \(alias.usageCount) time(s)")
                }

                // Comment indicator
                if !alias.comment.isEmpty {
                    Image(systemName: "text.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .help(alias.comment)
                }
            }
        }
        .padding(.vertical, settings.densityMode.rowPadding)
        .opacity(alias.isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isDraggable)
        .contextMenu {
            Button {
                onToggle()
            } label: {
                Label(
                    alias.isEnabled ? "Disable" : "Enable",
                    systemImage: alias.isEnabled ? "pause.circle" : "play.circle"
                )
            }

            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(alias.command, forType: .string)
            } label: {
                Label("Copy Command", systemImage: "doc.on.clipboard")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(alias.preview, forType: .string)
            } label: {
                Label("Copy Alias Line", systemImage: "terminal")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
