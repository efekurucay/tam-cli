import SwiftUI

/// Alias Pack template browser — import pre-built alias collections.
struct AliasPacksView: View {

    @ObservedObject var viewModel: AliasViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPack: AliasPack? = nil
    @State private var importedPacks: Set<String> = []
    @State private var resultMessage: String = ""
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alias Packs")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Import pre-built alias collections with one click.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
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

            HSplitView {
                // Pack list
                packList
                    .frame(minWidth: 180, maxWidth: 200)

                // Pack detail
                if let pack = selectedPack {
                    packDetail(pack)
                } else {
                    Text("Select a pack to preview")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            Divider()

            // Footer
            HStack {
                if showResult {
                    Label(resultMessage, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.callout)
                        .transition(.opacity)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
            .animation(.easeInOut(duration: 0.3), value: showResult)
        }
        .frame(width: 680, height: 500)
    }

    // MARK: - Pack List

    private var packList: some View {
        List(AliasPack.allPacks, selection: $selectedPack) { pack in
            HStack(spacing: 10) {
                Text(pack.emoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(.headline)
                    Text("\(pack.aliases.count) aliases")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if importedPacks.contains(pack.name) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            .tag(pack as AliasPack?)
        }
        .listStyle(.sidebar)
        .onAppear {
            selectedPack = AliasPack.allPacks.first
        }
    }

    // MARK: - Pack Detail

    private func packDetail(_ pack: AliasPack) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pack header
            HStack(spacing: 14) {
                Text(pack.emoji)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(pack.description)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Spacer()

                importButton(pack)
            }
            .padding(20)

            Divider()

            // Alias list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(pack.aliases) { alias in
                        aliasPreviewRow(alias)
                        Divider().opacity(0.5)
                    }
                }
            }
        }
    }

    private func aliasPreviewRow(_ alias: AliasItem) -> some View {
        let alreadyExists = viewModel.aliases.contains(where: { $0.name == alias.name })
        return HStack(spacing: 12) {
            Circle()
                .fill(alreadyExists ? Color.orange.opacity(0.7) : Color.green.opacity(0.7))
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(alias.name)
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundColor(alreadyExists ? .secondary : .primary)
                Text(alias.command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if alreadyExists {
                Text("exists")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .opacity(alreadyExists ? 0.6 : 1.0)
    }

    private func importButton(_ pack: AliasPack) -> some View {
        let alreadyImported = importedPacks.contains(pack.name)
        let willAdd = pack.aliases.filter { alias in
            !viewModel.aliases.contains(where: { $0.name == alias.name })
        }.count

        return Button {
            let result = viewModel.importPack(pack)
            importedPacks.insert(pack.name)
            resultMessage = "\(result.added) alias(es) imported from \(pack.name). \(result.skipped) skipped."
            showResult = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                showResult = false
            }
        } label: {
            Label(
                alreadyImported ? "Imported ✓" : "Import \(willAdd > 0 ? "(\(willAdd))" : "(all exist)")",
                systemImage: alreadyImported ? "checkmark" : "square.and.arrow.down"
            )
        }
        .buttonStyle(.borderedProminent)
        .disabled(willAdd == 0)
        .tint(alreadyImported ? .green : .accentColor)
    }
}
