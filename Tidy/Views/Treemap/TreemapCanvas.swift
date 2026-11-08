import SwiftUI

public struct TreemapCanvas: View {
    public let nodes: [TreemapNode]
    public let onSelect: (TreemapNode) -> Void
    public let onDelete: (TreemapNode) -> Void
    public let onReveal: (TreemapNode) -> Void

    @State private var hoveredNode: TreemapNode? = nil

    private let palette: [Color] = [
        Color.blue,
        Color.indigo,
        Color.purple,
        Color.cyan,
        Color.teal,
        Color.mint,
        Color.orange,
        Color.pink
    ]

    public var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let _ = TreemapScanner.layoutSquarified(nodes: nodes, in: rect)

            ZStack(alignment: .topLeading) {
                ForEach(nodes) { node in
                    if node.rect.width > 2 && node.rect.height > 2 {
                        let color = palette[node.colorIndex % palette.count]
                        let isHovered = (hoveredNode?.id == node.id)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(color.opacity(isHovered ? 0.35 : 0.20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(color.opacity(isHovered ? 0.9 : 0.4), lineWidth: isHovered ? 2 : 1)
                                )

                            if node.rect.width > 50 && node.rect.height > 35 {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        if node.isDirectory {
                                            Image(systemName: "folder.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(color)
                                        }
                                        Text(node.name)
                                            .font(.system(size: 11, weight: .semibold))
                                            .lineLimit(1)
                                    }

                                    Text(node.formattedSize)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(6)
                            }
                        }
                        .frame(width: max(0, node.rect.width - 2), height: max(0, node.rect.height - 2))
                        .offset(x: node.rect.minX + 1, y: node.rect.minY + 1)
                        .onHover { hovering in
                            if hovering {
                                hoveredNode = node
                            } else if hoveredNode?.id == node.id {
                                hoveredNode = nil
                            }
                        }
                        .onTapGesture {
                            onSelect(node)
                        }
                        .contextMenu {
                            if node.isDirectory {
                                Button("Otwórz folder (Drill-down)") {
                                    onSelect(node)
                                }
                            }
                            Button("Pokaż w Finderze") {
                                onReveal(node)
                            }
                            Button("Szybki podgląd") {
                                QuickLookHelper.preview(url: node.url)
                            }
                            Divider()
                            Button("Przenieś do Kosza", role: .destructive) {
                                onDelete(node)
                            }
                        }
                    }
                }

                // Hover Info Pill at bottom
                if let hovered = hoveredNode {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: hovered.isDirectory ? "folder.fill" : "doc.fill")
                                .font(.caption)
                            Text(hovered.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(hovered.formattedSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(hovered.url.path(percentEncoded: false))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .tidyGlassControl(cornerRadius: 8)
                        .padding(12)
                    }
                }
            }
        }
    }
}
