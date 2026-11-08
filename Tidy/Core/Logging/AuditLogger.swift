import Foundation

public struct AuditLogEntry: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let mode: DeletionMode
    public let totalBytesFreed: Int64
    public let succeededCount: Int
    public let failedCount: Int
    public let samplePaths: [String]
    public let errors: [String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mode: DeletionMode,
        totalBytesFreed: Int64,
        succeededCount: Int,
        failedCount: Int,
        samplePaths: [String],
        errors: [String]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mode = mode
        self.totalBytesFreed = totalBytesFreed
        self.succeededCount = succeededCount
        self.failedCount = failedCount
        self.samplePaths = samplePaths
        self.errors = errors
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
        failed: [String: String],
        bytesFreed: Int64
    ) {
        let entry = AuditLogEntry(
            mode: operation,
            totalBytesFreed: bytesFreed,
            succeededCount: succeeded.count,
            failedCount: failed.count,
            samplePaths: Array(succeeded.prefix(20)),
            errors: Array(failed.values.prefix(10))
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
