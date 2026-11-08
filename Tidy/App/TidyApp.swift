import SwiftUI
import AppKit

@main
struct TidyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("tidy_show_menu_bar_extra") private var showMenuBarExtra: Bool = false

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Skanowanie") {
                Button("Skanuj Maca") {
                    AppState.shared.scanAll()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Anuluj skanowanie") {
                    AppState.shared.cancelScan()
                }
                .keyboardShortcut(".", modifiers: .command)

                Divider()

                Button("Odśwież uprawnienia dysku") {
                    AppState.shared.refreshFullDiskAccess()
                }
            }
        }

        MenuBarExtra("Tidy", systemImage: "sparkles", isInserted: $showMenuBarExtra) {
            TidyMenuBarView(appState: AppState.shared)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure native window appearance
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
