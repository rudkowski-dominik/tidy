import SwiftUI

public struct DuplicateGroupRow: View {
    @Binding var group: DuplicateGroup
    @State private var isExpanded: Bool = true

    public var body: some View {
        VStack(spacing: 0) {
            // Group Header
            HStack(spacing: 12) {
                Image(systemName: "doc.on.doc.fill")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.files.first?.name ?? "Plik")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("\(group.files.count) kopie")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("Rozmiar: \(ByteFormatter.string(from: group.fileSize))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Zbędne: \(ByteFormatter.string(from: group.wastedBytes))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)

                    Text(group.hash.prefix(8) + "...")
                        .font(.system(size: 9, design: .monospaced))
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

            // Files in group
            if isExpanded {
                Divider()

                VStack(spacing: 0) {
                    ForEach($group.files) { $file in
                        let isRecommended = (file.url == group.recommendedKeepURL)

                        HStack(spacing: 12) {
                            Toggle("", isOn: $file.isSelected)
                                .labelsHidden()
                                .toggleStyle(.checkbox)
                                .onChange(of: file.isSelected) { _, newValue in
                                    // If user selects the recommended file for deletion, clear recommendation
                                    if newValue && isRecommended {
                                        // Pick another file as keep if available
                                        if let alternative = group.files.first(where: { $0.url != file.url && !$0.isSelected }) {
                                            group.recommendedKeepURL = alternative.url
                                        }
                                    }
                                }

                            Image(nsImage: FileMetadataHelper.icon(for: file.url))
                                .resizable()
                                .frame(width: 16, height: 16)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(file.name)
                                        .font(.caption)
                                        .fontWeight(isRecommended ? .bold : .regular)

                                    if isRecommended {
                                        Text("Oryginał (Zachowaj)")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(Color.green.opacity(0.2)))
                                            .foregroundStyle(.green)
                                    }
                                }

                                Text(file.url.path(percentEncoded: false))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            if let modDate = file.modificationDate {
                                Text(modDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                QuickLookHelper.preview(url: file.url)
                            } label: {
                                Image(systemName: "eye")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Szybki podgląd")

                            Button {
                                QuickLookHelper.revealInFinder(url: file.url)
                            } label: {
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Pokaż w Finderze")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(isRecommended ? Color.green.opacity(0.04) : Color.clear)

                        Divider().padding(.leading, 24)
                    }
                }
            }
        }
        .tidyGlassCard(cornerRadius: 12)
    }
}
