import Foundation

/// Safety enforcement for Tidy.
/// Defines system and user paths that can NEVER be modified, moved to Trash, or deleted under any circumstance.
public enum ProtectedPaths {

    /// Standard system prefixes that must never be altered.
    private static let systemPrefixes: [String] = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/etc",
        "/private/etc",
        "/var/db",
        "/private/var/db",
        "/var/root",
        "/private/var/root",
        "/Library/Apple",
        "/Library/Preferences",
        "/Library/Extensions",
        "/Library/Frameworks",
        "/Library/LaunchDaemons",
        "/Library/Security",
        "/Library/Keychains",
        "/System/Applications"
    ]

    /// Suffixes indicating bundles or databases that must never be deleted as junk or duplicates.
    private static let protectedExtensions: Set<String> = [
        "photoslibrary",
        "photolibrary",
        "aplibrary",
        "keychain",
        "keychain-db"
    ]

    /// User-specific protected relative paths inside home directory.
    private static let userProtectedRelativePaths: [String] = [
        "Library/Keychains",
        "Library/Messages",
        "Library/Mail",
        "Library/Mobile Documents",             // iCloud Drive container root
        "Library/Application Support/AddressBook",
        "Library/Accounts",
        "Library/IdentityServices"
    ]

    /// Normalizes path by resolving firmlinks (/System/Volumes/Data) and symlinks, and removing trailing slashes.
    public static func canonicalPath(for url: URL) -> String {
        var path = url.resolvingSymlinksInPath().standardized.path(percentEncoded: false)

        // On macOS Catalina+, APFS firmlinks mount the writable Data volume at /System/Volumes/Data.
        // Strip this prefix so /System/Volumes/Data/Users/abc becomes /Users/abc
        let firmlinkPrefix = "/System/Volumes/Data"
        if path.hasPrefix(firmlinkPrefix) {
            path.removeFirst(firmlinkPrefix.count)
            if path.isEmpty { path = "/" }
        }

        // Trim trailing slash for non-root paths so "/Applications/" matches "/Applications"
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }

        return path
    }

    /// Evaluates whether a given URL is strictly protected.
    ///
    /// - Parameter url: The file or folder URL to check.
    /// - Returns: `true` if deleting or modifying this path is forbidden; `false` otherwise.
    public static func isProtected(url: URL) -> Bool {
        let path = canonicalPath(for: url)

        // 1. Explicit temporary directories are cleanable
        if path.hasPrefix("/private/var/folders/") ||
           path.hasPrefix("/var/folders/") ||
           path.hasPrefix("/private/tmp/") ||
           path.hasPrefix("/tmp/") {
            // But protect the root temp folder itself
            if path == "/private/tmp" || path == "/tmp" || path == "/private/var/folders" || path == "/var/folders" {
                return true
            }
            return false
        }

        // 2. Check root / base directories that can never be deleted as a whole
        let home = canonicalPath(for: FileManager.default.homeDirectoryForCurrentUser)
        let rootDirectories: Set<String> = [
            "/",
            "/Applications",
            "/Library",
            "/Users",
            home,
            (home as NSString).appendingPathComponent("Desktop"),
            (home as NSString).appendingPathComponent("Documents"),
            (home as NSString).appendingPathComponent("Downloads"),
            (home as NSString).appendingPathComponent("Pictures"),
            (home as NSString).appendingPathComponent("Movies"),
            (home as NSString).appendingPathComponent("Music"),
            (home as NSString).appendingPathComponent("Library")
        ]

        if rootDirectories.contains(path) {
            return true
        }

        // 3. Check strict system prefixes
        for prefix in systemPrefixes {
            if path == prefix || path.hasPrefix(prefix + "/") {
                return true
            }
        }

        // 4. Check user protected paths
        for relative in userProtectedRelativePaths {
            let fullProtected = (home as NSString).appendingPathComponent(relative)
            if path == fullProtected || path.hasPrefix(fullProtected + "/") {
                return true
            }
        }

        // 5. Check protected extensions (e.g. Photos Library bundle)
        let standardizedURL = url.resolvingSymlinksInPath().standardized
        let ext = standardizedURL.pathExtension.lowercased()
        if protectedExtensions.contains(ext) {
            return true
        }

        // 6. Check if the URL points inside any .photoslibrary package
        var current = standardizedURL
        while current.pathComponents.count > 1 {
            if protectedExtensions.contains(current.pathExtension.lowercased()) {
                return true
            }
            current.deleteLastPathComponent()
        }

        return false
    }

    /// Throws an error if the specified URL is protected.
    public static func validateCanModify(url: URL) throws {
        if isProtected(url: url) {
            throw DeletionError.protectedPath(url.path(percentEncoded: false))
        }
    }
}
