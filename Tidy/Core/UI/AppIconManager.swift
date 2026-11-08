import AppKit
import SwiftUI

public enum AppIconTheme: String, CaseIterable, Identifiable {
    case automatic = "Automatyczna (System)"
    case dark = "Ciemna"
    case light = "Jasna"

    public var id: String { rawValue }
}

@MainActor
public final class AppIconManager: ObservableObject {
    public static let shared = AppIconManager()

    @AppStorage("tidy_app_icon_theme") public var selectedTheme: String = AppIconTheme.automatic.rawValue {
        didSet {
            applyIcon()
        }
    }

    private init() {
        applyIcon()
    }

    public func applyIcon() {
        let theme = AppIconTheme(rawValue: selectedTheme) ?? .automatic
        let isDark: Bool

        switch theme {
        case .automatic:
            let appearance = NSApp?.effectiveAppearance.name ?? .darkAqua
            isDark = (appearance == .darkAqua || appearance == .vibrantDark)
        case .dark:
            isDark = true
        case .light:
            isDark = false
        }

        let baseName = isDark ? "AppIconDark" : "AppIconLight"
        let filename = "\(baseName).png"

        // 1. Check bundle URL
        if let url = Bundle.main.url(forResource: baseName, withExtension: "png") ??
                     Bundle.main.url(forResource: filename, withExtension: nil),
           let image = NSImage(contentsOf: url) {
            NSApp?.applicationIconImage = image
            return
        }

        // 2. Check app bundle Contents/Resources directly
        let resURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(filename)")
        if let image = NSImage(contentsOf: resURL) {
            NSApp?.applicationIconImage = image
            return
        }

        // 3. Fallback: check project Resources during local testing
        let fallbackPath = "Tidy/Resources/\(filename)"
        if let image = NSImage(contentsOfFile: fallbackPath) {
            NSApp?.applicationIconImage = image
        }
    }
}
