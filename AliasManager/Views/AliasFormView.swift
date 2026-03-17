import SwiftUI

/// Form for adding and editing aliases (with tag picker and syntax preview).
struct AliasFormView: View {
    @Environment(\.dismiss) private var dismiss

    let isEditing: Bool
    let existingAlias: AliasItem?
    let onSave: (String, String, String, [String]) -> Void

    @State private var name: String = ""
    @State private var command: String = ""
    @State private var comment: String = ""
    @State private var tags: [String] = []
    @State private var tagInput: String = ""
    @State private var showValidation: Bool = false

    private let metadata = MetadataStore.shared

    init(
        isEditing: Bool = false,
        existingAlias: AliasItem? = nil,
        onSave: @escaping (String, String, String, [String]) -> Void
    ) {
        self.isEditing     = isEditing
        self.existingAlias = existingAlias
        self.onSave        = onSave

        if let alias = existingAlias {
            _name    = State(initialValue: alias.name)
            _command = State(initialValue: alias.command)
            _comment = State(initialValue: alias.comment)
            _tags    = State(initialValue: alias.tags)
        }
    }

    // MARK: - Validation

    private var isNameValid: Bool {
        let pattern = #"^[a-zA-Z_][a-zA-Z0-9_-]*$"#
        return !name.isEmpty && name.range(of: pattern, options: .regularExpression) != nil
    }

    private var isCommandValid: Bool {
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isFormValid: Bool { isNameValid && isCommandValid }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text(isEditing ? "Edit Alias" : "New Alias")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // Form fields
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Alias Name
                    fieldGroup(label: "Alias Name") {
                        TextField("gs, ll, dev...", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .disabled(isEditing)
                            .opacity(isEditing ? 0.7 : 1.0)

                        if showValidation && !isNameValid {
                            validationError("Enter a valid alias name (letters, numbers, _, -)")
                        }
                        if isEditing {
                            hint("Alias name cannot be changed after creation.")
                        }
                    }

                    // Command
                    fieldGroup(label: "Command") {
                        SyntaxHighlightedTextField(text: $command)
                            .frame(height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )

                        if showValidation && !isCommandValid {
                            validationError("Command cannot be empty.")
                        }
                    }

                    // Description
                    fieldGroup(label: "Description (optional)") {
                        TextField("What does this alias do?", text: $comment)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Tags
                    fieldGroup(label: "Tags (optional)") {
                        tagEditor
                    }

                    // Preview
                    if !name.isEmpty && !command.isEmpty {
                        previewSection
                    }
                }
                .padding(20)
            }

            Divider()

            // Buttons
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? "Save" : "Add") {
                    showValidation = true
                    if isFormValid {
                        onSave(name, command, comment, tags)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 440, height: 560)
    }

    // MARK: - Tag Editor

    private var tagEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing tags
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)
                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                    }
                }
            }

            // Tag input
            HStack {
                TextField("Add tag… (press Enter)", text: $tagInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addTag() }

                Button("Add") { addTag() }
                    .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Suggested tags from existing aliases
            let suggestions = suggestedTags
            if !suggestions.isEmpty {
                HStack(spacing: 6) {
                    Text("Suggestions:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    FlowLayout(spacing: 4) {
                        ForEach(suggestions, id: \.self) { tag in
                            Button(tag) {
                                if !tags.contains(tag) { tags.append(tag) }
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var suggestedTags: [String] {
        metadata.allTags.filter { !tags.contains($0) }.prefix(6).map { $0 }
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else {
            tagInput = ""
            return
        }
        tags.append(trimmed)
        tagInput = ""
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("alias \(name)='\(command)'")
                .font(.system(.caption, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Helpers

    private func fieldGroup<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            content()
        }
    }

    private func validationError(_ msg: String) -> some View {
        Text(msg).font(.caption).foregroundColor(.red)
    }

    private func hint(_ msg: String) -> some View {
        Text(msg).font(.caption).foregroundColor(.secondary)
    }
}

// MARK: - FlowLayout

/// Simple horizontal flow layout that wraps to next line.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Syntax Highlighted TextField

/// NSTextView wrapper that syntax-highlights shell command tokens.
struct SyntaxHighlightedTextField: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled  = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground  = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            applyHighlighting(to: textView)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func applyHighlighting(to textView: NSTextView) {
        let str = textView.string
        let storage = textView.textStorage!
        let full    = NSRange(str.startIndex..., in: str)

        storage.beginEditing()

        // Reset
        let base = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        storage.addAttribute(.font,            value: base,                range: full)
        storage.addAttribute(.foregroundColor, value: NSColor.labelColor,  range: full)

        // Pipes and semicolons — orange
        highlight(storage, str, pattern: #"(\||;|&&|\|\|)"#,
                  color: NSColor.systemOrange)

        // Flags (-f, --flag) — blue
        highlight(storage, str, pattern: #"(?<!\S)(--?[a-zA-Z][a-zA-Z0-9-]*)"#,
                  color: NSColor.systemBlue)

        // Env vars ($VAR) — purple
        highlight(storage, str, pattern: #"\$[a-zA-Z_][a-zA-Z0-9_]*"#,
                  color: NSColor.systemPurple)

        // Quoted strings — green
        highlight(storage, str, pattern: #"'[^']*'|"[^"]*""#,
                  color: NSColor.systemGreen)

        // Redirects (>, >>, <) — teal
        highlight(storage, str, pattern: #"(>>?|<)"#,
                  color: NSColor.systemTeal)

        storage.endEditing()
    }

    private func highlight(_ storage: NSTextStorage, _ str: String, pattern: String, color: NSColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let nsStr = str as NSString
        let range = NSRange(location: 0, length: nsStr.length)
        for match in regex.matches(in: str, range: range) {
            storage.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightedTextField

        init(_ parent: SyntaxHighlightedTextField) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.applyHighlighting(to: textView)
        }
    }
}
