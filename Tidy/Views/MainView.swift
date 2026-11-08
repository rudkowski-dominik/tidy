import SwiftUI

public struct MainView: View {
    @StateObject private var appState = AppState.shared

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
        } detail: {
            Group {
                switch appState.selectedSection {
                case .overview:
                    OverviewView(appState: appState)
                case .junk:
                    JunkCleanerView(appState: appState)
                case .duplicates:
                    DuplicatesView(appState: appState)
                case .largeFiles:
                    LargeFilesView(appState: appState)
                case .applications:
                    AppUninstallerView(appState: appState)
                case .treemap:
                    TreemapView(appState: appState)
                case .settings:
                    SettingsView(appState: appState)
                }
            }
            .frame(minWidth: 520, minHeight: 480)
        }
        .frame(minWidth: 760, minHeight: 520)
        .sheet(isPresented: $appState.isShowingConfirmationSheet) {
            ConfirmationSheet(appState: appState)
        }
        .sheet(isPresented: $appState.isShowingReportSheet) {
            if let report = appState.lastDeletionReport {
                DeletionReportSheet(report: report)
            }
        }
        .onAppear {
            appState.refreshFullDiskAccess()
        }
    }
}
