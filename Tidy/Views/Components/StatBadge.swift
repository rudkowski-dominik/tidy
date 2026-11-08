import SwiftUI

public struct StatBadge: View {
    public let icon: String
    public let title: String
    public let value: String
    public var accentColor: Color = .accentColor

    public init(icon: String, title: String, value: String, accentColor: Color = .accentColor) {
        self.icon = icon
        self.title = title
        self.value = value
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .tidyGlassControl(cornerRadius: 10)
    }
}
