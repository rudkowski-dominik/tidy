import SwiftUI

public struct OverviewView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FullDiskAccessBanner()

                // Disk Space Ring & Headline
                HStack(spacing: 32) {
                    DiskSpaceRingView(
                        usedBytes: appState.diskInfo.usedSpace,
                        freeBytes: appState.diskInfo.freeSpace,
                        totalBytes: appState.diskInfo.totalCapacity,
                        ringSize: 200,
                        lineWidth: 20,
                        showsInnerLabels: true
                    )
                    .padding(8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stan Twojego Maca")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text("Tidy to minimalistyczne, w 100% lokalne narzędzie do utrzymywania porządku na dysku. Żadnych ukrytych procesów, żadnej telemetrii, pełna prywatność Twoich danych.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Scan Action Area
                        HStack(spacing: 14) {
                            if appState.isScanning {
                                Button("Anuluj skanowanie") {
                                    appState.cancelScan()
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            } else {
                                Button {
                                    appState.scanAll()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                        Text("Skanuj Maca")
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .keyboardShortcut("r", modifiers: .command)
                            }

                            if let lastScan = appState.scanSummary.lastScanDate {
                                Text("Ostatnio: \(lastScan.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(24)
                .tidyGlassCard(cornerRadius: 18)

                // Progress Bar while scanning
                if appState.isScanning {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(appState.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", appState.scanProgress * 100))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        ProgressView(value: appState.scanProgress)
                            .progressViewStyle(.linear)
                    }
                    .padding()
                    .tidyGlassCard(cornerRadius: 12)
                }

                // Category Summary Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    CategoryCard(
                        title: "Śmieci systemowe i aplikacji",
                        subtitle: "Pamięć podręczna, logi, Xcode, instalatory",
                        icon: "trash.circle.fill",
                        color: .blue,
                        size: appState.scanSummary.junkBytes,
                        actionTitle: "Przejdź do śmieci"
                    ) {
                        appState.selectedSection = .junk
                    }

                    CategoryCard(
                        title: "Wykryte duplikaty",
                        subtitle: "Identyczne kopie plików w dokumentach i pobranych",
                        icon: "doc.on.doc.fill",
                        color: .orange,
                        size: appState.scanSummary.duplicatesBytes,
                        actionTitle: "Przejrzyj duplikaty"
                    ) {
                        appState.selectedSection = .duplicates
                    }

                    CategoryCard(
                        title: "Duże i nieużywane pliki",
                        subtitle: "Pliki > 100 MB i programy nieotwierane od miesięcy",
                        icon: "arrow.up.and.down.circle.fill",
                        color: .purple,
                        size: appState.scanSummary.largeFilesBytes,
                        actionTitle: "Pokaż duże pliki"
                    ) {
                        appState.selectedSection = .largeFiles
                    }

                    CategoryCard(
                        title: "Aplikacje i pozostałości",
                        subtitle: "Zarządzanie programami i osieroconymi plikami",
                        icon: "app.badge.fill",
                        color: .indigo,
                        size: appState.scanSummary.uninstallerBytes,
                        actionTitle: "Zarządzaj aplikacjami"
                    ) {
                        appState.selectedSection = .applications
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Przegląd")
    }
}

private struct CategoryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let size: Int64
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }

                Spacer()

                Text(ByteFormatter.string(from: size))
                    .font(.title3)
                    .fontWeight(.bold)
                    .contentTransition(.numericText())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(actionTitle) {
                onAction()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(16)
        .frame(height: 160)
        .tidyGlassCard(cornerRadius: 14)
    }
}
