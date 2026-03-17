import SwiftUI

/// Spotlight-style floating search panel (⌘K).
struct QuickSearchView: View {

    @ObservedObject var viewModel: AliasViewModel
    @Binding var isPresented: Bool

    @State private var query: String = ""
    @State private var copiedID: UUID? = nil
    @FocusState private var isSearchFocused: Bool

    private var results: [AliasItem] {
        guard !query.isEmpty else {
            return Array(viewModel.aliases.prefix(12))
        }
        let q = query.lowercased()
        return viewModel.aliases.filter {
            $0.name.lowercased().contains(q)    ||
            $0.command.lowercased().contains(q) ||
            $0.comment.lowercased().contains(q) ||
            $0.tags.joined(separator: " ").lowercased().contains(q)
        }.prefix(12).map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search aliases…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($isSearchFocused)
                    .onSubmit {
                        if let first = results.first {
                            copyAlias(first)
                        }
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if !results.isEmpty {
                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { alias in
                            QuickSearchRow(
                                alias: alias,
                                isCopied: copiedID == alias.id,
                                onCopy: { copyAlias(alias) }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 320)
            } else if !query.isEmpty {
                Divider()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No aliases matching \"\(query)\"")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            }

            // Footer
            Divider()
            HStack {
                Label("Enter to copy", systemImage: "return")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Label("Esc to close", systemImage: "escape")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 520)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .onAppear {
            query = ""
            isSearchFocused = true
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }

    private func copyAlias(_ alias: AliasItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(alias.command, forType: .string)
        viewModel.recordUsage(for: alias)
        copiedID = alias.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedID == alias.id { copiedID = nil }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Row

private struct QuickSearchRow: View {
    let alias: AliasItem
    let isCopied: Bool
    let onCopy: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 12) {
                // Status dot
                Circle()
                    .fill(alias.isEnabled ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 7, height: 7)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(alias.name)
                        .font(.system(.body, design: .monospaced, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(alias.command)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Tags
                if !alias.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(alias.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundColor(.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Copy indicator
                Image(systemName: isCopied ? "checkmark" : "doc.on.clipboard")
                    .font(.caption)
                    .foregroundColor(isCopied ? .green : .secondary)
                    .frame(width: 20)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isHovered ? Color.primary.opacity(0.06) : .clear)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
