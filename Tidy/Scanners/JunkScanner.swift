import Foundation

public actor JunkScanner {
    public static let shared = JunkScanner()

    private let fileManager = FileManager.default
    private let homeURL: URL

    private init() {
        self.homeURL = FileManager.default.homeDirectoryForCurrentUser
    }

    /// Scans all system & app junk categories.
    ///
    /// - Parameter progress: Closure receiving progress fraction (0.0 to 1.0) and status description.
    /// - Returns: An array of `JunkCategoryItem` ready for display.
    public func scan(progress: (@Sendable (Double, String) -> Void)? = nil) async -> [JunkCategoryItem] {
        var results: [JunkCategoryItem] = []
        let categories = JunkType.allCases
        let totalCount = Double(categories.count)

        for (index, cat) in categories.enumerated() {
            if Task.isCancelled { break }

            let fraction = Double(index) / totalCount
            progress?(fraction, "Skanowanie: \(cat.rawValue)...")

            let items = await scanCategory(cat)
            results.append(JunkCategoryItem(type: cat, items: items))
        }

        progress?(1.0, "Ukończono skanowanie śmieci")
        return results
    }

    private func scanCategory(_ type: JunkType) async -> [FileItem] {
        switch type {
        case .userCache:
            let cachesURL = homeURL.appendingPathComponent("Library/Caches")
            return scanTopLevelSubdirectories(at: cachesURL, excluding: [
                "com.apple.Safari",
                "Google",
                "Firefox",
                "company.thebrowser.Browser"
            ])

        case .systemLogs:
            let logsURL = homeURL.appendingPathComponent("Library/Logs")
            return scanDirectoryFiles(at: logsURL, recursive: false)

        case .crashReports:
            let diagURL = homeURL.appendingPathComponent("Library/Logs/DiagnosticReports")
            return scanDirectoryFiles(at: diagURL, recursive: false)

        case .tempFiles:
            var items: [FileItem] = []
            let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            items.append(contentsOf: scanDirectoryFiles(at: tmpURL, recursive: false))
            return items

        case .oldInstallers:
            let downloadsURL = homeURL.appendingPathComponent("Downloads")
            return scanInstallers(at: downloadsURL)

        case .xcodeDerivedData:
            let ddURL = homeURL.appendingPathComponent("Library/Developer/Xcode/DerivedData")
            return scanTopLevelSubdirectories(at: ddURL)

        case .xcodeArchives:
            let archURL = homeURL.appendingPathComponent("Library/Developer/Xcode/Archives")
            return scanTopLevelSubdirectories(at: archURL)

        case .xcodeSimulators:
            let devSupportURL = homeURL.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
            return scanTopLevelSubdirectories(at: devSupportURL)

        case .browserSafari:
            let safariCache = homeURL.appendingPathComponent("Library/Caches/com.apple.Safari")
            return scanSingleFolderIfPresent(at: safariCache, name: "Safari Cache")

        case .browserChrome:
            let chromeCache = homeURL.appendingPathComponent("Library/Caches/Google/Chrome")
            return scanSingleFolderIfPresent(at: chromeCache, name: "Google Chrome Cache")

        case .browserFirefox:
            let ffCache = homeURL.appendingPathComponent("Library/Caches/Firefox")
            return scanSingleFolderIfPresent(at: ffCache, name: "Firefox Cache")

        case .browserArc:
            let arcCache = homeURL.appendingPathComponent("Library/Caches/company.thebrowser.Browser")
            return scanSingleFolderIfPresent(at: arcCache, name: "Arc Browser Cache")

        case .trash:
            let trashURL = homeURL.appendingPathComponent(".Trash")
            return scanDirectoryFiles(at: trashURL, recursive: false, includeDirectories: true)
        }
    }

    private func scanTopLevelSubdirectories(at parentURL: URL, excluding: Set<String> = []) -> [FileItem] {
        guard fileManager.fileExists(atPath: parentURL.path(percentEncoded: false)) else { return [] }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: parentURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .totalFileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [FileItem] = []

        for url in contents {
            if Task.isCancelled { break }
            let name = url.lastPathComponent
            if excluding.contains(name) { continue }
            if ProtectedPaths.isProtected(url: url) { continue }

            let size = FileMetadataHelper.itemSize(at: url)
            guard size > 0 else { continue }

            let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            items.append(FileItem(
                url: url,
                size: size,
                modificationDate: modDate,
                category: FileMetadataHelper.category(for: url)
            ))
        }

        return items.sorted { $0.size > $1.size }
    }

    private func scanDirectoryFiles(at dirURL: URL, recursive: Bool, includeDirectories: Bool = false) -> [FileItem] {
        guard fileManager.fileExists(atPath: dirURL.path(percentEncoded: false)) else { return [] }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [FileItem] = []

        for url in contents {
            if Task.isCancelled { break }
            if ProtectedPaths.isProtected(url: url) { continue }

            var isDir: ObjCBool = false
            fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDir)

            if isDir.boolValue && !includeDirectories {
                continue
            }

            let size = FileMetadataHelper.itemSize(at: url)
            guard size > 0 else { continue }

            let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            items.append(FileItem(
                url: url,
                size: size,
                modificationDate: modDate,
                category: FileMetadataHelper.category(for: url)
            ))
        }

        return items.sorted { $0.size > $1.size }
    }

    private func scanInstallers(at downloadsURL: URL) -> [FileItem] {
        guard fileManager.fileExists(atPath: downloadsURL.path(percentEncoded: false)) else { return [] }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [FileItem] = []
        let installerExts: Set<String> = ["dmg", "pkg", "iso"]

        for url in contents {
            if Task.isCancelled { break }
            if installerExts.contains(url.pathExtension.lowercased()) {
                if ProtectedPaths.isProtected(url: url) { continue }

                let size = FileMetadataHelper.itemSize(at: url)
                let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate

                items.append(FileItem(
                    url: url,
                    size: size,
                    modificationDate: modDate,
                    category: .archive
                ))
            }
        }

        return items.sorted { $0.size > $1.size }
    }

    private func scanSingleFolderIfPresent(at url: URL, name: String) -> [FileItem] {
        guard fileManager.fileExists(atPath: url.path(percentEncoded: false)) else { return [] }
        if ProtectedPaths.isProtected(url: url) { return [] }

        let size = FileMetadataHelper.itemSize(at: url)
        guard size > 0 else { return [] }

        let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        return [FileItem(
            url: url,
            size: size,
            modificationDate: modDate,
            category: .other
        )]
    }
}
