import SwiftUI
import QuickLook

public struct LargeFilesView: View {
    @ObservedObject var appState: AppState

    @State private var minSizeMB: Double = 100.0 // Default 100 MB
    @State private var selectedCategory: FileCategory = .all
    @State private var selectedTab: Int = 0 // 0: Large Files, 1: Unused Apps
    @State private var unusedMonths: Int = 3
    @State private var previewURL: URL? = nil

    private var filteredLargeFiles: [FileItem] {
        appState.largeFiles.filter { item in
            let matchesCategory = (selectedCategory == .all || item.category == selectedCategory)
            let matchesSize = item.size >= Int64(minSizeMB * 1024 * 1024)
            return matchesCategory && matchesSize
        }
    }

    private var selectedFilesBytes: Int64 {
        filteredLargeFiles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    private var selectedFilesCount: Int {
        filteredLargeFiles.filter { $0.isSelected }.count
    }

    private var allFilteredSelected: Bool {
        guard !filteredLargeFiles.isEmpty else { return false }
        return filteredLargeFiles.allSatisfy { $0.isSelected }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            VStack(alignment: .leading, spacing: 12) {
                // Row 1: Subtitle & Main Action Buttons
                HStack(alignment: .center, spacing: 14) {
                    Text("Wyszukuj pliki zajmujące najwięcej miejsca na dysku oraz rzadko otwierane programy.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 16)

                    HStack(spacing: 8) {
                        Button {
                            appState.scanLargeFilesOnly(minSize: Int64(minSizeMB * 1024 * 1024))
                        } label: {
                            Label("Skanuj", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)

                        if selectedTab == 0 {
                            Button {
                                let urls = filteredLargeFiles.filter { $0.isSelected }.map { $0.url }
                                appState.requestDeletion(urls: urls, categoryName: "Duże pliki")
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Usuń zaznaczone")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedFilesBytes > 0 ? .purple : .secondary)
                            .disabled(selectedFilesBytes == 0)
                            .keyboardShortcut(.delete, modifiers: [])
                        }
                    }
                    .layoutPriority(1)
                }

                // Row 2: Segmented Switcher & Stats
                HStack(spacing: 14) {
                    Picker("", selection: $selectedTab) {
                        Text("Duże pliki (\(filteredLargeFiles.count))").tag(0)
                        Text("Nieużywane programy (\(appState.unusedApps.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 340)

                    Spacer()

                    if selectedTab == 0 && selectedFilesBytes > 0 {
                        Text("Zaznaczono: \(selectedFilesCount) (\(ByteFormatter.string(from: selectedFilesBytes)))")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.purple)
                    }
                }

                // Row 3: Dedicated Filter Strip (No horizontal crowding!)
                if selectedTab == 0 {
                    HStack(spacing: 16) {
                        // Category Picker with ample room
                        HStack(spacing: 6) {
                            Text("Typ:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("", selection: $selectedCategory) {
                                ForEach(FileCategory.allCases) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(minWidth: 140)
                        }

                        Divider().frame(height: 16)

                        // Threshold Slider with plenty of space
                        HStack(spacing: 8) {
                            Text("Próg: > \(Int(minSizeMB)) MB")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Slider(value: $minSizeMB, in: 25...1000, step: 25)
                                .frame(width: 140)
                        }

                        Spacer()

                        if !filteredLargeFiles.isEmpty {
                            Button {
                                toggleSelectAllLargeFiles()
                            } label: {
                                Label(allFilteredSelected ? "Odznacz wszystkie" : "Zaznacz wszystkie",
                                      systemImage: allFilteredSelected ? "checkmark.circle.fill" : "checkmark.circle")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 12) {
                        Text("Nieużywane od:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("", selection: $unusedMonths) {
                            Text("1 miesiąca").tag(1)
                            Text("3 miesięcy").tag(3)
                            Text("6 miesięcy").tag(6)
                            Text("1 roku").tag(12)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                        .onChange(of: unusedMonths) { _, _ in
                            Task {
                                let apps = await LargeFilesScanner.shared.scanUnusedApps(olderThanMonths: unusedMonths)
                                appState.unusedApps = apps
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)

            Divider()

            // Content Area
            if selectedTab == 0 {
                if filteredLargeFiles.isEmpty {
                    EmptyStateView(
                        icon: "arrow.up.and.down.circle",
                        title: "Brak dużych plików",
                        subtitle: "Zmień próg rozmiaru lub uruchom skanowanie."
                    )
                } else {
                    List {
                        ForEach($appState.largeFiles) { $item in
                            if selectedCategory == .all || item.category == selectedCategory {
                                if item.size >= Int64(minSizeMB * 1024 * 1024) {
                                    LargeFileRow(item: $item, onPreview: { url in
                                        self.previewURL = url
                                    })
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            } else {
                if appState.unusedApps.isEmpty {
                    EmptyStateView(
                        icon: "app.badge.checkmark",
                        title: "Wszystkie aplikacje są aktywnie używane",
                        subtitle: "Nie znaleziono programów nieotwieranych od ponad \(unusedMonths) miesięcy."
                    )
                } else {
                    List {
                        ForEach($appState.unusedApps) { $appItem in
                            UnusedAppRow(appItem: $appItem, onUninstall: {
                                appState.selectedSection = .applications
                            })
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .navigationTitle("Duże i nieużywane")
        .quickLookPreview($previewURL)
    }

    private func toggleSelectAllLargeFiles() {
        let shouldSelect = !allFilteredSelected
        for i in 0..<appState.largeFiles.count {
            let item = appState.largeFiles[i]
            let matchesCategory = (selectedCategory == .all || item.category == selectedCategory)
            let matchesSize = item.size >= Int64(minSizeMB * 1024 * 1024)
            if matchesCategory && matchesSize {
                appState.largeFiles[i].isSelected = shouldSelect
            }
        }
        HapticFeedback.triggerSelection()
    }
}

private struct LargeFileRow: View {
    @Binding var item: FileItem
    var onPreview: ((URL) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $item.isSelected)
                .labelsHidden()
                .toggleStyle(.checkbox)

            Image(nsImage: FileMetadataHelper.icon(for: item.url))
                .resizable()
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))

                    if let access = item.lastAccessDate {
                        Text("Ostatnio otwarty: \(access.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(item.url.deletingLastPathComponent().path(percentEncoded: false))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            Text(item.formattedSize)
                .font(.subheadline)
                .fontWeight(.bold)

            Button {
                onPreview?(item.url)
            } label: {
                Image(systemName: "eye")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Szybki podgląd (Quick Look)")

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
        .padding(.vertical, 4)
    }
}

private struct UnusedAppRow: View {
    @Binding var appItem: UnusedAppItem
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: FileMetadataHelper.icon(for: appItem.url))
                .resizable()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(appItem.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    Text(appItem.bundleID)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let used = appItem.lastUsedDate {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Użyty: \(used.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Text(appItem.formattedSize)
                .font(.subheadline)
                .fontWeight(.semibold)

            Button("Szczegóły") {
                onUninstall()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 6)
    }
}

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
