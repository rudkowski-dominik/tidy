import SwiftUI
import AppKit
import QuickLook
import UniformTypeIdentifiers

public struct TreemapView: View {
    @ObservedObject var appState: AppState

    @State private var navigationStack: [TreemapNode] = []
    @State private var currentRootURL: URL = FileManager.default.homeDirectoryForCurrentUser
    @State private var previewURL: URL? = nil
    @State private var isTargetedForDrop: Bool = false

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
                    },
                    onPreview: { child in
                        self.previewURL = child.url
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
        .quickLookPreview($previewURL)
        .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url = url, (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return }
                Task { @MainActor in
                    self.currentRootURL = url
                    self.navigationStack.removeAll()
                    appState.scanTreemap(for: url)
                }
            }
            return true
        }
        .overlay {
            if isTargetedForDrop {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.3x3.topleft.filled")
                            .font(.system(size: 48))
                            .foregroundStyle(.tint)
                        Text("Upuść folder, aby wyświetlić jego mapę miejsca")
                            .font(.headline)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .padding(20)
            }
        }
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
