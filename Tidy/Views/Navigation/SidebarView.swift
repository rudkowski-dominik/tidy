import SwiftUI

public struct SidebarView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        List(selection: $appState.selectedSection) {
            Section("Analiza i czyszczenie") {
                NavigationLink(value: NavigationSection.overview) {
                    Label(NavigationSection.overview.rawValue, systemImage: NavigationSection.overview.icon)
                }

                NavigationLink(value: NavigationSection.junk) {
                    HStack {
                        Label(NavigationSection.junk.rawValue, systemImage: NavigationSection.junk.icon)
                        Spacer()
                        if appState.scanSummary.junkBytes > 0 {
                            Text(ByteFormatter.string(from: appState.scanSummary.junkBytes))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }

                NavigationLink(value: NavigationSection.duplicates) {
                    HStack {
                        Label(NavigationSection.duplicates.rawValue, systemImage: NavigationSection.duplicates.icon)
                        Spacer()
                        if appState.scanSummary.duplicatesBytes > 0 {
                            Text(ByteFormatter.string(from: appState.scanSummary.duplicatesBytes))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.15)))
                                .foregroundStyle(Color.orange)
                        }
                    }
                }

                NavigationLink(value: NavigationSection.largeFiles) {
                    HStack {
                        Label(NavigationSection.largeFiles.rawValue, systemImage: NavigationSection.largeFiles.icon)
                        Spacer()
                        if !appState.largeFiles.isEmpty {
                            Text("\(appState.largeFiles.count)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.primary.opacity(0.1)))
                        }
                    }
                }

                NavigationLink(value: NavigationSection.applications) {
                    HStack {
                        Label(NavigationSection.applications.rawValue, systemImage: NavigationSection.applications.icon)
                        Spacer()
                        if !appState.orphanedApps.isEmpty {
                            Text("\(appState.orphanedApps.count)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.purple.opacity(0.15)))
                                .foregroundStyle(Color.purple)
                                .help("\(appState.orphanedApps.count) pozostałości po odinstalowanych programach")
                        }
                    }
                }

                NavigationLink(value: NavigationSection.treemap) {
                    Label(NavigationSection.treemap.rawValue, systemImage: NavigationSection.treemap.icon)
                }
            }

            Section("Aplikacja") {
                NavigationLink(value: NavigationSection.settings) {
                    Label(NavigationSection.settings.rawValue, systemImage: NavigationSection.settings.icon)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkerboard")
                        .font(.caption)
                        .foregroundStyle(appState.hasFullDiskAccess ? .green : .orange)

                    Text(appState.hasFullDiskAccess ? "Pełny dostęp: Aktywny" : "Wymagany pełny dostęp")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
}
