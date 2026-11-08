import Foundation
import AppKit

public struct FileItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL
    public let name: String
    public let size: Int64
    public let modificationDate: Date?
    public let lastAccessDate: Date?
    public let category: FileCategory
    public var isSelected: Bool

    public init(
        url: URL,
        size: Int64,
        modificationDate: Date? = nil,
        lastAccessDate: Date? = nil,
        category: FileCategory = .other,
        isSelected: Bool = true
    ) {
        self.id = url.path(percentEncoded: false)
        self.url = url
        self.name = url.lastPathComponent
        self.size = size
        self.modificationDate = modificationDate
        self.lastAccessDate = lastAccessDate
        self.category = category
        self.isSelected = isSelected
    }

    public var formattedSize: String {
        ByteFormatter.string(from: size)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
}
