import Foundation

public enum JunkType: String, CaseIterable, Identifiable, Sendable {
    case userCache = "Pamięć podręczna użytkownika"
    case systemLogs = "Dzienniki systemowe i aplikacji"
    case crashReports = "Raporty o awariach (Crash Reports)"
    case tempFiles = "Pliki tymczasowe"
    case oldInstallers = "Stare instalatory (.dmg, .pkg)"
    case xcodeDerivedData = "Xcode: DerivedData"
    case xcodeArchives = "Xcode: Archiwa projektów"
    case xcodeSimulators = "Xcode: Dane urządzeń i symulatorów"
    case browserSafari = "Safari: Pamięć podręczna"
    case browserChrome = "Chrome: Pamięć podręczna"
    case browserFirefox = "Firefox: Pamięć podręczna"
    case browserArc = "Arc: Pamięć podręczna"
    case trash = "Kosz systemowy"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .userCache: return "cylinder.split.1x2"
        case .systemLogs: return "doc.text.magnifyingglass"
        case .crashReports: return "exclamationmark.triangle"
        case .tempFiles: return "clock.arrow.circlepath"
        case .oldInstallers: return "shippingbox"
        case .xcodeDerivedData, .xcodeArchives, .xcodeSimulators: return "hammer"
        case .browserSafari: return "safari"
        case .browserChrome: return "globe"
        case .browserFirefox: return "flame"
        case .browserArc: return "sparkles"
        case .trash: return "trash"
        }
    }

    public var categoryDescription: String {
        switch self {
        case .userCache:
            return "Tymczasowe pliki generowane przez aplikacje w celu przyspieszenia działania. Ich usunięcie jest bezpieczne."
        case .systemLogs:
            return "Pliki dzienników diagnostycznych zapisywane przez programy i procesy systemowe."
        case .crashReports:
            return "Raporty błędów wygenerowane podczas niespodziewanego zamknięcia aplikacji."
        case .tempFiles:
            return "Pozostałości po zakończonych operacjach i procesach w katalogach tymczasowych."
        case .oldInstallers:
            return "Pobrane obrazy dysków i pakiety instalacyjne w folderze Pobrane."
        case .xcodeDerivedData:
            return "Tymczasowe pliki indeksów i kompilacji projektów Xcode. Zostaną odbudowane przy kolejnym buildzie."
        case .xcodeArchives:
            return "Zarchiwizowane wersje aplikacji wygenerowane podczas tworzenia wydań."
        case .xcodeSimulators:
            return "Pamięć podręczna i logi powiązane z symulatorami i podłączonymi urządzeniami testowymi."
        case .browserSafari:
            return "Zapisane pliki stron internetowych, grafiki i skrypty przeglądarki Safari."
        case .browserChrome:
            return "Pamięć podręczna stron internetowych przeglądarki Google Chrome."
        case .browserFirefox:
            return "Pamięć podręczna stron internetowych przeglądarki Mozilla Firefox."
        case .browserArc:
            return "Pamięć podręczna stron internetowych przeglądarki Arc."
        case .trash:
            return "Pliki oczekujące w Koszu na ostateczne usunięcie lub przywrócenie."
        }
    }

    public var defaultSelected: Bool {
        switch self {
        case .xcodeArchives:
            // Do not select archives by default, user should consciously decide
            return false
        default:
            return true
        }
    }
}

public struct JunkCategoryItem: Identifiable, Sendable {
    public let type: JunkType
    public var items: [FileItem]
    public var isSelected: Bool

    public var id: String { type.id }

    public init(type: JunkType, items: [FileItem] = [], isSelected: Bool? = nil) {
        self.type = type
        self.items = items
        self.isSelected = isSelected ?? type.defaultSelected
    }

    public var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    public var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    public var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }
}
