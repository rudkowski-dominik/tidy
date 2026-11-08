import Foundation

public struct DuplicateGroup: Identifiable, Sendable {
    public let id: String // sha256 hash
    public let hash: String
    public let fileSize: Int64
    public var files: [FileItem]
    public var recommendedKeepURL: URL

    public init(hash: String, fileSize: Int64, files: [FileItem], recommendedKeepURL: URL? = nil) {
        self.id = hash
        self.hash = hash
        self.fileSize = fileSize
        self.files = files

        if let recommended = recommendedKeepURL {
            self.recommendedKeepURL = recommended
        } else {
            // Auto-recommendation logic:
            // 1. Prefer file with oldest creation date
            // 2. Or prefer Documents / Pictures over Downloads / Desktop
            let sorted = files.sorted { f1, f2 in
                let p1 = f1.url.path(percentEncoded: false)
                let p2 = f2.url.path(percentEncoded: false)

                let isDoc1 = p1.contains("/Documents") || p1.contains("/Pictures")
                let isDoc2 = p2.contains("/Documents") || p2.contains("/Pictures")
                if isDoc1 != isDoc2 {
                    return isDoc1 && !isDoc2
                }

                let d1 = f1.modificationDate ?? Date.distantPast
                let d2 = f2.modificationDate ?? Date.distantPast
                return d1 < d2
            }
            self.recommendedKeepURL = sorted.first?.url ?? files.first!.url
        }

        // By default, mark all items except the recommended keep URL for deletion
        for i in 0..<self.files.count {
            self.files[i].isSelected = (self.files[i].url != self.recommendedKeepURL)
        }
    }

    public var wastedBytes: Int64 {
        guard files.count > 1 else { return 0 }
        let selectedCount = files.filter { $0.isSelected }.count
        return Int64(selectedCount) * fileSize
    }

    public var totalSize: Int64 {
        Int64(files.count) * fileSize
    }
}
