import Foundation
import SwiftUI
import Combine

public enum NavigationSection: String, CaseIterable, Identifiable {
    case overview = "Przegląd"
    case junk = "Śmieci systemowe"
    case duplicates = "Duplikaty"
    case largeFiles = "Duże i nieużywane"
    case applications = "Aplikacje"
    case treemap = "Mapa miejsca"
    case settings = "Ustawienia"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .overview: return "gauge.with.dots.needle.bottom.50percent"
        case .junk: return "trash"
        case .duplicates: return "doc.on.doc"
        case .largeFiles: return "arrow.up.and.down.and.sparkles"
        case .applications: return "square.stack.3d.up"
        case .treemap: return "square.grid.3x3"
        case .settings: return "gearshape"
        }
    }
}

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // MARK: - Navigation & Permissions
    @Published public var selectedSection: NavigationSection = .overview
    @Published public var hasFullDiskAccess: Bool = false
    @Published public var isDryRun: Bool = false {
        didSet { UserDefaults.standard.set(isDryRun, forKey: "tidy_is_dry_run") }
    }
    @Published public var allowPermanentDeletion: Bool = false {
        didSet { UserDefaults.standard.set(allowPermanentDeletion, forKey: "tidy_allow_permanent") }
    }

    // MARK: - Scan State
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var statusMessage: String = "Gotowy do skanowania"
    @Published public var scanSummary: ScanSummary = ScanSummary()

    // MARK: - Data Models
    @Published public var diskInfo: DiskSpaceInfo = DiskSpaceInfo(totalCapacity: 0, freeSpace: 0, usedSpace: 0)
    @Published public var junkCategories: [JunkCategoryItem] = []
    @Published public var duplicates: [DuplicateGroup] = []
    @Published public var largeFiles: [FileItem] = []
    @Published public var unusedApps: [UnusedAppItem] = []
    @Published public var installedApps: [InstalledApp] = []
    @Published public var orphanedApps: [InstalledApp] = []
    @Published public var treemapRoot: TreemapNode? = nil

    // MARK: - UI Alerts & Deletion Confirmation
    @Published public var isShowingConfirmationSheet: Bool = false
    @Published public var pendingDeletionURLs: [URL] = []
    @Published public var pendingDeletionCategory: String = ""
    @Published public var lastDeletionReport: DeletionReport? = nil
    @Published public var isShowingReportSheet: Bool = false

    private var scanTask: Task<Void, Never>? = nil

    private init() {
        self.isDryRun = UserDefaults.standard.bool(forKey: "tidy_is_dry_run")
        self.allowPermanentDeletion = UserDefaults.standard.bool(forKey: "tidy_allow_permanent")
        self.hasFullDiskAccess = FullDiskAccessChecker.shared.hasFullDiskAccess
        refreshDiskInfo()
    }

    public func refreshFullDiskAccess() {
        FullDiskAccessChecker.shared.refresh()
        self.hasFullDiskAccess = FullDiskAccessChecker.shared.hasFullDiskAccess
    }

    public func refreshDiskInfo() {
        Task {
            let info = await DiskOverviewScanner.shared.scanDiskSpace()
            self.diskInfo = info
            self.scanSummary.totalDiskCapacity = info.totalCapacity
            self.scanSummary.freeDiskSpace = info.freeSpace
            self.scanSummary.usedDiskSpace = info.usedSpace
        }
    }

    // MARK: - Scan Actions

    /// Launches a full scan across all categories.
    public func scanAll() {
        cancelScan()
        isScanning = true
        scanProgress = 0.0
        statusMessage = "Rozpoczynanie pełnego skanowania..."
        let startTime = Date()

        scanTask = Task(priority: .utility) {
            // 1. Disk Space
            let dInfo = await DiskOverviewScanner.shared.scanDiskSpace()
            await MainActor.run {
                self.diskInfo = dInfo
                self.scanProgress = 0.1
                self.statusMessage = "Skanowanie śmieci systemowych..."
            }

            // 2. Junk
            let junk = await JunkScanner.shared.scan { @Sendable prog, msg in
                Task { @MainActor in
                    AppState.shared.scanProgress = 0.1 + (0.3 * prog)
                    AppState.shared.statusMessage = msg
                }
            }
            if Task.isCancelled { return }

            // 3. Duplicates
            let dups = await DuplicateScanner.shared.scan { @Sendable prog, msg in
                Task { @MainActor in
                    AppState.shared.scanProgress = 0.4 + (0.25 * prog)
                    AppState.shared.statusMessage = msg
                }
            }
            if Task.isCancelled { return }

            // 4. Large Files & Unused Apps
            let lFiles = await LargeFilesScanner.shared.scanLargeFiles { @Sendable prog, msg in
                Task { @MainActor in
                    AppState.shared.scanProgress = 0.65 + (0.15 * prog)
                    AppState.shared.statusMessage = msg
                }
            }
            let uApps = await LargeFilesScanner.shared.scanUnusedApps()
            if Task.isCancelled { return }

            // 5. Installed Apps & Leftovers
            let iApps = await AppUninstallerScanner.shared.scanInstalledApps { @Sendable prog, msg in
                Task { @MainActor in
                    AppState.shared.scanProgress = 0.8 + (0.15 * prog)
                    AppState.shared.statusMessage = msg
                }
            }
            let installedIDs = Set(iApps.map { $0.bundleID })
            let orphans = await AppUninstallerScanner.shared.scanOrphanedRemnants(installedBundleIDs: installedIDs)
            if Task.isCancelled { return }

            let duration = Date().timeIntervalSince(startTime)

            await MainActor.run {
                self.junkCategories = junk
                self.duplicates = dups
                self.largeFiles = lFiles
                self.unusedApps = uApps
                self.installedApps = iApps
                self.orphanedApps = orphans

                // Update summary with total discovered bytes
                var summary = self.scanSummary
                summary.junkBytes = junk.reduce(0) { $0 + $1.totalSize }
                summary.duplicatesBytes = dups.reduce(0) { $0 + $1.wastedBytes }
                summary.largeFilesBytes = lFiles.reduce(0) { $0 + $1.size }
                summary.uninstallerBytes = orphans.reduce(0) { $0 + $1.totalSize }
                summary.isScanning = false
                summary.scanProgress = 1.0
                summary.currentStatusText = "Skanowanie zakończone w \(String(format: "%.1f", duration))s"
                summary.lastScanDate = Date()
                summary.scanDuration = duration

                self.scanSummary = summary
                self.isScanning = false
                self.scanProgress = 1.0
                self.statusMessage = "Skanowanie zakończone w \(String(format: "%.1f", duration)) s"
                HapticFeedback.triggerAction()
            }
        }
    }

    public func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        statusMessage = "Skanowanie anulowane"
    }

    // MARK: - Individual Scans

    public func scanJunkOnly() {
        Task(priority: .utility) {
            await MainActor.run {
                self.isScanning = true
                self.statusMessage = "Skanowanie śmieci systemowych..."
            }
            let items = await JunkScanner.shared.scan()
            await MainActor.run {
                self.junkCategories = items
                self.scanSummary.junkBytes = items.reduce(0) { $0 + $1.selectedSize }
                self.isScanning = false
                self.statusMessage = "Zakończono skanowanie śmieci"
            }
        }
    }

    public func scanDuplicatesOnly(directories: [URL]? = nil) {
        Task(priority: .utility) {
            await MainActor.run {
                self.isScanning = true
                self.statusMessage = "Wyszukiwanie duplikatów..."
            }
            let dirs = directories ?? DuplicateScanner.defaultScanDirectories
            let groups = await DuplicateScanner.shared.scan(directories: dirs)
            await MainActor.run {
                self.duplicates = groups
                self.scanSummary.duplicatesBytes = groups.reduce(0) { $0 + $1.wastedBytes }
                self.isScanning = false
                self.statusMessage = "Zakończono wyszukiwanie duplikatów"
            }
        }
    }

    public func scanLargeFilesOnly(minSize: Int64 = 100 * 1024 * 1024) {
        Task(priority: .utility) {
            await MainActor.run {
                self.isScanning = true
                self.statusMessage = "Wyszukiwanie dużych i nieużywanych plików..."
            }
            let files = await LargeFilesScanner.shared.scanLargeFiles(minSizeBytes: minSize)
            let uApps = await LargeFilesScanner.shared.scanUnusedApps()
            await MainActor.run {
                self.largeFiles = files
                self.unusedApps = uApps
                self.isScanning = false
                self.statusMessage = "Zakończono wyszukiwanie dużych plików"
            }
        }
    }

    public func scanAppsOnly() {
        Task(priority: .utility) {
            await MainActor.run {
                self.isScanning = true
                self.statusMessage = "Wyszukiwanie aplikacji i pozostałości..."
            }
            let apps = await AppUninstallerScanner.shared.scanInstalledApps()
            let installedIDs = Set(apps.map { $0.bundleID })
            let orphans = await AppUninstallerScanner.shared.scanOrphanedRemnants(installedBundleIDs: installedIDs)
            await MainActor.run {
                self.installedApps = apps
                self.orphanedApps = orphans
                self.isScanning = false
                self.statusMessage = "Zakończono analizę aplikacji"
            }
        }
    }

    public func scanTreemap(for url: URL) {
        Task(priority: .utility) {
            await MainActor.run {
                self.isScanning = true
                self.statusMessage = "Budowanie mapy zajętości: \(url.lastPathComponent)..."
            }
            let root = await TreemapScanner.shared.scan(rootURL: url)
            await MainActor.run {
                self.treemapRoot = root
                self.isScanning = false
                self.statusMessage = "Mapa gotowa"
            }
        }
    }

    // MARK: - Deletion Execution

    public func requestDeletion(urls: [URL], categoryName: String) {
        guard !urls.isEmpty else { return }
        self.pendingDeletionURLs = urls
        self.pendingDeletionCategory = categoryName
        self.isShowingConfirmationSheet = true
    }

    public func executePendingDeletion(permanent: Bool = false) {
        let urls = pendingDeletionURLs
        let mode: DeletionMode = permanent ? .permanent : .trash
        let dryRun = self.isDryRun

        Task {
            let report = await DeletionService.shared.delete(urls: urls, mode: mode, dryRun: dryRun)

            await MainActor.run {
                self.lastDeletionReport = report
                self.isShowingConfirmationSheet = false
                self.isShowingReportSheet = true
                self.refreshDiskInfo()

                // Remove deleted items from local state
                let succeeded = Set(report.succeededURLs)
                self.purgeRemovedURLs(succeeded)
                HapticFeedback.triggerAction()
            }
        }
    }

    private func purgeRemovedURLs(_ removed: Set<URL>) {
        // 1. Junk
        for i in 0..<junkCategories.count {
            junkCategories[i].items.removeAll { removed.contains($0.url) }
        }

        // 2. Duplicates
        for i in 0..<duplicates.count {
            duplicates[i].files.removeAll { removed.contains($0.url) }
        }
        duplicates.removeAll { $0.files.count < 2 }

        // 3. Large files
        largeFiles.removeAll { removed.contains($0.url) }
        unusedApps.removeAll { removed.contains($0.url) }

        // 4. Apps
        for i in 0..<installedApps.count {
            installedApps[i].associatedItems.removeAll { removed.contains($0.url) }
        }
        orphanedApps.removeAll { app in
            if let appURL = app.appURL, removed.contains(appURL) { return true }
            return app.associatedItems.allSatisfy { removed.contains($0.url) }
        }
    }
}
