import SwiftUI

public struct TidyMenuBarView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.tint)
                Text("Tidy")
                    .font(.headline)
                Spacer()
                Text("macOS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Dysk główny")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(ByteFormatter.string(from: appState.diskInfo.freeSpace))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("wolne")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: appState.diskInfo.usedPercent)
                    .progressViewStyle(.linear)
            }

            Divider()

            if appState.scanSummary.totalCleanableBytes > 0 {
                HStack {
                    Text("Można odzyskać:")
                        .font(.caption)
                    Spacer()
                    Text(ByteFormatter.string(from: appState.scanSummary.totalCleanableBytes))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 8) {
                Button("Otwórz Tidy") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Spacer()

                Button("Skanuj") {
                    appState.scanAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 240)
    }
}
