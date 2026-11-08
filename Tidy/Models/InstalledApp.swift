import Foundation
import AppKit

public struct AppAssociatedItem: Identifiable, Sendable {
    public let id: String
    public let url: URL
    public let size: Int64
    public let typeDescription: String
    public var isSelected: Bool

    public init(url: URL, size: Int64, typeDescription: String, isSelected: Bool = true) {
        self.id = url.path(percentEncoded: false)
        self.url = url
        self.size = size
        self.typeDescription = typeDescription
        self.isSelected = isSelected
    }
}

public struct InstalledApp: Identifiable, Sendable {
    public let id: String
    public let bundleID: String
    public let name: String
    public let appURL: URL?
    public let appBundleSize: Int64
    public let lastUsedDate: Date?
    public var associatedItems: [AppAssociatedItem]
    public let isOrphaned: Bool
    public var isSelected: Bool

    public init(
        id: String,
        bundleID: String,
        name: String,
        appURL: URL?,
        appBundleSize: Int64,
        lastUsedDate: Date?,
        associatedItems: [AppAssociatedItem] = [],
        isOrphaned: Bool = false,
        isSelected: Bool = false
    ) {
        self.id = id
        self.bundleID = bundleID
        self.name = name
        self.appURL = appURL
        self.appBundleSize = appBundleSize
        self.lastUsedDate = lastUsedDate
        self.associatedItems = associatedItems
        self.isOrphaned = isOrphaned
        self.isSelected = isSelected
    }

    public var totalSize: Int64 {
        appBundleSize + associatedItems.reduce(0) { $0 + $1.size }
    }

    public var selectedSize: Int64 {
        let appPart = (isSelected && appURL != nil) ? appBundleSize : 0
        let itemsPart = associatedItems.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        return appPart + itemsPart
    }

    public var allSelectedURLs: [URL] {
        var result: [URL] = []
        if isSelected, let appURL = appURL {
            result.append(appURL)
        }
        for item in associatedItems where item.isSelected {
            result.append(item.url)
        }
        return result
    }
}
