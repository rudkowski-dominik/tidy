import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: Int = 0 // 0: Ogólne i Bezpieczeństwo, 1: Dziennik operacji

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ustawienia")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Dostosuj tryb działania aplikacji, sprawdź uprawnienia oraz przejrzyj historię operacji.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("", selection: $selectedTab) {
                    Text("Opcje i bezpieczeństwo").tag(0)
                    Text("Dziennik operacji").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            if selectedTab == 0 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Safety & Mode Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tryby działania i bezpieczeństwo")
                                .font(.headline)

                            VStack(spacing: 14) {
                                Toggle(isOn: $appState.isDryRun) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Tryb próbny (Dry Run)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Aplikacja symuluje proces czyszczenia i zapisuje wyniki w dzienniku bez fizycznego usuwania jakichkolwiek plików z dysku.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .toggleStyle(.switch)

                                Divider()

                                Toggle(isOn: $appState.allowPermanentDeletion) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Zezwalaj na trwałe usuwanie (Opcjonalne)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Domyślnie wszystkie pliki trafiają do systemowego Kosza (można je przywrócić). Włączenie tej opcji udostępnia wybór natychmiastowego skasowania.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .toggleStyle(.switch)
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }

                        // Full Disk Access Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Uprawnienia macOS")
                                .font(.headline)

                            HStack(alignment: .center, spacing: 14) {
                                Image(systemName: appState.hasFullDiskAccess ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(appState.hasFullDiskAccess ? .green : .orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appState.hasFullDiskAccess ? "Pełny dostęp do dysku jest aktywny" : "Wymagane nadanie Pełnego dostępu do dysku")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text("Umożliwia wykrywanie pamięci podręcznych przeglądarek, logów oraz pozostałości po usuniętych programach.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button(appState.hasFullDiskAccess ? "Otwórz Ustawienia" : "Skonfiguruj uprawnienia") {
                                    FullDiskAccessChecker.shared.openSystemSettings()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(appState.hasFullDiskAccess ? .secondary : .accentColor)
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }

                        // Protected Paths Information
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reguły integralności systemu (Ochrona danych)")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tidy posiada twardo zakodowaną listę ścieżek, których aplikacja nigdy nie dotyka:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 6) {
                                    ProtectedRuleRow(label: "Katalogi systemowe", detail: "/System, /usr, /bin, /sbin, /Library, /private")
                                    ProtectedRuleRow(label: "Chmura i tożsamość", detail: "~/Library/Mobile Documents (iCloud Drive), ~/Library/Keychains")
                                    ProtectedRuleRow(label: "Komunikacja i zdjęcia", detail: "~/Library/Messages, ~/Library/Mail, biblioteki Photos (*.photoslibrary)")
                                    ProtectedRuleRow(label: "Główne foldery użytkownika", detail: "Katalog domowy, Biurko, Dokumenty, Pobrane (jako całe foldery)")
                                }
                                .padding(10)
                                .background(Color.primary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }

                        // About Tidy
                        VStack(alignment: .leading, spacing: 12) {
                            Text("O programie")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Tidy")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("Wersja 1.0.0")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("Uczciwa, lekka i bezpieczna alternatywa dla płatnych rozwiązań. Napisana w 100% w natywnym kodzie Swift i SwiftUI. Bez reklam, bez subskrypcji, bez telemetrii i bez dodatkowych procesów w tle.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 800)
                }
            } else {
                AuditLogView()
            }
        }
        .navigationTitle("Ustawienia")
    }
}

private struct ProtectedRuleRow: View {
    let label: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.caption2)
                .foregroundStyle(.green)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
