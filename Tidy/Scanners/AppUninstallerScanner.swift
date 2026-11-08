import Foundation

public actor AppUninstallerScanner {
    public static let shared = AppUninstallerScanner()

    private let fileManager = FileManager.default
    private let homeURL: URL

    private init() {
        self.homeURL = FileManager.default.homeDirectoryForCurrentUser
    }

    /// Scans installed third-party applications and resolves their associated library data.
    public func scanInstalledApps(progress: (@Sendable (Double, String) -> Void)? = nil) async -> [InstalledApp] {
        progress?(0.1, "Wyszukiwanie zainstalowanych programów...")

        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            homeURL.appendingPathComponent("Applications")
        ].filter { fileManager.fileExists(atPath: $0.path(percentEncoded: false)) }

        var appURLs: [URL] = []
        for dir in searchDirs {
            if let urls = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                for url in urls where url.pathExtension.lowercased() == "app" {
                    if !ProtectedPaths.isProtected(url: url) {
                        appURLs.append(url)
                    }
                }
            }
        }

        var apps: [InstalledApp] = []
        let total = Double(appURLs.count)

        for (i, url) in appURLs.enumerated() {
            if Task.isCancelled { break }

            let bundle = Bundle(url: url)
            guard let bundleID = bundle?.bundleIdentifier else { continue }

            let appName = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String) ??
                          (bundle?.infoDictionary?["CFBundleName"] as? String) ??
                          url.deletingPathExtension().lastPathComponent

            progress?(Double(i) / total, "Analiza powiązanych plików: \(appName)...")

            let appSize = FileMetadataHelper.itemSize(at: url)
            let lastUsed = FileMetadataHelper.lastUsedDate(for: url)

            let associated = findAssociatedFiles(forBundleID: bundleID, appName: appName)

            apps.append(InstalledApp(
                id: bundleID,
                bundleID: bundleID,
                name: appName,
                appURL: url,
                appBundleSize: appSize,
                lastUsedDate: lastUsed,
                associatedItems: associated,
                isOrphaned: false
            ))
        }

        apps.sort { $0.totalSize > $1.totalSize }
        progress?(1.0, "Znaleziono \(apps.count) aplikacji")
        return apps
    }

    /// Scans Library directories for leftover files whose parent app is no longer installed.
    public func scanOrphanedRemnants(installedBundleIDs: Set<String>, progress: (@Sendable (Double, String) -> Void)? = nil) async -> [InstalledApp] {
        progress?(0.5, "Poszukiwanie osieroconych plików po odinstalowanych aplikacjach...")

        let libraryURL = homeURL.appendingPathComponent("Library")
        let searchLocations: [(URL, String)] = [
            (libraryURL.appendingPathComponent("Application Support"), "Application Support"),
            (libraryURL.appendingPathComponent("Caches"), "Caches"),
            (libraryURL.appendingPathComponent("Preferences"), "Preferences"),
            (libraryURL.appendingPathComponent("Containers"), "Containers"),
            (libraryURL.appendingPathComponent("Saved Application State"), "Saved State"),
            (libraryURL.appendingPathComponent("WebKit"), "WebKit"),
            (libraryURL.appendingPathComponent("HTTPStorages"), "HTTPStorages")
        ]

        var orphanedApps: [String: [AppAssociatedItem]] = [:]

        // Standard Apple prefixes to ignore as orphaned
        let applePrefixes = ["com.apple.", "com.google.Keystone", "MobileDevice"]

        for (dir, desc) in searchLocations {
            if Task.isCancelled { break }
            guard fileManager.fileExists(atPath: dir.path(percentEncoded: false)) else { continue }

            guard let items = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for itemURL in items {
                let name = itemURL.lastPathComponent
                if ProtectedPaths.isProtected(url: itemURL) { continue }

                // Check if name looks like a bundle ID (e.g. "com.spotify.client" or "com.tinyspeck.slackmacgap")
                let cleanID = name.replacingOccurrences(of: ".savedState", with: "")
                                  .replacingOccurrences(of: ".plist", with: "")

                let isApple = applePrefixes.contains { cleanID.hasPrefix($0) }
                if isApple { continue }

                // If it contains dots and has at least 3 parts (com.vendor.product) and is not installed
                if cleanID.contains(".") && !installedBundleIDs.contains(cleanID) {
                    let size = FileMetadataHelper.itemSize(at: itemURL)
                    guard size > 0 else { continue }

                    let associated = AppAssociatedItem(
                        url: itemURL,
                        size: size,
                        typeDescription: desc,
                        isSelected: true
                    )
                    orphanedApps[cleanID, default: []].append(associated)
                }
            }
        }

        var result: [InstalledApp] = []
        for (bundleID, items) in orphanedApps {
            let readableName = bundleID.components(separatedBy: ".").last?.capitalized ?? bundleID
            result.append(InstalledApp(
                id: "orphan_\(bundleID)",
                bundleID: bundleID,
                name: "\(readableName) (Pozostałość)",
                appURL: nil,
                appBundleSize: 0,
                lastUsedDate: nil,
                associatedItems: items,
                isOrphaned: true,
                isSelected: true
            ))
        }

        result.sort { $0.totalSize > $1.totalSize }
        progress?(1.0, "Znaleziono \(result.count) osieroconych pozostałości")
        return result
    }

    private func findAssociatedFiles(forBundleID bundleID: String, appName: String) -> [AppAssociatedItem] {
        var items: [AppAssociatedItem] = []
        let lib = homeURL.appendingPathComponent("Library")

        // 1. Application Support (<BundleID> or <AppName>)
        let appSupport = lib.appendingPathComponent("Application Support")
        checkAndAppend(appSupport.appendingPathComponent(bundleID), desc: "Application Support", into: &items)
        if !appName.isEmpty {
            checkAndAppend(appSupport.appendingPathComponent(appName), desc: "Application Support", into: &items)
        }

        // 2. Caches
        let caches = lib.appendingPathComponent("Caches")
        checkAndAppend(caches.appendingPathComponent(bundleID), desc: "Caches", into: &items)

        // 3. Preferences (.plist)
        let prefs = lib.appendingPathComponent("Preferences")
        checkAndAppend(prefs.appendingPathComponent("\(bundleID).plist"), desc: "Preferences", into: &items)

        // 4. Containers
        let containers = lib.appendingPathComponent("Containers")
        checkAndAppend(containers.appendingPathComponent(bundleID), desc: "App Sandbox Container", into: &items)

        // 5. Saved Application State
        let savedState = lib.appendingPathComponent("Saved Application State")
        checkAndAppend(savedState.appendingPathComponent("\(bundleID).savedState"), desc: "Saved Application State", into: &items)

        // 6. WebKit
        let webKit = lib.appendingPathComponent("WebKit")
        checkAndAppend(webKit.appendingPathComponent(bundleID), desc: "WebKit Cache", into: &items)

        // 7. HTTPStorages
        let httpStorages = lib.appendingPathComponent("HTTPStorages")
        checkAndAppend(httpStorages.appendingPathComponent(bundleID), desc: "HTTP Cookies/Storage", into: &items)

        // 8. LaunchAgents (e.g. ~/Library/LaunchAgents/<BundleID>.plist)
        let launchAgents = lib.appendingPathComponent("LaunchAgents")
        checkAndAppend(launchAgents.appendingPathComponent("\(bundleID).plist"), desc: "Launch Agent", into: &items)

        return items
    }

    private func checkAndAppend(_ url: URL, desc: String, into list: inout [AppAssociatedItem]) {
        if ProtectedPaths.isProtected(url: url) { return }
        guard fileManager.fileExists(atPath: url.path(percentEncoded: false)) else { return }

        let size = FileMetadataHelper.itemSize(at: url)
        guard size > 0 else { return }

        list.append(AppAssociatedItem(url: url, size: size, typeDescription: desc, isSelected: true))
    }
}
