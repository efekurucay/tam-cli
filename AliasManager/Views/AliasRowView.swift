import SwiftUI

/// A single alias row in the sidebar list.
struct AliasRowView: View {
    let alias: AliasItem
    var isDraggable: Bool = false
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Drag handle — visible only in Manual order mode
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(isDraggable ? 0.45 : 0))
                .frame(width: 14)
                .help(isDraggable ? "Drag to reorder" : "")

            // Status indicator
            Circle()
                .fill(alias.isEnabled ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 8, height: 8)

            // Alias info
            VStack(alignment: .leading, spacing: 2) {
                Text(alias.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(alias.isEnabled ? .primary : .secondary)

                Text(alias.command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Show icon if comment exists
            if !alias.comment.isEmpty {
                Image(systemName: "text.bubble")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .help(alias.comment)
            }
        }
        .padding(.vertical, 4)
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

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
