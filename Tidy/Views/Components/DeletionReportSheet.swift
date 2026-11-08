import SwiftUI

public struct DeletionReportSheet: View {
    public let report: DeletionReport
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(report.isCompleteSuccess ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: report.isCompleteSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(report.isCompleteSuccess ? .green : .orange)
            }

            VStack(spacing: 4) {
                Text(report.mode == .dryRun ? "Symulacja zakończona" : "Czyszczenie ukończone")
                    .font(.title2)
                    .fontWeight(.bold)

                if report.mode == .dryRun {
                    Text("Tryb próbny: zidentyfikowano potencjalne oszczędności")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Odzyskano \(ByteFormatter.string(from: report.totalBytesFreed))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }

            // Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(report.succeededURLs.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Usuniętych")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider().frame(height: 30)

                VStack {
                    Text("\(report.failedItems.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(report.failedItems.isEmpty ? Color.secondary : Color.red)
                    Text("Pominiętych")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider().frame(height: 30)

                VStack {
                    Text(String(format: "%.1fs", report.duration))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Czas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .tidyGlassCard(cornerRadius: 12)

            // Failed errors list if any
            if !report.failedItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pominięte elementy (chronione lub zablokowane):")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(report.failedItems.keys), id: \.self) { url in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(url.lastPathComponent)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text(report.failedItems[url] ?? "Brak dostępu")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 100)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            Button("Zamknij") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 480)
    }
}
