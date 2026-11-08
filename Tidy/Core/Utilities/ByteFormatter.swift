import Foundation

public enum ByteFormatter {
    public static func string(from bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    public static func detailedString(from bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        f.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        f.isAdaptive = false
        return f.string(fromByteCount: bytes)
    }

    public static func percentString(part: Int64, total: Int64) -> String {
        guard total > 0 else { return "0%" }
        let percent = (Double(part) / Double(total)) * 100.0
        return String(format: "%.1f%%", percent)
    }
}
