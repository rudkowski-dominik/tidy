import SwiftUI
import Quartz

public struct QuickLookHelper {
    public static func preview(url: URL) {
        NSWorkspace.shared.open(url)
    }

    public static func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
