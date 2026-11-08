import Foundation

public struct RestorableFile: Identifiable, Codable, Sendable {
    public var id: String { originalPath }
    public let originalPath: String
    public let trashPath: String
    public var isRestored: Bool

    public init(originalPath: String, trashPath: String, isRestored: Bool = false) {
        self.originalPath = originalPath
        self.trashPath = trashPath
        self.isRestored = isRestored
    }
}

public struct AuditLogEntry: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let mode: DeletionMode
    public let totalBytesFreed: Int64
    public let succeededCount: Int
    public let failedCount: Int
    public let samplePaths: [String]
    public let errors: [String]
    public var restorableFiles: [RestorableFile]

    public var canRestore: Bool {
        mode == .trash && !restorableFiles.isEmpty && restorableFiles.contains(where: { !$0.isRestored })
    }

    public var isFullyRestored: Bool {
        mode == .trash && !restorableFiles.isEmpty && restorableFiles.allSatisfy { $0.isRestored }
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mode: DeletionMode,
        totalBytesFreed: Int64,
        succeededCount: Int,
        failedCount: Int,
        samplePaths: [String],
        errors: [String],
        restorableFiles: [RestorableFile] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mode = mode
        self.totalBytesFreed = totalBytesFreed
        self.succeededCount = succeededCount
        self.failedCount = failedCount
        self.samplePaths = samplePaths
        self.errors = errors
        self.restorableFiles = restorableFiles
    }
}

public actor AuditLogger {
    public static let shared = AuditLogger()

    private let logFileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let tidyDir = appSupport.appendingPathComponent("Tidy", isDirectory: true)

        try? FileManager.default.createDirectory(at: tidyDir, withIntermediateDirectories: true)
        self.logFileURL = tidyDir.appendingPathComponent("audit_log.json")

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func record(
        operation: DeletionMode,
        succeeded: [String],
        trashedRecords: [TrashedItemRecord] = [],
        failed: [String: String],
        bytesFreed: Int64
    ) {
        let restorable = trashedRecords.map {
            RestorableFile(originalPath: $0.originalPath, trashPath: $0.trashPath, isRestored: false)
        }

        let entry = AuditLogEntry(
            mode: operation,
            totalBytesFreed: bytesFreed,
            succeededCount: succeeded.count,
            failedCount: failed.count,
            samplePaths: Array(succeeded.prefix(20)),
            errors: Array(failed.values.prefix(10)),
            restorableFiles: restorable
        )

        var entries = loadEntries()
        entries.insert(entry, at: 0) // Newest first

        // Keep maximum 200 entries to prevent infinite growth
        if entries.count > 200 {
            entries = Array(entries.prefix(200))
        }

        if let data = try? encoder.encode(entries) {
            try? data.write(to: logFileURL, options: .atomic)
        }
    }

    public func loadEntries() -> [AuditLogEntry] {
        guard let data = try? Data(contentsOf: logFileURL),
              let entries = try? decoder.decode([AuditLogEntry].self, from: data) else {
            return []
        }
        return entries
    }

    public func restore(entryID: UUID) -> (restored: Int, missing: Int) {
        var entries = loadEntries()
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else {
            return (0, 0)
        }

        var entry = entries[index]
        var restoredCount = 0
        var missingCount = 0

        for i in 0..<entry.restorableFiles.count {
            if entry.restorableFiles[i].isRestored { continue }

            let trashURL = URL(fileURLWithPath: entry.restorableFiles[i].trashPath)
            let origURL = URL(fileURLWithPath: entry.restorableFiles[i].originalPath)

            if FileManager.default.fileExists(atPath: trashURL.path(percentEncoded: false)) {
                let parentDir = origURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

                var targetURL = origURL
                if FileManager.default.fileExists(atPath: origURL.path(percentEncoded: false)) {
                    let base = origURL.deletingPathExtension().lastPathComponent
                    let ext = origURL.pathExtension
                    let newName = ext.isEmpty ? "\(base)_przywrócony" : "\(base)_przywrócony.\(ext)"
                    targetURL = parentDir.appendingPathComponent(newName)
                }

                do {
                    try FileManager.default.moveItem(at: trashURL, to: targetURL)
                    entry.restorableFiles[i] = RestorableFile(
                        originalPath: targetURL.path(percentEncoded: false),
                        trashPath: entry.restorableFiles[i].trashPath,
                        isRestored: true
                    )
                    restoredCount += 1
                } catch {
                    missingCount += 1
                }
            } else {
                missingCount += 1
            }
        }

        entries[index] = entry
        if let data = try? encoder.encode(entries) {
            try? data.write(to: logFileURL, options: .atomic)
        }

        return (restoredCount, missingCount)
    }

    public func exportCSV() -> String {
        var csv = "Data,Godzina,Tryb,ZwolnioneBajty,SformatowanyRozmiar,LiczbaPlikow,Bledy,Sciezki\n"
        let entries = loadEntries()
        let dateFormatter = ISO8601DateFormatter()

        for e in entries {
            let dateStr = dateFormatter.string(from: e.timestamp)
            let modeStr = e.mode.rawValue
            let bytes = e.totalBytesFreed
            let human = ByteFormatter.string(from: bytes).replacingOccurrences(of: ",", with: ".")
            let count = e.succeededCount
            let errors = e.errors.joined(separator: "; ").replacingOccurrences(of: "\"", with: "\"\"")
            let paths = e.samplePaths.joined(separator: "; ").replacingOccurrences(of: "\"", with: "\"\"")

            csv += "\"\(dateStr)\",\"\(modeStr)\",\(bytes),\"\(human)\",\(count),\"\(errors)\",\"\(paths)\"\n"
        }
        return csv
    }

    public func exportJSON() -> String {
        let entries = loadEntries()
        guard let data = try? encoder.encode(entries),
              let jsonStr = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return jsonStr
    }

    public func clearLogs() {
        try? FileManager.default.removeItem(at: logFileURL)
    }

    public var logFilePath: String {
        logFileURL.path(percentEncoded: false)
    }

    public var logDirectoryURL: URL {
        logFileURL.deletingLastPathComponent()
    }
}
