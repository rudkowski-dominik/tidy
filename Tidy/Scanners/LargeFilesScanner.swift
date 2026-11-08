import Foundation
import AppKit

public struct UnusedAppItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let bundleID: String
    public let size: Int64
    public let lastUsedDate: Date?
    public var isSelected: Bool

    public init(
        name: String,
        url: URL,
        bundleID: String,
        size: Int64,
        lastUsedDate: Date?,
        isSelected: Bool = false
    ) {
        self.id = url.path(percentEncoded: false)
        self.name = name
        self.url = url
        self.bundleID = bundleID
        self.size = size
        self.lastUsedDate = lastUsedDate
        self.isSelected = isSelected
    }

    public var formattedSize: String {
        ByteFormatter.string(from: size)
    }
}

public actor LargeFilesScanner {
    public static let shared = LargeFilesScanner()

    private let fileManager = FileManager.default
    private let homeURL: URL

    private init() {
        self.homeURL = FileManager.default.homeDirectoryForCurrentUser
    }

    /// Scans user directories for files larger than `minSizeBytes`.
    public func scanLargeFiles(
        minSizeBytes: Int64 = 100 * 1024 * 1024, // 100 MB default
        directories: [URL]? = nil,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [FileItem] {
        let scanDirs = directories ?? [
            homeURL.appendingPathComponent("Downloads"),
            homeURL.appendingPathComponent("Documents"),
            homeURL.appendingPathComponent("Desktop"),
            homeURL.appendingPathComponent("Movies"),
            homeURL.appendingPathComponent("Music")
        ].filter { fileManager.fileExists(atPath: $0.path(percentEncoded: false)) }

        var results: [FileItem] = []
        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .isDirectoryKey,
            .isPackageKey,
            .contentModificationDateKey,
            .contentAccessDateKey
        ]

        let totalDirs = Double(scanDirs.count)
        for (i, dir) in scanDirs.enumerated() {
            if Task.isCancelled { break }
            progress?(Double(i) / totalDirs, "Przeszukiwanie: \(dir.lastPathComponent)...")

            guard let enumerator = fileManager.enumerator(
                at: dir,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }
                if ProtectedPaths.isProtected(url: url) { continue }

                guard let values = try? url.resourceValues(forKeys: keys) else { continue }
                if values.isDirectory == true || values.isPackage == true { continue }

                let size = Int64(values.fileSize ?? 0)
                if size >= minSizeBytes {
                    let lastAccess = values.contentAccessDate ?? values.contentModificationDate
                    let item = FileItem(
                        url: url,
                        size: size,
                        modificationDate: values.contentModificationDate,
                        lastAccessDate: lastAccess,
                        category: FileMetadataHelper.category(for: url),
                        isSelected: false // User should consciously select large files
                    )
                    results.append(item)
                }
            }
        }

        results.sort { $0.size > $1.size }
        progress?(1.0, "Znaleziono \(results.count) dużych plików")
        return results
    }

    /// Scans installed apps for applications that have not been opened in `olderThanMonths`.
    public func scanUnusedApps(
        olderThanMonths: Int = 3,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [UnusedAppItem] {
        progress?(0.1, "Wyszukiwanie rzadko używanych aplikacji...")

        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            homeURL.appendingPathComponent("Applications")
        ].filter { fileManager.fileExists(atPath: $0.path(percentEncoded: false)) }

        var apps: [UnusedAppItem] = []
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -olderThanMonths, to: Date()) ?? Date()

        for dir in searchDirs {
            if Task.isCancelled { break }

            guard let urls = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in urls where url.pathExtension.lowercased() == "app" {
                if Task.isCancelled { break }
                if ProtectedPaths.isProtected(url: url) { continue }

                let bundle = Bundle(url: url)
                let bundleID = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let appName = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String) ??
                              (bundle?.infoDictionary?["CFBundleName"] as? String) ??
                              url.deletingPathExtension().lastPathComponent

                let lastUsed = FileMetadataHelper.lastUsedDate(for: url)

                // If never recorded or older than cutoff date, consider it unused
                if let used = lastUsed {
                    if used < cutoffDate {
                        let size = FileMetadataHelper.itemSize(at: url)
                        apps.append(UnusedAppItem(
                            name: appName,
                            url: url,
                            bundleID: bundleID,
                            size: size,
                            lastUsedDate: used
                        ))
                    }
                } else {
                    // Check creation / modification date if last used is unavailable
                    let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
                    let modDate = values?.contentModificationDate ?? values?.creationDate
                    if let modDate = modDate, modDate < cutoffDate {
                        let size = FileMetadataHelper.itemSize(at: url)
                        apps.append(UnusedAppItem(
                            name: appName,
                            url: url,
                            bundleID: bundleID,
                            size: size,
                            lastUsedDate: modDate
                        ))
                    }
                }
            }
        }

        apps.sort { $0.size > $1.size }
        progress?(1.0, "Znaleziono \(apps.count) nieużywanych aplikacji")
        return apps
    }
}
