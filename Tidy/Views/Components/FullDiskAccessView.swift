import SwiftUI

public struct FullDiskAccessBanner: View {
    @ObservedObject var checker = FullDiskAccessChecker.shared
    @ObservedObject var appState = AppState.shared

    public var body: some View {
        if !checker.hasFullDiskAccess {
            HStack(spacing: 14) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wymagany Pełny dostęp do dysku")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Aby Tidy mógł wykryć cache przeglądarek, logi i pozostałości po aplikacjach, nadaj uprawnienie w Ustawieniach systemowych.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Otwórz Ustawienia") {
                    checker.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Sprawdź") {
                    appState.refreshFullDiskAccess()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

public struct FullDiskAccessModalView: View {
    @ObservedObject var checker = FullDiskAccessChecker.shared
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text("Wymagany Pełny dostęp do dysku")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("macOS chroni pliki aplikacji i dane użytkownika. Aby Tidy mógł rzetelnie przeskanować dysk, potrzebuje uprawnienia Full Disk Access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                StepRow(step: "1", text: "Kliknij poniższy przycisk, aby otworzyć Ustawienia systemowe.")
                StepRow(step: "2", text: "Przejdź do: Prywatność i ochrona → Pełny dostęp do dysku.")
                StepRow(step: "3", text: "Włącz przełącznik obok aplikacji Tidy (lub przeciągnij ją na listę).")
                StepRow(step: "4", text: "Wróć do aplikacji i kliknij „Sprawdź ponownie”.")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .tidyGlassCard(cornerRadius: 12)

            HStack(spacing: 12) {
                Button("Otwórz Ustawienia systemowe") {
                    checker.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button("Sprawdź ponownie") {
                    appState.refreshFullDiskAccess()
                    if appState.hasFullDiskAccess {
                        dismiss()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}

private struct StepRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.primary.opacity(0.1)))

            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}
