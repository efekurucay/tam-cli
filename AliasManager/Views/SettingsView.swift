import SwiftUI

/// App settings window — theme, appearance, menu bar, and stats.
struct SettingsView: View {

    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedTab: SettingsTab = .appearance

    enum SettingsTab: String, CaseIterable {
        case appearance = "Appearance"
        case menuBar    = "Menu Bar"
        case stats      = "Statistics"

        var icon: String {
            switch self {
            case .appearance: return "paintbrush"
            case .menuBar:    return "menubar.rectangle"
            case .stats:      return "chart.bar"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppearanceTab(settings: settings)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(SettingsTab.appearance)

            MenuBarTab(settings: settings)
                .tabItem {
                    Label("Menu Bar", systemImage: "menubar.rectangle")
                }
                .tag(SettingsTab.menuBar)
        }
        .frame(width: 440, height: 320)
    }
}

// MARK: - Appearance Tab

private struct AppearanceTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Accent Color") {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 10) {
                    ForEach(AppSettings.AccentTheme.allCases) { theme in
                        Button {
                            settings.accentThemeName = theme.rawValue
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(theme == .system ? AnyShapeStyle(LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )) : AnyShapeStyle(theme.color))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                settings.accentTheme == theme
                                                    ? Color.primary
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                            .padding(-3)
                                    )

                                Text(theme.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Row Density") {
                Picker("Density", selection: $settings.densityModeName) {
                    ForEach(AppSettings.DensityMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Tags") {
                Toggle("Show tags in alias rows", isOn: $settings.showTagsInRow)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Menu Bar Tab

private struct MenuBarTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Menu Bar") {
                Toggle("Show AliasManager in menu bar", isOn: $settings.menuBarEnabled)
                    .onChange(of: settings.menuBarEnabled) { _, enabled in
                        NotificationCenter.default.post(
                            name: .menuBarNeedsRebuild,
                            object: nil,
                            userInfo: ["enabled": enabled]
                        )
                    }

                if settings.menuBarEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Shows your most-used aliases in the menu bar for quick access.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("Click any alias to copy its command to clipboard.", systemImage: "doc.on.clipboard")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
