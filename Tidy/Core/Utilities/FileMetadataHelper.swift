import Foundation
import AppKit
import CoreServices

public enum FileCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "Wszystkie"
    case archive = "Archiwa i instalatory"
    case video = "Wideo"
    case audio = "Audio"
    case image = "Obrazy"
    case document = "Dokumenty"
    case application = "Aplikacje"
    case other = "Inne"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .archive: return "archivebox"
        case .video: return "film"
        case .audio: return "music.note"
        case .image: return "photo"
        case .document: return "doc.text"
        case .application: return "app.badge"
        case .other: return "doc"
        }
    }
}

public enum FileMetadataHelper {

    /// Computes the total recursive size of a directory or single file in bytes.
    public static func itemSize(at url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDir) else {
            return 0
        }

        if !isDir.boolValue {
            let res = try? url.resourceValues(forKeys: [.totalFileSizeKey, .fileSizeKey])
            return Int64(res?.totalFileSize ?? res?.fileSize ?? 0)
        }

        var total: Int64 = 0
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey, .isDirectoryKey, .isPackageKey]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else {
            return 0
        }

        while let fileURL = enumerator.nextObject() as? URL {
            if let values = try? fileURL.resourceValues(forKeys: keys) {
                if values.isDirectory == false {
                    total += Int64(values.totalFileSize ?? values.fileSize ?? 0)
                }
            }
        }

        return total
    }

    /// Obtains the last opened / accessed date using Spotlight Metadata (kMDItemLastUsedDate)
    /// or falls back to filesystem content access/modification date.
    public static func lastUsedDate(for url: URL) -> Date? {
        let path = url.path(percentEncoded: false)

        if let mdItem = MDItemCreate(kCFAllocatorDefault, path as CFString) {
            if let lastUsedRef = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) {
                if let date = lastUsedRef as? Date {
                    return date
                }
            }
        }

        // Fallback to filesystem timestamps
        if let values = try? url.resourceValues(forKeys: [.contentAccessDateKey, .contentModificationDateKey]) {
            return values.contentAccessDate ?? values.contentModificationDate
        }

        return nil
    }

    /// Categorizes a file URL into standard categories.
    public static func category(for url: URL) -> FileCategory {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "dmg", "pkg", "zip", "tar", "gz", "tgz", "bz2", "7z", "rar", "iso":
            return .archive
        case "mov", "mp4", "m4v", "mkv", "avi", "webm", "wmv", "flv":
            return .video
        case "mp3", "m4a", "wav", "flac", "aac", "aiff", "ogg":
            return .audio
        case "png", "jpg", "jpeg", "heic", "tiff", "gif", "webp", "bmp", "svg", "raw", "cr2", "nef":
            return .image
        case "pdf", "docx", "doc", "xlsx", "xls", "pptx", "ppt", "pages", "numbers", "key", "txt", "rtf", "md", "csv":
            return .document
        case "app":
            return .application
        default:
            return .other
        }
    }

    /// Checks if the URL represents an application bundle or file package.
    public static func isFilePackage(at url: URL) -> Bool {
        NSWorkspace.shared.isFilePackage(atPath: url.path(percentEncoded: false))
    }

    /// Fetches the system icon for a file or application.
    public static func icon(for url: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false))
    }
}
