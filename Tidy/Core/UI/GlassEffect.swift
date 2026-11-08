import SwiftUI
import AppKit

public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var borderOpacity: Double

    public init(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.12) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(borderOpacity), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
    }
}

public struct GlassControlModifier: ViewModifier {
    var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                    )
            }
    }
}

public extension View {
    func tidyGlassCard(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.12) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }

    func tidyGlassControl(cornerRadius: CGFloat = 8) -> some View {
        modifier(GlassControlModifier(cornerRadius: cornerRadius))
    }
}

public enum HapticFeedback {
    public static func triggerSelection() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    }

    public static func triggerAction() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
}
