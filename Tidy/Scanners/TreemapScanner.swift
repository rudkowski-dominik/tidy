import Foundation
import CoreGraphics

public actor TreemapScanner {
    public static let shared = TreemapScanner()

    private let fileManager = FileManager.default

    private init() {}

    /// Builds a Treemap hierarchy for a given root URL up to a maximum depth.
    public func scan(
        rootURL: URL,
        maxDepth: Int = 3,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> TreemapNode {
        progress?(0.1, "Analiza zawartości folderu...")
        let rootNode = buildNode(for: rootURL, currentDepth: 0, maxDepth: maxDepth)
        progress?(1.0, "Ukończono mapowanie folderu")
        return rootNode
    }

    private func buildNode(for url: URL, currentDepth: Int, maxDepth: Int) -> TreemapNode {
        let name = url.lastPathComponent.isEmpty ? url.path(percentEncoded: false) : url.lastPathComponent
        var isDir: ObjCBool = false

        guard fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDir) else {
            return TreemapNode(url: url, name: name, size: 0, isDirectory: false)
        }

        if !isDir.boolValue || FileMetadataHelper.isFilePackage(at: url) {
            let size = FileMetadataHelper.itemSize(at: url)
            return TreemapNode(url: url, name: name, size: size, isDirectory: false)
        }

        if currentDepth >= maxDepth {
            let size = FileMetadataHelper.itemSize(at: url)
            return TreemapNode(url: url, name: name, size: size, isDirectory: true)
        }

        let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey]
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            let size = FileMetadataHelper.itemSize(at: url)
            return TreemapNode(url: url, name: name, size: size, isDirectory: true)
        }

        var children: [TreemapNode] = []
        var totalSize: Int64 = 0

        for childURL in contents {
            if Task.isCancelled { break }
            if ProtectedPaths.isProtected(url: childURL) { continue }

            let childNode = buildNode(for: childURL, currentDepth: currentDepth + 1, maxDepth: maxDepth)
            if childNode.size > 0 {
                children.append(childNode)
                totalSize += childNode.size
            }
        }

        children.sort { $0.size > $1.size }

        // Assign palette color indices
        for (idx, child) in children.enumerated() {
            child.colorIndex = idx % 8
        }

        return TreemapNode(
            url: url,
            name: name,
            size: totalSize,
            isDirectory: true,
            children: children
        )
    }

    /// Computes squarified treemap layout for a list of nodes within a given CGRect.
    public static func layoutSquarified(nodes: [TreemapNode], in rect: CGRect) {
        guard !nodes.isEmpty, rect.width > 0, rect.height > 0 else { return }

        let totalValue = Double(nodes.reduce(0) { $0 + $1.size })
        guard totalValue > 0 else { return }

        let normalizedValues = nodes.map { (Double($0.size) / totalValue) * Double(rect.width * rect.height) }
        var remainingRect = rect

        var currentIndex = 0
        while currentIndex < nodes.count {
            var row: [Int] = [currentIndex]
            var bestWorstRatio = worstRatio(row: row, values: normalizedValues, side: min(Double(remainingRect.width), Double(remainingRect.height)))

            for nextIndex in (currentIndex + 1)..<nodes.count {
                var candidateRow = row
                candidateRow.append(nextIndex)
                let ratio = worstRatio(row: candidateRow, values: normalizedValues, side: min(Double(remainingRect.width), Double(remainingRect.height)))
                if ratio <= bestWorstRatio {
                    bestWorstRatio = ratio
                    row = candidateRow
                } else {
                    break
                }
            }

            // Layout row
            remainingRect = layoutRow(row: row, nodes: nodes, values: normalizedValues, in: remainingRect)
            currentIndex += row.count
        }
    }

    private static func worstRatio(row: [Int], values: [Double], side: Double) -> Double {
        guard side > 0 else { return Double.infinity }
        let rowSum = row.reduce(0.0) { $0 + values[$1] }
        guard rowSum > 0 else { return Double.infinity }

        let s2 = side * side
        let rowSum2 = rowSum * rowSum

        var maxRatio: Double = 0
        for idx in row {
            let v = values[idx]
            guard v > 0 else { continue }
            let r1 = (s2 * v) / rowSum2
            let r2 = rowSum2 / (s2 * v)
            let ratio = max(r1, r2)
            if ratio > maxRatio {
                maxRatio = ratio
            }
        }
        return maxRatio
    }

    private static func layoutRow(row: [Int], nodes: [TreemapNode], values: [Double], in rect: CGRect) -> CGRect {
        let isHorizontal = rect.width >= rect.height
        let side = isHorizontal ? Double(rect.height) : Double(rect.width)
        let rowSum = row.reduce(0.0) { $0 + values[$1] }
        guard side > 0, rowSum > 0 else { return rect }

        let rowLength = CGFloat(rowSum / side)
        var offset: CGFloat = 0

        for idx in row {
            let v = values[idx]
            let itemLength = CGFloat(v / rowSum) * CGFloat(side)

            if isHorizontal {
                nodes[idx].rect = CGRect(
                    x: rect.minX,
                    y: rect.minY + offset,
                    width: rowLength,
                    height: itemLength
                )
            } else {
                nodes[idx].rect = CGRect(
                    x: rect.minX + offset,
                    y: rect.minY,
                    width: itemLength,
                    height: rowLength
                )
            }
            offset += itemLength
        }

        if isHorizontal {
            return CGRect(
                x: rect.minX + rowLength,
                y: rect.minY,
                width: max(0, rect.width - rowLength),
                height: rect.height
            )
        } else {
            return CGRect(
                x: rect.minX,
                y: rect.minY + rowLength,
                width: rect.width,
                height: max(0, rect.height - rowLength)
            )
        }
    }
}
