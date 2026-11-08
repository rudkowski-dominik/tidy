import SwiftUI
import AppKit

public struct TreemapView: View {
    @ObservedObject var appState: AppState

    @State private var navigationStack: [TreemapNode] = []
    @State private var currentRootURL: URL = FileManager.default.homeDirectoryForCurrentUser

    private var currentNode: TreemapNode? {
        navigationStack.last ?? appState.treemapRoot
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 16) {
                Text("Wizualna mapa zajętości folderów. Kliknij blok, aby wejść głębiej, lub kliknij prawym przyciskiem, aby przenieść do Kosza.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 16)

                Button {
                    chooseFolder()
                } label: {
                    Label("Zmień folder", systemImage: "folder")
                }
                .buttonStyle(.bordered)

                Button {
                    appState.scanTreemap(for: currentRootURL)
                } label: {
                    Label("Odśwież", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial)

            // Breadcrumbs Navigation Bar
            HStack(spacing: 6) {
                Button {
                    navigationStack.removeAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "house.fill")
                        Text(currentRootURL.lastPathComponent)
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)

                ForEach(0..<navigationStack.count, id: \.self) { idx in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)

                    Button {
                        navigationStack = Array(navigationStack.prefix(idx + 1))
                    } label: {
                        Text(navigationStack[idx].name)
                            .font(.caption)
                            .fontWeight(idx == navigationStack.count - 1 ? .bold : .regular)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))

            Divider()

            // Main Canvas
            if let node = currentNode, let children = node.children, !children.isEmpty {
                TreemapCanvas(
                    nodes: children,
                    onSelect: { child in
                        if child.isDirectory && child.children != nil && !child.children!.isEmpty {
                            navigationStack.append(child)
                        }
                    },
                    onDelete: { child in
                        appState.requestDeletion(urls: [child.url], categoryName: "Element mapy: \(child.name)")
                    },
                    onReveal: { child in
                        QuickLookHelper.revealInFinder(url: child.url)
                    }
                )
                .padding(12)
            } else if appState.isScanning {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Analizowanie struktury katalogów...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("Brak danych mapy")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Wybierz folder lub kliknij poniżej, aby przeskanować katalog domowy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Skanuj katalog domowy") {
                        currentRootURL = FileManager.default.homeDirectoryForCurrentUser
                        appState.scanTreemap(for: currentRootURL)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Mapa miejsca")
        .onAppear {
            if appState.treemapRoot == nil {
                appState.scanTreemap(for: currentRootURL)
            }
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Wybierz folder"

        if panel.runModal() == .OK, let url = panel.url {
            currentRootURL = url
            navigationStack.removeAll()
            appState.scanTreemap(for: url)
        }
    }
}
