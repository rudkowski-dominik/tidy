import SwiftUI

public struct JunkCleanerView: View {
    @ObservedObject var appState: AppState

    private var selectedTotalBytes: Int64 {
        appState.junkCategories.reduce(0) { $0 + $1.selectedSize }
    }

    private var selectedItemCount: Int {
        appState.junkCategories.reduce(0) { $0 + $1.selectedCount }
    }

    private var allItemsSelected: Bool {
        guard !appState.junkCategories.isEmpty else { return false }
        return appState.junkCategories.allSatisfy { cat in
            cat.isSelected && cat.items.allSatisfy { $0.isSelected }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar / Action Bar
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 14) {
                    Text("Bezpieczne usuwanie pamięci podręcznej, dzienników, instalatorów i plików Xcode bez naruszania Twoich dokumentów.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 16)

                    // Selection buttons
                    HStack(spacing: 8) {
                        Button {
                            toggleSelectAll()
                        } label: {
                            Label(allItemsSelected ? "Odznacz wszystkie" : "Zaznacz wszystkie",
                                  systemImage: allItemsSelected ? "checkmark.circle.fill" : "checkmark.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .keyboardShortcut("a", modifiers: .command)

                        Button {
                            appState.scanJunkOnly()
                        } label: {
                            Label("Skanuj", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)

                        Button {
                            var urls: [URL] = []
                            for cat in appState.junkCategories {
                                for item in cat.items where item.isSelected {
                                    urls.append(item.url)
                                }
                            }
                            appState.requestDeletion(urls: urls, categoryName: "Śmieci systemowe")
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text(appState.isDryRun ? "Testuj czyszczenie" : "Wyczyść zaznaczone")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(selectedTotalBytes > 0 ? .accentColor : .secondary)
                        .disabled(selectedTotalBytes == 0)
                    }
                }

                // Summary status pill
                HStack(spacing: 8) {
                    Text("Zaznaczono:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(selectedItemCount) elementów")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(ByteFormatter.string(from: selectedTotalBytes))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(selectedTotalBytes > 0 ? Color.accentColor : Color.secondary)

                    Spacer()
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            if appState.junkCategories.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Brak danych śmieci")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Uruchom skanowanie, aby odnaleźć zbędne pliki podręczne, logi i archiwa.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Rozpocznij skanowanie") {
                        appState.scanJunkOnly()
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach($appState.junkCategories) { $cat in
                            JunkCategoryRow(category: $cat)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Śmieci systemowe")
    }

    private func toggleSelectAll() {
        let shouldSelect = !allItemsSelected
        for i in 0..<appState.junkCategories.count {
            appState.junkCategories[i].isSelected = shouldSelect
            for j in 0..<appState.junkCategories[i].items.count {
                appState.junkCategories[i].items[j].isSelected = shouldSelect
            }
        }
        HapticFeedback.triggerSelection()
    }
}
