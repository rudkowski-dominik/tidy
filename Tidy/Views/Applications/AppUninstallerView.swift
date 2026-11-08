import SwiftUI

public struct AppUninstallerView: View {
    @ObservedObject var appState: AppState

    @State private var searchText: String = ""
    @State private var selectedTab: Int = 0 // 0: Installed Apps, 1: Leftovers
    @State private var inspectingApp: InstalledApp? = nil

    private var filteredInstalledApps: [InstalledApp] {
        if searchText.isEmpty {
            return appState.installedApps
        }
        return appState.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredOrphanedApps: [InstalledApp] {
        if searchText.isEmpty {
            return appState.orphanedApps
        }
        return appState.orphanedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var orphanedTotalBytes: Int64 {
        appState.orphanedApps.reduce(0) { $0 + $1.totalSize }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 14) {
                    Text("Kompletne usuwanie aplikacji wraz z plikami z Biblioteki oraz sprzątanie danych po dawno skasowanych programach.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 16)

                    HStack(spacing: 8) {
                        Button {
                            appState.scanAppsOnly()
                        } label: {
                            Label("Skanuj", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)

                        if selectedTab == 1 && orphanedTotalBytes > 0 {
                            Button {
                                var urls: [URL] = []
                                for orphan in appState.orphanedApps {
                                    urls.append(contentsOf: orphan.allSelectedURLs)
                                }
                                appState.requestDeletion(urls: urls, categoryName: "Pozostałości po aplikacjach")
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Usuń wszystkie pozostałości")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                    }
                }

                // Row 2: Tabs switcher & Search
                HStack(spacing: 16) {
                    Picker("", selection: $selectedTab) {
                        Text("Zainstalowane programy (\(appState.installedApps.count))").tag(0)
                        Text("Pozostałości po aplikacjach (\(appState.orphanedApps.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)

                    Spacer()

                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Szukaj programu...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.caption)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(width: 220)
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // Explanatory Banner for Leftovers tab
            if selectedTab == 1 && !appState.orphanedApps.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Czym są pozostałości po aplikacjach?")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Gdy usuwasz aplikację przeciągając ją do Kosza, system często zostawia jej foldery w ~/Library. Poniżej znajdują się pliki programów, których już nie ma na Twoim Macu.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(10)
                .background(Color.purple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // List Content
            if selectedTab == 0 {
                if filteredInstalledApps.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "app.dashed")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Brak aplikacji spełniających kryteria")
                            .font(.headline)
                        Spacer()
                    }
                } else {
                    List(filteredInstalledApps) { app in
                        AppRowItem(app: app) {
                            inspectingApp = app
                        }
                    }
                    .listStyle(.inset)
                }
            } else {
                if filteredOrphanedApps.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("Brak zbędnych pozostałości")
                            .font(.headline)
                        Text("Wszystkie foldery konfiguracyjne i pamięci podręczne w ~/Library należą do aktualnie zainstalowanych programów.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    List(filteredOrphanedApps) { orphan in
                        AppRowItem(app: orphan) {
                            inspectingApp = orphan
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .navigationTitle("Aplikacje")
        .sheet(item: $inspectingApp) { app in
            if let idx = appState.installedApps.firstIndex(where: { $0.id == app.id }) {
                AppDetailSheet(app: $appState.installedApps[idx], appState: appState)
            } else if let idx = appState.orphanedApps.firstIndex(where: { $0.id == app.id }) {
                AppDetailSheet(app: $appState.orphanedApps[idx], appState: appState)
            }
        }
    }
}

private struct AppRowItem: View {
    let app: InstalledApp
    let onInspect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if let url = app.appURL {
                Image(nsImage: FileMetadataHelper.icon(for: url))
                    .resizable()
                    .frame(width: 36, height: 36)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "folder.badge.questionmark")
                        .foregroundStyle(.purple)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    Text(app.bundleID)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if !app.associatedItems.isEmpty {
                        Text("• \(app.associatedItems.count) powiązanych plików")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    if let lastUsed = app.lastUsedDate {
                        Text("• Ostatnio: \(lastUsed.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(ByteFormatter.string(from: app.totalSize))
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text(app.isOrphaned ? "Pozostałość" : "Łączny rozmiar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button("Szczegóły") {
                onInspect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
