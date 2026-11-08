import Foundation
import CryptoKit

public enum FileHasher {
    private static let partialChunkSize = 8192 // 8 KB

    /// Computes a fast partial hash of a file using its first and last chunks.
    /// Ideal for fast candidate filtering in duplicate detection.
    public static func partialHash(for url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()

        // 1. Read first block
        let headData = handle.readData(ofLength: partialChunkSize)
        guard !headData.isEmpty else { return nil }
        hasher.update(data: headData)

        // 2. Read tail block if file is larger than 2 * partialChunkSize
        do {
            let endOffset = try handle.seekToEnd()
            if endOffset > UInt64(partialChunkSize * 2) {
                try handle.seek(toOffset: endOffset - UInt64(partialChunkSize))
                let tailData = handle.readData(ofLength: partialChunkSize)
                hasher.update(data: tailData)
            }
        } catch {
            return nil
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Computes full SHA-256 hash of a file by streaming in chunks.
    /// Supports Task cancellation.
    public static func fullHash(for url: URL, bufferSize: Int = 65536) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()

        while true {
            if Task.isCancelled { return nil }
            let chunk = handle.readData(ofLength: bufferSize)
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
