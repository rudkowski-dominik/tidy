import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct AuditLogView: View {
    @State private var entries: [AuditLogEntry] = []
    @State private var isLoading: Bool = true
    @State private var statusAlertMessage: String? = nil
    @State private var isShowingAlert: Bool = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Bar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dziennik operacji i audyt")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Lokalny rejestr wszystkich wykonanych operacji z możliwością przywrócenia plików z Kosza.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Zapisz jako CSV...", systemImage: "tablecells")
                    }

                    Button {
                        exportJSON()
                    } label: {
                        Label("Zapisz jako JSON...", systemImage: "curlybraces")
                    }

                    Divider()

                    Button {
                        copyToClipboard()
                    } label: {
                        Label("Kopiuj do schowka", systemImage: "doc.on.doc")
                    }
                } label: {
                    Label("Eksportuj", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    loadLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help("Odśwież wpisy")

                Button("Otwórz folder logów") {
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
            .padding(.horizontal)
            .padding(.top, 10)

            Divider()

            if entries.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Brak zarejestrowanych operacji")
                        .font(.headline)
                    Text("Wszystkie przyszłe operacje czyszczenia będą rejestrowane w tym miejscu z opcją przywrócenia z Kosza.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center) {
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
                                        entry.mode == .dryRun ? Color.blue.opacity(0.18) :
                                        (entry.mode == .permanent ? Color.red.opacity(0.18) : Color.green.opacity(0.18))
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
                                Text("• Błąd: \(entry.errors.first ?? "")")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Restore button / status
                            if entry.canRestore {
                                Button {
                                    restore(entry: entry)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                        Text("Przywróć z Kosza")
                                    }
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                                .controlSize(.small)
                            } else if entry.isFullyRestored {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Przywrócono na dysk")
                                }
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                            }
                        }

                        if !entry.samplePaths.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(entry.samplePaths.prefix(3), id: \.self) { path in
                                    Text(path)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .tidyGlassCard(cornerRadius: 10)
                }
                .listStyle(.inset)
            }
        }
        .padding(.bottom, 8)
        .alert(statusAlertMessage ?? "Informacja", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) {}
        }
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

    private func restore(entry: AuditLogEntry) {
        Task {
            let result = await AuditLogger.shared.restore(entryID: entry.id)
            await MainActor.run {
                loadLogs()
                AppState.shared.refreshDiskInfo()
                if result.missing == 0 {
                    self.statusAlertMessage = "Pomyślnie przywrócono \(result.restored) plików z Kosza na oryginalne ścieżki."
                } else if result.restored > 0 {
                    self.statusAlertMessage = "Przywrócono \(result.restored) plików. Nie odnaleziono \(result.missing) plików (prawdopodobnie Kosz został już wcześniej opróżniony)."
                } else {
                    self.statusAlertMessage = "Nie można przywrócić plików: elementy nie znajdują się już w Koszu."
                }
                self.isShowingAlert = true
            }
        }
    }

    private func exportCSV() {
        Task {
            let csv = await AuditLogger.shared.exportCSV()
            await MainActor.run {
                let panel = NSSavePanel()
                panel.title = "Eksportuj historię audytu Tidy do CSV"
                panel.nameFieldStringValue = "tidy_audit_log.csv"
                panel.allowedContentTypes = [.commaSeparatedText]
                panel.canCreateDirectories = true

                if panel.runModal() == .OK, let targetURL = panel.url {
                    try? csv.write(to: targetURL, atomically: true, encoding: .utf8)
                }
            }
        }
    }

    private func exportJSON() {
        Task {
            let json = await AuditLogger.shared.exportJSON()
            await MainActor.run {
                let panel = NSSavePanel()
                panel.title = "Eksportuj historię audytu Tidy do JSON"
                panel.nameFieldStringValue = "tidy_audit_log.json"
                panel.allowedContentTypes = [.json]
                panel.canCreateDirectories = true

                if panel.runModal() == .OK, let targetURL = panel.url {
                    try? json.write(to: targetURL, atomically: true, encoding: .utf8)
                }
            }
        }
    }

    private func copyToClipboard() {
        Task {
            let csv = await AuditLogger.shared.exportCSV()
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(csv, forType: .string)
                self.statusAlertMessage = "Skopiowano historię operacji do schowka systemowego."
                self.isShowingAlert = true
            }
        }
    }
}
