import SwiftUI

@main
struct AliasManagerApp: App {

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 880, height: 580)
        .commands {
            // File menu
            CommandGroup(after: .newItem) {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshAliases, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // Edit menu — Undo/Redo handled by toolbar buttons
            CommandGroup(replacing: .undoRedo) { }

            // Help menu
            CommandGroup(replacing: .help) {
                Button("About AliasManager") {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com/efekurucay/tam-cli")!
                    )
                }
                Divider()
                Button("View on GitHub") {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com/efekurucay/tam-cli")!
                    )
                }
            }
        }

        // Settings window (⌘,)
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshAliases = Notification.Name("refreshAliases")
}
