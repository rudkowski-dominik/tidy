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

            // Disk Ring & Space Summary
            HStack(spacing: 14) {
                DiskSpaceRingView(
                    usedBytes: appState.diskInfo.usedSpace,
                    freeBytes: appState.diskInfo.freeSpace,
                    totalBytes: appState.diskInfo.totalCapacity,
                    ringSize: 64,
                    lineWidth: 8
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(ByteFormatter.string(from: appState.diskInfo.freeSpace))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("wolne z \(ByteFormatter.string(from: appState.diskInfo.totalCapacity))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(String(format: "%.1f%% zajęte", appState.diskInfo.usedPercent * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Scan status & cleanup potential
            if appState.scanSummary.totalCleanableBytes > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Można odzyskać:")
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
                            Text("• Śmieci:")
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
                            Text("• Duplikaty:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(ByteFormatter.string(from: appState.scanSummary.duplicatesBytes))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Divider()

            // Action Buttons
            HStack(spacing: 8) {
                Button {
                    openMainWindow()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow")
                        Text("Otwórz Tidy")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Spacer()

                Button {
                    appState.scanAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Skanuj")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 270)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
