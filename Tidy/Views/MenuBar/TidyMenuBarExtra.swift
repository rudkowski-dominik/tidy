import SwiftUI
import AppKit

public struct TidyMenuBarView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.tint)
                Text("Tidy")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("100% lokalnie")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Zakończ Tidy")
            }

            Divider()

            // Disk Space Summary
            HStack(spacing: 14) {
                DiskSpaceRingView(
                    usedBytes: appState.diskInfo.usedSpace,
                    freeBytes: appState.diskInfo.freeSpace,
                    totalBytes: appState.diskInfo.totalCapacity,
                    ringSize: 52,
                    lineWidth: 6,
                    showsInnerLabels: false
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(ByteFormatter.string(from: appState.diskInfo.freeSpace)) wolne")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("z \(ByteFormatter.string(from: appState.diskInfo.totalCapacity)) ogółem")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(String(format: "%.1f%% dysku zajęte", appState.diskInfo.usedPercent * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Scan status & cleanup potential
            if appState.scanSummary.totalCleanableBytes > 0 {
                VStack(spacing: 5) {
                    HStack {
                        Label("Można odzyskać:", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ByteFormatter.string(from: appState.scanSummary.totalCleanableBytes))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }

                    if appState.scanSummary.junkBytes > 0 {
                        HStack {
                            Text("• Śmieci i cache:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(ByteFormatter.string(from: appState.scanSummary.junkBytes))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if appState.scanSummary.duplicatesBytes > 0 {
                        HStack {
                            Text("• Duplikaty plików:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(ByteFormatter.string(from: appState.scanSummary.duplicatesBytes))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Divider()

            // Action Buttons
            HStack(spacing: 8) {
                Button {
                    openMainWindow()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "macwindow")
                        Text("Otwórz Tidy")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button {
                    appState.scanAll()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Skanuj")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            // Privacy & Author Footer
            HStack {
                Text("Twórca: Dominik Rudkowski")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Pełna prywatność danych")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .frame(width: 300)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
