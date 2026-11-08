import SwiftUI
import AppKit

public struct DuplicatesView: View {
    @ObservedObject var appState: AppState
    @State private var scanFolders: [URL] = DuplicateScanner.defaultScanDirectories

    private var totalWastedBytes: Int64 {
        appState.duplicates.reduce(0) { $0 + $1.wastedBytes }
    }

    private var totalSelectedDuplicatesCount: Int {
        appState.duplicates.reduce(0) { sum, grp in
            sum + grp.files.filter { $0.isSelected }.count
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Action bar
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wyszukiwarka duplikatów")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Wieloetapowa weryfikacja (rozmiar → częściowy hash → SHA-256). Oryginał jest chroniony, zaznaczane są tylko zbędne kopie.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        chooseCustomFolder()
                    } label: {
                        Label("Dodaj folder", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button {
                        appState.scanDuplicatesOnly(directories: scanFolders)
                    } label: {
                        Label("Skanuj", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        var urlsToDelete: [URL] = []
                        for grp in appState.duplicates {
                            for f in grp.files where f.isSelected {
                                urlsToDelete.append(f.url)
                            }
                        }
                        appState.requestDeletion(urls: urlsToDelete, categoryName: "Duplikaty plików")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Usuń kopie")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(totalWastedBytes > 0 ? .orange : .secondary)
                    .disabled(totalWastedBytes == 0)
                }

                if !appState.duplicates.isEmpty {
                    HStack(spacing: 8) {
                        Text("Znaleziono:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(appState.duplicates.count) grup duplikatów")
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Zaznaczono kopii: \(totalSelectedDuplicatesCount)")
                            .font(.caption2)
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Do odzyskania: \(ByteFormatter.string(from: totalWastedBytes))")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            // Scanned Folders Pill Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Skanowane foldery:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(scanFolders, id: \.self) { folder in
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text(folder.lastPathComponent)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.primary.opacity(0.02))

            Divider()

            if appState.duplicates.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("Brak wykrytych duplikatów")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Wybierz foldery i uruchom skanowanie. Tidy używa bezpiecznego, wieloetapowego hashowania (rozmiar → częściowy hash → SHA-256).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)

                    Button("Rozpocznij skanowanie folderów") {
                        appState.scanDuplicatesOnly(directories: scanFolders)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach($appState.duplicates) { $group in
                            DuplicateGroupRow(group: $group)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Duplikaty")
    }

    private func chooseCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Wybierz foldery"

        if panel.runModal() == .OK {
            for url in panel.urls {
                if !scanFolders.contains(url) {
                    scanFolders.append(url)
                }
            }
            appState.scanDuplicatesOnly(directories: scanFolders)
        }
    }
}
