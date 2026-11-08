import SwiftUI

public struct AppDetailSheet: View {
    @Binding var app: InstalledApp
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                if let url = app.appURL {
                    Image(nsImage: FileMetadataHelper.icon(for: url))
                        .resizable()
                        .frame(width: 48, height: 48)
                } else {
                    Image(systemName: "questionmark.app.dashed")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(app.bundleID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(ByteFormatter.string(from: app.selectedSize))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("z \(ByteFormatter.string(from: app.totalSize))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // List of components
            ScrollView {
                VStack(spacing: 12) {
                    // Main App Bundle
                    if let appURL = app.appURL {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pakiet aplikacji (.app)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Toggle("", isOn: $app.isSelected)
                                    .labelsHidden()
                                    .toggleStyle(.checkbox)

                                Image(systemName: "app.fill")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appURL.lastPathComponent)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text(appURL.path(percentEncoded: false))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(ByteFormatter.string(from: app.appBundleSize))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(12)
                            .tidyGlassCard(cornerRadius: 10)
                        }
                    }

                    // Associated Files
                    if !app.associatedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Powiązane pliki i dane (\(app.associatedItems.count))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ForEach($app.associatedItems) { $item in
                                HStack(spacing: 12) {
                                    Toggle("", isOn: $item.isSelected)
                                        .labelsHidden()
                                        .toggleStyle(.checkbox)

                                    Image(systemName: iconForType(item.typeDescription))
                                        .foregroundStyle(.purple)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(item.typeDescription)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }

                                        Text(item.url.path(percentEncoded: false))
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }

                                    Spacer()

                                    Text(ByteFormatter.string(from: item.size))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Button {
                                        QuickLookHelper.revealInFinder(url: item.url)
                                    } label: {
                                        Image(systemName: "arrow.right.circle")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(10)
                                .tidyGlassCard(cornerRadius: 10)
                            }
                        }
                    } else {
                        Text("Brak znalezionych dodatkowych plików konfiguracyjnych w ~/Library.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                    }
                }
                .padding()
            }

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                Button("Zamknij") {
                    dismiss()
                }

                Spacer()

                Button {
                    let urls = app.allSelectedURLs
                    dismiss()
                    appState.requestDeletion(urls: urls, categoryName: "Aplikacja: \(app.name)")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Usuń wybrane elementy (\(ByteFormatter.string(from: app.selectedSize)))")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(app.selectedSize > 0 ? .red : .secondary)
                .disabled(app.selectedSize == 0)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .frame(width: 580, height: 500)
    }

    private func iconForType(_ desc: String) -> String {
        switch desc {
        case "Application Support": return "folder.badge.gearshape"
        case "Caches": return "cylinder.split.1x2"
        case "Preferences": return "slider.horizontal.3"
        case "Containers": return "shippingbox"
        case "Launch Agent": return "bolt.shield"
        default: return "doc"
        }
    }
}
