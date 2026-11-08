import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var iconManager = AppIconManager.shared
    @AppStorage("tidy_show_menu_bar_extra") private var showMenuBarExtra: Bool = false
    @State private var selectedTab: Int = 0 // 0: Ogólne i Bezpieczeństwo, 1: Dziennik operacji

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar (No duplicate "Ustawienia" title; window titlebar already shows it)
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Dostosuj tryb działania aplikacji, uprawnienia systemowe oraz historię operacji.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Picker("", selection: $selectedTab) {
                    Text("Opcje i bezpieczeństwo").tag(0)
                    Text("Dziennik operacji").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)

            Divider()

            if selectedTab == 0 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Safety & Mode Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tryby działania i bezpieczeństwo")
                                .font(.headline)

                            VStack(spacing: 14) {
                                HStack(alignment: .center, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Tryb próbny (Dry Run)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Aplikacja symuluje proces czyszczenia i zapisuje wyniki w dzienniku bez fizycznego usuwania jakichkolwiek plików z dysku.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 16)

                                    Toggle("", isOn: $appState.isDryRun)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                }

                                Divider()

                                HStack(alignment: .center, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Zezwalaj na trwałe usuwanie (Opcjonalne)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Domyślnie wszystkie pliki trafiają do systemowego Kosza (można je przywrócić). Włączenie tej opcji udostępnia wybór natychmiastowego skasowania.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 16)

                                    Toggle("", isOn: $appState.allowPermanentDeletion)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                }
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }

                        // Appearance & Icon Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Wygląd i ikona programu")
                                .font(.headline)

                            VStack(spacing: 14) {
                                HStack(alignment: .center, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Motyw ikony w Docku")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Wybierz styl ikony: automatycznie dopasowany do motywu macOS, dedykowany ciemny lub jasny.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 16)

                                    Picker("", selection: $iconManager.selectedTheme) {
                                        ForEach(AppIconTheme.allCases) { theme in
                                            Text(theme.rawValue).tag(theme.rawValue)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 190)
                                }

                                Divider()

                                HStack(alignment: .center, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Ikona w pasku menu (Menu Bar)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Wyświetlaj Tidy w górnym pasku systemowym z szybkim podglądem wolnego miejsca i skrótem do skanowania.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 16)

                                    Toggle("", isOn: $showMenuBarExtra)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                }
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }

                        // Full Disk Access Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Uprawnienia macOS")
                                .font(.headline)

                            HStack(alignment: .center, spacing: 16) {
                                Image(systemName: appState.hasFullDiskAccess ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(appState.hasFullDiskAccess ? .green : .orange)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(appState.hasFullDiskAccess ? "Pełny dostęp do dysku jest aktywny" : "Wymagane nadanie Pełnego dostępu do dysku")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text("Umożliwia wykrywanie pamięci podręcznych przeglądarek, logów oraz pozostałości po usuniętych programach.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 16)

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
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reguły integralności systemu (Ochrona danych)")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tidy posiada twardo zakodowaną listę ścieżek, których aplikacja nigdy nie modyfikuje:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 6) {
                                    ProtectedRuleRow(label: "Katalogi systemowe", detail: "/System, /usr, /bin, /sbin, /Library, /private")
                                    ProtectedRuleRow(label: "Chmura i tożsamość", detail: "~/Library/Mobile Documents (iCloud Drive), ~/Library/Keychains")
                                    ProtectedRuleRow(label: "Komunikacja i zdjęcia", detail: "~/Library/Messages, ~/Library/Mail, biblioteki Photos (*.photoslibrary)")
                                    ProtectedRuleRow(label: "Główne foldery użytkownika", detail: "Katalog domowy, Biurko, Dokumenty, Pobrane (jako całe foldery)")
                                }
                                .padding(12)
                                .background(Color.primary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }

                        // About Tidy
                        VStack(alignment: .leading, spacing: 10) {
                            Text("O programie")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Tidy")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("Wersja 1.0.1")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("Uczciwa, lekka i bezpieczna alternatywa dla płatnych rozwiązań. Napisana w 100% w natywnym kodzie Swift i SwiftUI. Bez reklam, bez subskrypcji, bez telemetrii i bez dodatkowych procesów w tle.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .tidyGlassCard(cornerRadius: 12)
                        }
                    }
                    .padding(20)
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
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
