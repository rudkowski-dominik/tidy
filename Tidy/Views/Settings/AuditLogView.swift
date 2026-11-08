import SwiftUI

public struct AuditLogView: View {
    @State private var entries: [AuditLogEntry] = []
    @State private var isLoading: Bool = true

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dziennik operacji (Audit Log)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Lokalny rejestr wszystkich wykonanych operacji czyszczenia i prób.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    loadLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help("Odśwież wpisy")

                Button("Otwórz plik logu") {
                    Task {
                        let dir = await AuditLogger.shared.logDirectoryURL
                        QuickLookHelper.revealInFinder(url: dir)
                    }
                }
                .buttonStyle(.bordered)

                Button("Wyczyść historię", role: .destructive) {
                    Task {
                        await AuditLogger.shared.clearLogs()
                        loadLogs()
                    }
                }
                .buttonStyle(.bordered)
            }

            Divider()

            if entries.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Brak zarejestrowanych operacji")
                        .font(.headline)
                    Text("Wszystkie przyszłe operacje usuwania do Kosza i testów będą rejestrowane w tym miejscu.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .fontWeight(.semibold)

                            Spacer()

                            Text(entry.mode == .dryRun ? "TRYB PRÓBNY" : (entry.mode == .permanent ? "TRWAŁE" : "KOSZ"))
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(
                                        entry.mode == .dryRun ? Color.blue.opacity(0.2) :
                                        (entry.mode == .permanent ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                                    )
                                )
                                .foregroundStyle(
                                    entry.mode == .dryRun ? Color.blue :
                                    (entry.mode == .permanent ? Color.red : Color.green)
                                )

                            Text(ByteFormatter.string(from: entry.totalBytesFreed))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }

                        HStack(spacing: 12) {
                            Text("Usunięto: \(entry.succeededCount) | Błędy: \(entry.failedCount)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            if !entry.errors.isEmpty {
                                Text("• Błędy: \(entry.errors.first ?? "")")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                            }
                        }

                        if !entry.samplePaths.isEmpty {
                            Text(entry.samplePaths.joined(separator: "\n"))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .padding(8)
                    .tidyGlassCard(cornerRadius: 8)
                }
                .listStyle(.inset)
            }
        }
        .padding()
        .onAppear {
            loadLogs()
        }
    }

    private func loadLogs() {
        Task {
            let loaded = await AuditLogger.shared.loadEntries()
            await MainActor.run {
                self.entries = loaded
                self.isLoading = false
            }
        }
    }
}
