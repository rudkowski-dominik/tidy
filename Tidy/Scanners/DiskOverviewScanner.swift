import Foundation

public struct DiskSpaceInfo: Sendable {
    public let totalCapacity: Int64
    public let freeSpace: Int64
    public let usedSpace: Int64

    public var usedPercent: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedSpace) / Double(totalCapacity)
    }
}

public actor DiskOverviewScanner {
    public static let shared = DiskOverviewScanner()

    private init() {}

    public func scanDiskSpace() -> DiskSpaceInfo {
        let rootURL = URL(fileURLWithPath: "/")

        do {
            let values = try rootURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey
            ])

            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? Int64(values.volumeAvailableCapacity ?? 0)
            let used = max(0, total - free)

            return DiskSpaceInfo(
                totalCapacity: total,
                freeSpace: free,
                usedSpace: used
            )
        } catch {
            return DiskSpaceInfo(totalCapacity: 0, freeSpace: 0, usedSpace: 0)
        }
    }
}
