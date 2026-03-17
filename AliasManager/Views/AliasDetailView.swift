import SwiftUI

/// Detail panel for the selected alias (right side).
struct AliasDetailView: View {
    let alias: AliasItem
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onRecordUsage: () -> Void

    @State private var isCopied = false
    @State private var isRunning = false
    @State private var runResult: CommandRunner.Result? = nil
    @State private var showRunner = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    commandSection

                    if !alias.tags.isEmpty { tagsSection }
                    if !alias.comment.isEmpty { commentSection }

                    statsSection

                    if showRunner { testRunnerSection }

                    previewSection
                }
                .padding(24)
            }

            Divider()
            actionBar
        }
        .frame(minWidth: 380)
        .onChange(of: alias.id) { _, _ in
            runResult  = nil
            showRunner = false
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(alias.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)

                    statusBadge
                }
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Edit")
        }
        .padding(20)
    }

    private var statusBadge: some View {
        Text(alias.isEnabled ? "Active" : "Disabled")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                alias.isEnabled
                    ? Color.green.opacity(0.15)
                    : Color.gray.opacity(0.15)
            )
            .foregroundColor(alias.isEnabled ? .green : .secondary)
            .clipShape(Capsule())
    }

    // MARK: - Command

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Command", icon: "terminal")

            HStack(alignment: .top, spacing: 8) {
                Text(alias.command)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 6) {
                    // Copy
                    Button {
                        copyCommand()
                    } label: {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.clipboard")
                            .foregroundColor(isCopied ? .green : .secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Copy Command")

                    // Test Runner toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showRunner.toggle()
                            if !showRunner { runResult = nil }
                        }
                    } label: {
                        Image(systemName: showRunner ? "xmark.circle" : "play.circle")
                            .foregroundColor(showRunner ? .red : .secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help(showRunner ? "Close test runner" : "Test this command")
                }
            }
        }
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(alias.command, forType: .string)
        onRecordUsage()
        withAnimation { isCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isCopied = false }
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Tags", icon: "tag")

            FlowLayout(spacing: 6) {
                ForEach(alias.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Comment

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Description", icon: "text.bubble")
            Text(alias.comment)
                .font(.body)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(
                value: "\(alias.usageCount)",
                label: "Times used",
                icon: "chart.bar.fill",
                color: alias.usageCount > 0 ? .accentColor : .secondary
            )

            if let lastUsed = alias.lastUsed {
                statCard(
                    value: lastUsed.relativeString,
                    label: "Last used",
                    icon: "clock.fill",
                    color: .secondary
                )
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.callout)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Test Runner

    private var testRunnerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Test Runner", icon: "play.fill")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Runs the command in a zsh subprocess")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        runCommand()
                    } label: {
                        if isRunning {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 60)
                        } else {
                            Label("Run", systemImage: "play.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(isRunning)
                }

                if let result = runResult {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: result.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.succeeded ? .green : .red)
                                .font(.caption)
                            Text("Exit \(result.exitCode)")
                                .font(.caption)
                                .foregroundColor(result.succeeded ? .green : .red)
                        }

                        if !result.output.isEmpty {
                            Text(result.output)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .lineLimit(20)
                        }

                        if !result.errorOutput.isEmpty {
                            Text(result.errorOutput)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.red)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .lineLimit(10)
                        }

                        if result.output.isEmpty && result.errorOutput.isEmpty {
                            Text("(no output)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func runCommand() {
        isRunning = true
        runResult = nil
        onRecordUsage()
        Task {
            let result = await CommandRunner.runDirect(alias.command)
            await MainActor.run {
                isRunning = false
                withAnimation { runResult = result }
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(".zshrc Output", icon: "doc.text")
            Text(alias.zshrcLine)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
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

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(16)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

// MARK: - Date Extension

private extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
