import Foundation
import SwiftUI

public final class TreemapNode: Identifiable, @unchecked Sendable {
    public let id: String
    public let url: URL
    public let name: String
    public let size: Int64
    public let isDirectory: Bool
    public var children: [TreemapNode]?
    public var rect: CGRect = .zero
    public var colorIndex: Int = 0

    public init(
        url: URL,
        name: String,
        size: Int64,
        isDirectory: Bool,
        children: [TreemapNode]? = nil,
        rect: CGRect = .zero,
        colorIndex: Int = 0
    ) {
        self.id = url.path(percentEncoded: false)
        self.url = url
        self.name = name
        self.size = size
        self.isDirectory = isDirectory
        self.children = children
        self.rect = rect
        self.colorIndex = colorIndex
    }

    public var formattedSize: String {
        ByteFormatter.string(from: size)
    }
}
