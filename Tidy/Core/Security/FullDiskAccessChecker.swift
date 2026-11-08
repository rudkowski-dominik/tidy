import Foundation
import AppKit

@MainActor
public final class FullDiskAccessChecker: ObservableObject {
    public static let shared = FullDiskAccessChecker()

    @Published public private(set) var hasFullDiskAccess: Bool = false

    private init() {
        self.hasFullDiskAccess = checkFullDiskAccess()
    }

    /// Checks if the process currently possesses Full Disk Access (FDA).
    public func refresh() {
        self.hasFullDiskAccess = checkFullDiskAccess()
    }

    private func checkFullDiskAccess() -> Bool {
        // Test reading ~/Library/Safari or ~/Library/Mail
        let home = FileManager.default.homeDirectoryForCurrentUser
        let testPaths = [
            home.appendingPathComponent("Library/Safari"),
            home.appendingPathComponent("Library/Mail"),
            home.appendingPathComponent("Library/Suggestions")
        ]

        for path in testPaths {
            // Check if directory exists
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: path.path(percentEncoded: false), isDirectory: &isDir), isDir.boolValue {
                do {
                    _ = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    return true
                } catch {
                    // Access denied => definitely missing FDA
                    return false
                }
            }
        }

        // If none of those folders exist (rare on personal Mac), test user's TCC database path or assume true
        let tccURL = home.appendingPathComponent("Library/Application Support/com.apple.TCC")
        do {
            _ = try FileManager.default.contentsOfDirectory(at: tccURL, includingPropertiesForKeys: nil)
            return true
        } catch {
            return false
        }
    }

    /// Opens macOS System Settings directly to Full Disk Access panel.
    public func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
