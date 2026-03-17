import SwiftUI

/// App-wide appearance and behaviour preferences.
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    // MARK: - Density

    enum DensityMode: String, CaseIterable, Identifiable {
        case compact  = "Compact"
        case normal   = "Normal"
        case spacious = "Spacious"

        var id: String { rawValue }

        var rowPadding: CGFloat {
            switch self {
            case .compact:  return 2
            case .normal:   return 4
            case .spacious: return 10
            }
        }
    }

    // MARK: - Accent Theme

    enum AccentTheme: String, CaseIterable, Identifiable {
        case system = "System"
        case blue   = "Blue"
        case purple = "Purple"
        case pink   = "Pink"
        case red    = "Red"
        case orange = "Orange"
        case yellow = "Yellow"
        case green  = "Green"
        case teal   = "Teal"
        case indigo = "Indigo"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .system: return .accentColor
            case .blue:   return .blue
            case .purple: return .purple
            case .pink:   return .pink
            case .red:    return .red
            case .orange: return .orange
            case .yellow: return Color(red: 0.9, green: 0.75, blue: 0)
            case .green:  return .green
            case .teal:   return .teal
            case .indigo: return .indigo
            }
        }
    }

    // MARK: - Stored Values

    @AppStorage("accentTheme")    var accentThemeName:  String = AccentTheme.system.rawValue
    @AppStorage("densityMode")   var densityModeName:  String = DensityMode.normal.rawValue
    @AppStorage("showTagsInRow") var showTagsInRow:    Bool   = true
    @AppStorage("menuBarEnabled") var menuBarEnabled:  Bool   = true

    // MARK: - Computed

    var accentTheme: AccentTheme {
        AccentTheme(rawValue: accentThemeName) ?? .system
    }

    var densityMode: DensityMode {
        DensityMode(rawValue: densityModeName) ?? .normal
    }
}
