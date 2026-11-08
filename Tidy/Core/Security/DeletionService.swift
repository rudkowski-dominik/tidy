import Foundation
import AppKit

public enum DeletionMode: String, Codable, Sendable {
    case trash       // Moves file to Trash (Safe, default)
    case permanent   // Permanently removes file (Explicit confirmation required)
    case dryRun      // Simulates deletion without removing files
}

public enum DeletionError: LocalizedError, Sendable {
    case protectedPath(String)
    case fileNotFound(String)
    case accessDenied(String)
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .protectedPath(let path):
            return "Ścieżka jest chroniona przez system i nie może zostać usunięta: \(path)"
        case .fileNotFound(let path):
            return "Plik nie został znaleziony: \(path)"
        case .accessDenied(let path):
            return "Brak uprawnień do usunięcia pliku: \(path)"
        case .executionFailed(let reason):
            return "Błąd operacji: \(reason)"
        }
    }
}

public struct DeletionReport: Sendable {
    public let mode: DeletionMode
    public let succeededURLs: [URL]
    public let failedItems: [URL: String]
    public let totalBytesFreed: Int64
    public let duration: TimeInterval

    public var isCompleteSuccess: Bool {
        failedItems.isEmpty
    }
}

public actor DeletionService {
    public static let shared = DeletionService()

    private let fileManager = FileManager.default

    private init() {}

    /// Performs deletion of items according to the requested mode.
    ///
    /// - Parameters:
    ///   - urls: The list of URLs to delete or recycle.
    ///   - mode: The chosen deletion mode.
    ///   - dryRun: If true, overrides mode to .dryRun.
    /// - Returns: A report detailing successes and failures.
    public func delete(urls: [URL], mode: DeletionMode = .trash, dryRun: Bool = false) async -> DeletionReport {
        let startTime = Date()
        let effectiveMode = dryRun ? .dryRun : mode

        var succeeded: [URL] = []
        var failed: [URL: String] = [:]
        var bytesFreed: Int64 = 0

        for url in urls {
            // 1. Safety check: Is path protected?
            if ProtectedPaths.isProtected(url: url) {
                failed[url] = "Plik jest chroniony przez reguły bezpieczeństwa systemu."
                continue
            }

            // 2. Check existence
            let standardized = url.standardizedFileURL
            guard fileManager.fileExists(atPath: standardized.path(percentEncoded: false)) else {
                failed[url] = "Plik już nie istnieje."
                continue
            }

            // Compute size before deletion
            let itemSize = (try? standardized.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey]).totalFileSize) ??
                           (try? standardized.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let calculatedSize = Int64(itemSize)

            // 3. Perform operation
            if effectiveMode == .dryRun {
                succeeded.append(standardized)
                bytesFreed += calculatedSize
                continue
            }

            do {
                switch effectiveMode {
                case .trash:
                    try fileManager.trashItem(at: standardized, resultingItemURL: nil)
                    succeeded.append(standardized)
                    bytesFreed += calculatedSize

                case .permanent:
                    try fileManager.removeItem(at: standardized)
                    succeeded.append(standardized)
                    bytesFreed += calculatedSize

                case .dryRun:
                    break
                }
            } catch {
                failed[url] = error.localizedDescription
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        let report = DeletionReport(
            mode: effectiveMode,
            succeededURLs: succeeded,
            failedItems: failed,
            totalBytesFreed: bytesFreed,
            duration: duration
        )

        // Record in persistent audit log
        await AuditLogger.shared.record(
            operation: effectiveMode,
            succeeded: succeeded.map { $0.path(percentEncoded: false) },
            failed: failed.mapKeys { $0.path(percentEncoded: false) },
            bytesFreed: bytesFreed
        )

        return report
    }
}

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (k, v) in self {
            result[transform(k)] = v
        }
        return result
    }
}
