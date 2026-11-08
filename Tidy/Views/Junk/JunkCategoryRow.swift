import SwiftUI

public struct JunkCategoryRow: View {
    @Binding var category: JunkCategoryItem
    @State private var isExpanded: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 12) {
                Toggle("", isOn: $category.isSelected)
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                    .onChange(of: category.isSelected) { _, newValue in
                        for i in 0..<category.items.count {
                            category.items[i].isSelected = newValue
                        }
                    }

                Image(systemName: category.type.icon)
                    .foregroundStyle(.tint)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(category.type.categoryDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(ByteFormatter.string(from: category.totalSize))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(category.items.count) plików")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Expanded File List
            if isExpanded && !category.items.isEmpty {
                Divider()

                VStack(spacing: 0) {
                    ForEach($category.items) { $item in
                        HStack(spacing: 12) {
                            Toggle("", isOn: $item.isSelected)
                                .labelsHidden()
                                .toggleStyle(.checkbox)
                                .onChange(of: item.isSelected) { _, _ in
                                    // If any item is selected, keep category marked
                                    category.isSelected = category.items.contains { $0.isSelected }
                                }

                            Image(nsImage: FileMetadataHelper.icon(for: item.url))
                                .resizable()
                                .frame(width: 16, height: 16)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)

                                Text(item.url.deletingLastPathComponent().path(percentEncoded: false))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            Text(item.formattedSize)
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Button {
                                QuickLookHelper.revealInFinder(url: item.url)
                            } label: {
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Pokaż w Finderze")
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 6)

                        Divider().padding(.leading, 32)
                    }
                }
                .background(Color.primary.opacity(0.02))
            }
        }
        .tidyGlassCard(cornerRadius: 12)
    }
}
