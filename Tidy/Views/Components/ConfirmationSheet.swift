import SwiftUI

public struct ConfirmationSheet: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var confirmPermanent: Bool = false

    private var totalBytes: Int64 {
        appState.pendingDeletionURLs.reduce(0) { sum, url in
            sum + FileMetadataHelper.itemSize(at: url)
        }
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header icon
            ZStack {
                Circle()
                    .fill(appState.isDryRun ? Color.blue.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: appState.isDryRun ? "eye.trianglebadge.exclamationmark" : "trash.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(appState.isDryRun ? .blue : .red)
            }

            VStack(spacing: 6) {
                Text(appState.isDryRun ? "Symulacja czyszczenia (Tryb próbny)" : "Potwierdzenie usunięcia")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Kategoria: \(appState.pendingDeletionCategory)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Summary stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(appState.pendingDeletionURLs.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("elementów")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider().frame(height: 30)

                VStack {
                    Text(ByteFormatter.string(from: totalBytes))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("do odzyskania")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .tidyGlassCard(cornerRadius: 12)

            // Warning / Info Note
            if appState.isDryRun {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Tryb próbny jest aktywny. Żadne pliki nie zostaną faktycznie skasowane.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if appState.allowPermanentDeletion {
                Toggle(isOn: $confirmPermanent) {
                    Text("Usuń trwale (pomiń Kosz systemowy)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .toggleStyle(.checkbox)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("Pliki zostaną bezpiecznie przeniesione do Kosza. Możesz je w każdej chwili przywrócić.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Scrollable list of paths to be removed
            VStack(alignment: .leading, spacing: 6) {
                Text("Elementy do usunięcia:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(appState.pendingDeletionURLs, id: \.self) { url in
                            HStack {
                                Image(systemName: "doc")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(url.path(percentEncoded: false))
                                    .font(.system(size: 11, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text(ByteFormatter.string(from: FileMetadataHelper.itemSize(at: url)))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 120)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Buttons
            HStack(spacing: 12) {
                Button("Anuluj") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(role: confirmPermanent ? .destructive : nil) {
                    appState.executePendingDeletion(permanent: confirmPermanent)
                } label: {
                    Text(appState.isDryRun ? "Uruchom próbę" : (confirmPermanent ? "Usuń trwale" : "Przenieś do Kosza"))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(confirmPermanent ? .red : .accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
