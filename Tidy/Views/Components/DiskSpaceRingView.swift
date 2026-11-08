import SwiftUI

public struct DiskSpaceRingView: View {
    public let usedBytes: Int64
    public let freeBytes: Int64
    public let totalBytes: Int64
    public var ringSize: CGFloat = 180
    public var lineWidth: CGFloat = 18

    public init(usedBytes: Int64, freeBytes: Int64, totalBytes: Int64, ringSize: CGFloat = 180, lineWidth: CGFloat = 18) {
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.totalBytes = totalBytes
        self.ringSize = ringSize
        self.lineWidth = lineWidth
    }

    private var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1.0, max(0.0, Double(usedBytes) / Double(totalBytes)))
    }

    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            // Used space ring
            Circle()
                .trim(from: 0.0, to: CGFloat(usedFraction))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.accentColor, .blue, .cyan]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: usedFraction)

            // Inner statistics
            VStack(spacing: 4) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.secondary)

                Text(ByteFormatter.string(from: freeBytes))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text("wolne z \(ByteFormatter.string(from: totalBytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .padding()
    }
}
