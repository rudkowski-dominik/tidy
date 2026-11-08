import Foundation

public struct ScanSummary: Sendable {
    public var totalDiskCapacity: Int64 = 0
    public var freeDiskSpace: Int64 = 0
    public var usedDiskSpace: Int64 = 0

    public var junkBytes: Int64 = 0
    public var duplicatesBytes: Int64 = 0
    public var largeFilesBytes: Int64 = 0
    public var uninstallerBytes: Int64 = 0

    public var isScanning: Bool = false
    public var scanProgress: Double = 0.0 // 0.0 ... 1.0
    public var currentStatusText: String = "Gotowy do skanowania"
    public var lastScanDate: Date? = nil
    public var scanDuration: TimeInterval = 0

    public init() {}

    public var totalCleanableBytes: Int64 {
        junkBytes + duplicatesBytes + largeFilesBytes + uninstallerBytes
    }
}
