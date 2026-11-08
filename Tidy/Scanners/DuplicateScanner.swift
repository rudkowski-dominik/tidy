import Foundation

public actor DuplicateScanner {
    public static let shared = DuplicateScanner()

    private let fileManager = FileManager.default

    private init() {}

    public static var defaultScanDirectories: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Pictures")
        ].filter { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
    }

    /// Scans provided directories for duplicate files using multi-pass hashing.
    ///
    /// - Parameters:
    ///   - directories: The directories to scan.
    ///   - minFileSize: Minimum file size in bytes (e.g. 1024 to avoid zero-byte or tiny clutter).
    ///   - progress: Progress reporting callback.
    /// - Returns: List of duplicate groups.
    public func scan(
        directories: [URL] = defaultScanDirectories,
        minFileSize: Int64 = 1024,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [DuplicateGroup] {
        progress?(0.05, "Zbieranie listy plików...")

        // Phase 1: Collect files grouped by exact size
        var sizeGroups: [Int64: [URL]] = [:]

        for dir in directories {
            if Task.isCancelled { return [] }
            collectFiles(in: dir, minSize: minFileSize, into: &sizeGroups)
        }

        // Keep only groups where 2 or more files have the exact same size
        let candidateGroups = sizeGroups.filter { $0.value.count >= 2 }
        let totalCandidates = candidateGroups.values.reduce(0) { $0 + $1.count }

        guard totalCandidates > 0 else {
            progress?(1.0, "Nie znaleziono duplikatów")
            return []
        }

        progress?(0.30, "Analiza wstępna (częściowe hashowanie)...")

        // Phase 2: Compute partial hash for files in candidates
        var partialHashGroups: [String: [URL]] = [:]
        var processedPartial = 0

        for (size, urls) in candidateGroups {
            if Task.isCancelled { return [] }

            for url in urls {
                if let pHash = FileHasher.partialHash(for: url) {
                    let key = "\(size)_\(pHash)"
                    partialHashGroups[key, default: []].append(url)
                }
                processedPartial += 1
                let frac = 0.30 + (0.30 * Double(processedPartial) / Double(totalCandidates))
                progress?(frac, "Częściowy hash: \(url.lastPathComponent)")
            }
        }

        // Filter partial hash collisions (count >= 2)
        let fullHashCandidates = partialHashGroups.filter { $0.value.count >= 2 }
        let candidateFilesForFullHash = fullHashCandidates.values.reduce(0) { $0 + $1.count }

        guard candidateFilesForFullHash > 0 else {
            progress?(1.0, "Brak duplikatów")
            return []
        }

        progress?(0.60, "Pełna weryfikacja SHA-256...")

        // Phase 3: Full SHA-256 hash
        var fullHashGroups: [String: (size: Int64, urls: [URL])] = [:]
        var processedFull = 0

        for (_, urls) in fullHashCandidates {
            if Task.isCancelled { return [] }

            for url in urls {
                if Task.isCancelled { return [] }
                if let fHash = FileHasher.fullHash(for: url) {
                    let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    if var existing = fullHashGroups[fHash] {
                        existing.urls.append(url)
                        fullHashGroups[fHash] = existing
                    } else {
                        fullHashGroups[fHash] = (Int64(size), [url])
                    }
                }
                processedFull += 1
                let frac = 0.60 + (0.35 * Double(processedFull) / Double(candidateFilesForFullHash))
                progress?(frac, "Weryfikacja SHA-256: \(url.lastPathComponent)")
            }
        }

        // Phase 4: Construct DuplicateGroups
        var finalGroups: [DuplicateGroup] = []

        for (hash, tuple) in fullHashGroups where tuple.urls.count >= 2 {
            var items: [FileItem] = []
            for url in tuple.urls {
                let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                let accessDate = (try? url.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
                items.append(FileItem(
                    url: url,
                    size: tuple.size,
                    modificationDate: modDate,
                    lastAccessDate: accessDate,
                    category: FileMetadataHelper.category(for: url),
                    isSelected: false
                ))
            }

            finalGroups.append(DuplicateGroup(
                hash: hash,
                fileSize: tuple.size,
                files: items
            ))
        }

        // Sort by wasted space descending
        finalGroups.sort { $0.wastedBytes > $1.wastedBytes }

        progress?(1.0, "Zakończono wykrywanie duplikatów: znaleziono \(finalGroups.count) grup")
        return finalGroups
    }

    private func collectFiles(in directory: URL, minSize: Int64, into dict: inout [Int64: [URL]]) {
        guard fileManager.fileExists(atPath: directory.path(percentEncoded: false)) else { return }

        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .isDirectoryKey,
            .isPackageKey,
            .isSymbolicLinkKey,
            .isHiddenKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants]
        ) else { return }

        while let url = enumerator.nextObject() as? URL {
            if Task.isCancelled { break }

            guard let values = try? url.resourceValues(forKeys: keys) else { continue }

            if values.isHidden == true ||
               values.isDirectory == true ||
               values.isPackage == true ||
               values.isSymbolicLink == true {
                continue
            }

            if ProtectedPaths.isProtected(url: url) {
                continue
            }

            let size = Int64(values.fileSize ?? 0)
            if size >= minSize {
                dict[size, default: []].append(url)
            }
        }
    }
}
