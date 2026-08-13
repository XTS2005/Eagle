import SwiftUI
import Combine
import CryptoKit
import UIKit

private let completeStyleRepositoryBase = URL(
    string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/"
)!

enum CompleteStyleComponent: String, CaseIterable, Identifiable {
    case wallpaper
    case passcode
    case card

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wallpaper: return LaraL10n.text(en: "Wallpaper", es: "Fondo")
        case .passcode: return LaraL10n.text(en: "Passcode", es: "Código")
        case .card: return LaraL10n.text(en: "Card", es: "Tarjeta")
        }
    }

    var systemImage: String {
        switch self {
        case .wallpaper: return "photo.on.rectangle.angled"
        case .passcode: return "circle.grid.3x3.fill"
        case .card: return "creditcard.fill"
        }
    }
}

struct CompleteStyleTone: Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: 1) }
}

enum CompleteStyleMotif: String, Sendable {
    case orbit
    case ribbons
    case grid
    case prism
    case bubbles
    case circuit
}

struct CompleteStylePack: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let tagline: String
    let summary: String
    let symbol: String
    let tones: [CompleteStyleTone]
    let motif: CompleteStyleMotif
    let wallpaperName: String
    let wallpaperFile: String
    let wallpaperPreview: String
    let wallpaperAuthor: String
    let passcodeName: String
    let passcodeFile: String
    let passcodePreview: String
    let passcodeAuthor: String

    var primary: CompleteStyleTone { tones[0] }
    var secondary: CompleteStyleTone { tones[min(1, tones.count - 1)] }
    var tertiary: CompleteStyleTone { tones[min(2, tones.count - 1)] }
    var localizedName: String { LaraL10n.localized(name) }
    var localizedTagline: String { LaraL10n.localized(tagline) }
    var localizedSummary: String { LaraL10n.localized(summary) }

    var wallpaperURL: URL {
        completeStyleRepositoryBase.appendingPathComponent("wallpapers/custom/\(wallpaperFile)")
    }

    var wallpaperPreviewURL: URL {
        completeStyleRepositoryBase.appendingPathComponent(wallpaperPreview)
    }

    var passcodeURL: URL {
        completeStyleRepositoryBase.appendingPathComponent("wallpapers/passtheme/\(passcodeFile)")
    }

    var passcodePreviewURL: URL {
        completeStyleRepositoryBase.appendingPathComponent(passcodePreview)
    }

    static let all: [CompleteStylePack] = [
        CompleteStylePack(
            id: "obsidian",
            name: "Obsidiana",
            tagline: "Profundo, silencioso, preciso.",
            summary: "Negros minerales con una luz violeta contenida. Elegante de noche y fácil de leer.",
            symbol: "circle.hexagongrid.fill",
            tones: [
                .init(red: 0.055, green: 0.06, blue: 0.09),
                .init(red: 0.25, green: 0.16, blue: 0.52),
                .init(red: 0.55, green: 0.39, blue: 0.94)
            ],
            motif: .orbit,
            wallpaperName: "Black Hole",
            wallpaperFile: "BlackHole.tendies",
            wallpaperPreview: "previews/custom/gifs/BlackHole.gif",
            wallpaperAuthor: "@i.mes",
            passcodeName: "Simple Dark",
            passcodeFile: "simple_dark.passthm",
            passcodePreview: "previews/passtheme/images/simple_dark.png",
            passcodeAuthor: "@c22dev"
        ),
        CompleteStylePack(
            id: "neon",
            name: "Pulso",
            tagline: "Luz eléctrica sin ruido visual.",
            summary: "Cian y magenta sobre un lienzo oscuro, con movimiento sutil y controles luminosos.",
            symbol: "waveform.path.ecg",
            tones: [
                .init(red: 0.025, green: 0.055, blue: 0.10),
                .init(red: 0.00, green: 0.82, blue: 0.92),
                .init(red: 0.94, green: 0.12, blue: 0.64)
            ],
            motif: .ribbons,
            wallpaperName: "Neon Lines",
            wallpaperFile: "neon_lines.tendies",
            wallpaperPreview: "previews/custom/gifs/neon_lines.gif",
            wallpaperAuthor: "@i.mes",
            passcodeName: "Neon",
            passcodeFile: "neon.passthm",
            passcodePreview: "previews/passtheme/images/neon_preview.png",
            passcodeAuthor: "@YangJiii"
        ),
        CompleteStylePack(
            id: "brisa",
            name: "Brisa",
            tagline: "Calma azul con profundidad.",
            summary: "Ondas suaves, tipografía limpia y una tarjeta que cambia entre índigo y azul cielo.",
            symbol: "wind",
            tones: [
                .init(red: 0.06, green: 0.12, blue: 0.28),
                .init(red: 0.22, green: 0.34, blue: 0.88),
                .init(red: 0.40, green: 0.78, blue: 0.96)
            ],
            motif: .ribbons,
            wallpaperName: "Midnight Brisa",
            wallpaperFile: "MidnightBrisa.tendies",
            wallpaperPreview: "previews/custom/gifs/MidnightBrisa.gif",
            wallpaperAuthor: "@limonetexd",
            passcodeName: "Monopad",
            passcodeFile: "Monopad.passthm",
            passcodePreview: "previews/passtheme/images/monopad.png",
            passcodeAuthor: "@BomberFish"
        ),
        CompleteStylePack(
            id: "arcade",
            name: "Arcade",
            tagline: "Color, ritmo y memoria táctil.",
            summary: "Un estilo juguetón inspirado en consolas, equilibrado para seguir sintiéndose moderno.",
            symbol: "gamecontroller.fill",
            tones: [
                .init(red: 0.10, green: 0.07, blue: 0.22),
                .init(red: 0.98, green: 0.30, blue: 0.34),
                .init(red: 0.98, green: 0.78, blue: 0.20)
            ],
            motif: .prism,
            wallpaperName: "Tinted Cubes",
            wallpaperFile: "TintedCubes.tendies",
            wallpaperPreview: "previews/custom/gifs/TintedCubes.gif",
            wallpaperAuthor: "@dootskyre",
            passcodeName: "Consoles",
            passcodeFile: "consoles.passthm",
            passcodePreview: "previews/passtheme/images/consoles.png",
            passcodeAuthor: "Dinervc"
        ),
        CompleteStylePack(
            id: "aero",
            name: "Aero",
            tagline: "Optimismo digital, bien editado.",
            summary: "Agua, cielo y color con una interpretación más sobria del clásico estilo Frutiger Aero.",
            symbol: "drop.fill",
            tones: [
                .init(red: 0.02, green: 0.30, blue: 0.48),
                .init(red: 0.10, green: 0.74, blue: 0.68),
                .init(red: 0.72, green: 0.92, blue: 0.38)
            ],
            motif: .bubbles,
            wallpaperName: "Frutiger Aero",
            wallpaperFile: "FrutigerAeroV1.tendies",
            wallpaperPreview: "previews/custom/gifs/FrutigerAeroV1.gif",
            wallpaperAuthor: "@devwithoutcod1ng",
            passcodeName: "Colored Numbers",
            passcodeFile: "colored_numbers.passthm",
            passcodePreview: "previews/passtheme/images/colored_numbers.png",
            passcodeAuthor: "Skwad29"
        ),
        CompleteStylePack(
            id: "terminal",
            name: "Terminal",
            tagline: "Herramientas, no adornos.",
            summary: "Verde de fósforo, estructura técnica y detalles monoespaciados para un aspecto funcional.",
            symbol: "terminal.fill",
            tones: [
                .init(red: 0.025, green: 0.07, blue: 0.055),
                .init(red: 0.08, green: 0.60, blue: 0.34),
                .init(red: 0.52, green: 0.96, blue: 0.62)
            ],
            motif: .circuit,
            wallpaperName: "GitHub",
            wallpaperFile: "GitHub.tendies",
            wallpaperPreview: "previews/custom/gifs/GitHub-wallpaper.gif",
            wallpaperAuthor: "@enkei64",
            passcodeName: "Digital",
            passcodeFile: "Digital.passthm",
            passcodePreview: "previews/passtheme/images/digital.png",
            passcodeAuthor: "Xenon"
        )
    ]
}

struct CompleteStyleSelection: Sendable {
    let title: String
    let wallpaperPack: CompleteStylePack?
    let passcodePack: CompleteStylePack?
    let cardPack: CompleteStylePack?

    var selectedCount: Int {
        [wallpaperPack, passcodePack, cardPack].compactMap { $0 }.count
    }

    var visualPack: CompleteStylePack? {
        wallpaperPack ?? cardPack ?? passcodePack
    }

    var uniformPackID: String? {
        let identifiers = Set([wallpaperPack, passcodePack, cardPack].compactMap { $0?.id })
        return identifiers.count == 1 ? identifiers.first : nil
    }
}

struct CompleteStyleFileSnapshot: Codable, Sendable {
    let path: String
    let data: Data
}

struct CompleteStyleUndoSnapshot: Codable, Sendable {
    let createdAt: Date
    let previousActiveName: String?
    let previousActivePackID: String?
    let previousVisualPackID: String?
    var passcodeFiles: [CompleteStyleFileSnapshot]
    var cardFile: CompleteStyleFileSnapshot?
    var installedWallpaperPaths: [String]
    var changedComponents: [String]
}

private struct CompleteStyleCachedResource: Sendable {
    let data: Data
    let cameFromCache: Bool
}

enum CompleteStyleResultState: String {
    case applied
    case skipped
    case failed

    var systemImage: String {
        switch self {
        case .applied: return "checkmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .applied: return .green
        case .skipped: return .secondary
        case .failed: return .orange
        }
    }
}

struct CompleteStyleComponentResult: Identifiable {
    let component: CompleteStyleComponent
    let state: CompleteStyleResultState
    let detail: String
    var id: String { component.rawValue }
}

struct CompleteStyleRunResult: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let components: [CompleteStyleComponentResult]

    var installedWallpaper: Bool {
        components.contains { $0.component == .wallpaper && $0.state == .applied }
    }

    var changedSystemArtwork: Bool {
        components.contains {
            ($0.component == .passcode || $0.component == .card) && $0.state == .applied
        }
    }
}

private enum CompleteStyleEngineError: LocalizedError {
    case badDownload
    case incompletePasscode
    case passcodeUnavailable
    case cardUnavailable
    case cardImageFailed
    case cardBackupFailed
    case cardWriteFailed(String)
    case undoPreparationFailed(String)
    case undoWriteFailed(String)
    case undoUnavailable
    case cacheWriteFailed
    case nothingToRestore

    var errorDescription: String? {
        switch self {
        case .badDownload:
            return LaraL10n.text(en: "One of the style assets could not be downloaded.", es: "No se pudo descargar uno de los recursos del estilo.")
        case .incompletePasscode:
            return LaraL10n.text(en: "The passcode theme does not contain all ten digits.", es: "El tema del código no contiene los diez números.")
        case .passcodeUnavailable:
            return LaraL10n.text(en: "The passcode cache was not found on this iPhone.", es: "No se encontró la caché del código en este iPhone.")
        case .cardUnavailable:
            return LaraL10n.text(en: "No compatible Wallet card was found.", es: "No se encontró una tarjeta de Wallet compatible.")
        case .cardImageFailed:
            return LaraL10n.text(en: "The card design could not be generated.", es: "No se pudo generar el diseño de la tarjeta.")
        case .cardBackupFailed:
            return LaraL10n.text(en: "The original card could not be saved, so Eagle made no change.", es: "No se pudo conservar la tarjeta original; Eagle no realizó el cambio.")
        case .cardWriteFailed(let message):
            return LaraL10n.text(en: "The card could not be updated: \(message)", es: "No se pudo actualizar la tarjeta: \(message)")
        case .undoPreparationFailed(let component):
            return LaraL10n.text(en: "Undo could not be prepared for \(component), so Eagle made no change.", es: "No se pudo preparar Deshacer para \(component); Eagle no realizó ese cambio.")
        case .undoWriteFailed(let message):
            return LaraL10n.text(en: "A previous file could not be recovered: \(message)", es: "No se pudo recuperar uno de los archivos anteriores: \(message)")
        case .undoUnavailable:
            return LaraL10n.text(en: "There is no recent change for Eagle to undo.", es: "No hay un cambio reciente que Eagle pueda deshacer.")
        case .cacheWriteFailed:
            return LaraL10n.text(en: "The asset downloaded, but Eagle could not save it safely.", es: "El recurso se descargó, pero Eagle no pudo guardarlo de forma segura.")
        case .nothingToRestore:
            return LaraL10n.text(en: "There are no Style changes to restore yet.", es: "Todavía no hay cambios de Estilos para restaurar.")
        }
    }
}

@MainActor
private final class CompleteStyleResourceCache {
    static let shared = CompleteStyleResourceCache()

    private let fm = FileManager.default
    private let directory: URL

    private init() {
        directory = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaraCompleteStyles", isDirectory: true)
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func resource(
        at url: URL,
        maximumSize: Int,
        forceRefresh: Bool = false
    ) async throws -> CompleteStyleCachedResource {
        let paths = cachePaths(for: url)
        if !forceRefresh,
           let cached = verifiedCachedData(dataURL: paths.data, digestURL: paths.digest),
           !cached.isEmpty,
           cached.count <= maximumSize {
            return CompleteStyleCachedResource(data: cached, cameFromCache: true)
        }

        remove(url)
        var lastError: Error = CompleteStyleEngineError.badDownload

        for attempt in 0..<2 {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 120
                request.cachePolicy = .reloadIgnoringLocalCacheData
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200,
                      !data.isEmpty,
                      data.count <= maximumSize else {
                    throw CompleteStyleEngineError.badDownload
                }

                try store(data, dataURL: paths.data, digestURL: paths.digest)
                return CompleteStyleCachedResource(data: data, cameFromCache: false)
            } catch {
                lastError = error
                if attempt == 0 {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                }
            }
        }

        throw lastError
    }

    func remove(_ url: URL) {
        let paths = cachePaths(for: url)
        try? fm.removeItem(at: paths.data)
        try? fm.removeItem(at: paths.digest)
    }

    func clear() {
        try? fm.removeItem(at: directory)
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func cachePaths(for url: URL) -> (data: URL, digest: URL) {
        let key = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return (
            directory.appendingPathComponent("\(key).resource"),
            directory.appendingPathComponent("\(key).sha256")
        )
    }

    private func verifiedCachedData(dataURL: URL, digestURL: URL) -> Data? {
        guard let data = try? Data(contentsOf: dataURL, options: .mappedIfSafe),
              let expected = try? String(contentsOf: digestURL, encoding: .utf8),
              digest(for: data) == expected else {
            return nil
        }
        return data
    }

    private func store(_ data: Data, dataURL: URL, digestURL: URL) throws {
        do {
            try data.write(to: dataURL, options: .atomic)
            try digest(for: data).write(to: digestURL, atomically: true, encoding: .utf8)
        } catch {
            try? fm.removeItem(at: dataURL)
            try? fm.removeItem(at: digestURL)
            throw CompleteStyleEngineError.cacheWriteFailed
        }
    }

    private func digest(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
private final class CompleteStyleUndoStore {
    static let shared = CompleteStyleUndoStore()

    private let fm = FileManager.default
    private let finalURL: URL
    private let pendingURL: URL

    private init() {
        let directory = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaraCompleteStyles", isDirectory: true)
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        finalURL = directory.appendingPathComponent("LastChange.plist")
        pendingURL = directory.appendingPathComponent("PendingChange.plist")
    }

    var hasSnapshot: Bool {
        fm.fileExists(atPath: finalURL.path)
    }

    func load() -> CompleteStyleUndoSnapshot? {
        guard let data = try? Data(contentsOf: finalURL) else { return nil }
        return try? PropertyListDecoder().decode(CompleteStyleUndoSnapshot.self, from: data)
    }

    func begin(_ snapshot: CompleteStyleUndoSnapshot) throws {
        try write(snapshot, to: pendingURL)
    }

    func commit(_ snapshot: CompleteStyleUndoSnapshot) throws {
        try write(snapshot, to: finalURL)
        try? fm.removeItem(at: pendingURL)
    }

    func discardPending() {
        try? fm.removeItem(at: pendingURL)
    }

    func clear() {
        try? fm.removeItem(at: finalURL)
        try? fm.removeItem(at: pendingURL)
    }

    private func write(_ snapshot: CompleteStyleUndoSnapshot, to url: URL) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }
}

@MainActor
final class CompleteStyleManager: ObservableObject {
    static let shared = CompleteStyleManager()

    @Published private(set) var isWorking = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var stage = LaraL10n.text(en: "Preparing", es: "Preparando")
    @Published private(set) var passcodeAvailable = false
    @Published private(set) var cardAvailable = false
    @Published var lastResult: CompleteStyleRunResult?
    @Published private(set) var activePackID: String?
    @Published private(set) var activeStyleName: String?
    @Published private(set) var activeVisualPackID: String?
    @Published private(set) var canUndo = false

    private let activePackKey = "lara.completeStyles.activePack"
    private let activeNameKey = "lara.completeStyles.activeName"
    private let activeVisualPackKey = "lara.completeStyles.activeVisualPack"
    private let wallpaperPathsKey = "lara.completeStyles.wallpaperPaths"

    private init() {
        activePackID = UserDefaults.standard.string(forKey: activePackKey)
        activeStyleName = UserDefaults.standard.string(forKey: activeNameKey)
        activeVisualPackID = UserDefaults.standard.string(forKey: activeVisualPackKey)
        if activeStyleName == nil,
           let activePackID,
           let migrated = CompleteStylePack.all.first(where: { $0.id == activePackID }) {
            activeStyleName = migrated.localizedName
            activeVisualPackID = migrated.id
        }
        canUndo = CompleteStyleUndoStore.shared.hasSnapshot
    }

    var activePack: CompleteStylePack? {
        CompleteStylePack.all.first { $0.id == activePackID }
    }

    var activeVisualPack: CompleteStylePack? {
        CompleteStylePack.all.first { $0.id == activeVisualPackID }
            ?? activePack
    }

    var hasActiveStyle: Bool { activeStyleName != nil }

    func refreshCompatibility() {
        guard laramgr.shared.sbxready else {
            passcodeAvailable = false
            cardAvailable = false
            return
        }
        passcodeAvailable = CompletePasscodeStyleEngine.basePath() != nil
        cardAvailable = CompleteCardStyleEngine.hasCompatibleCard()
    }

    func apply(
        pack: CompleteStylePack,
        wallpaper: Bool,
        passcode: Bool,
        card: Bool
    ) {
        apply(selection: CompleteStyleSelection(
            title: pack.name,
            wallpaperPack: wallpaper ? pack : nil,
            passcodePack: passcode ? pack : nil,
            cardPack: card ? pack : nil
        ))
    }

    func apply(selection: CompleteStyleSelection) {
        guard !isWorking else { return }
        guard laramgr.shared.sbxready else {
            lastResult = CompleteStyleRunResult(
                title: LaraL10n.text(en: "Eagle needs access", es: "Eagle necesita acceso"),
                message: LaraL10n.text(en: "Tap Continue under Prepare Access before applying a style.", es: "Pulsa Continuar en Preparar acceso antes de aplicar un estilo."),
                components: []
            )
            return
        }

        let selectedCount = selection.selectedCount
        guard selectedCount > 0 else {
            lastResult = CompleteStyleRunResult(
                title: LaraL10n.text(en: "Choose at least one part", es: "Elige al menos una parte"),
                message: LaraL10n.text(en: "Turn on Wallpaper, Passcode, or Card in the style options.", es: "Activa Fondo, Código o Tarjeta en las opciones del estilo."),
                components: []
            )
            return
        }

        isWorking = true
        progress = 0
        stage = LaraL10n.text(en: "Checking compatibility", es: "Comprobando compatibilidad")
        lastResult = nil

        Task {
            var completed = 0
            var results: [CompleteStyleComponentResult] = []
            var installedWallpaperPaths: [String] = []
            var undoSaved = true
            var undoSnapshot = CompleteStyleUndoSnapshot(
                createdAt: Date(),
                previousActiveName: activeStyleName,
                previousActivePackID: activePackID,
                previousVisualPackID: activeVisualPackID,
                passcodeFiles: [],
                cardFile: nil,
                installedWallpaperPaths: [],
                changedComponents: []
            )

            @MainActor func advance(_ nextStage: String) {
                completed += 1
                progress = Double(completed) / Double(selectedCount)
                stage = nextStage
            }

            @MainActor func persistUndoProgress() {
                do {
                    try CompleteStyleUndoStore.shared.commit(undoSnapshot)
                    canUndo = true
                    undoSaved = true
                } catch {
                    CompleteStyleUndoStore.shared.clear()
                    canUndo = false
                    undoSaved = false
                }
            }

            do {
                stage = LaraL10n.text(en: "Preparing Undo", es: "Preparando Deshacer")
                if selection.passcodePack != nil,
                   CompletePasscodeStyleEngine.basePath() != nil {
                    undoSnapshot.passcodeFiles = try CompletePasscodeStyleEngine.snapshot()
                }
                if selection.cardPack != nil,
                   CompleteCardStyleEngine.hasCompatibleCard() {
                    undoSnapshot.cardFile = try CompleteCardStyleEngine.snapshot()
                }
                try CompleteStyleUndoStore.shared.begin(undoSnapshot)
            } catch {
                CompleteStyleUndoStore.shared.discardPending()
                lastResult = CompleteStyleRunResult(
                    title: LaraL10n.text(en: "No changes were made", es: "No se realizó ningún cambio"),
                    message: LaraL10n.text(en: "Eagle could not save the current state for Undo. Your files remain unchanged.", es: "Eagle no pudo guardar el estado actual para Deshacer. Tus archivos permanecen intactos."),
                    components: []
                )
                progress = 0
                stage = LaraL10n.text(en: "No changes", es: "Sin cambios")
                isWorking = false
                return
            }

            if let pack = selection.passcodePack {
                stage = LaraL10n.text(en: "Preparing \(pack.passcodeName)", es: "Preparando \(pack.passcodeName)")
                do {
                    guard CompletePasscodeStyleEngine.basePath() != nil else {
                        throw CompleteStyleEngineError.passcodeUnavailable
                    }
                    let prepared = try await passcodeImages(for: pack)
                    let images = prepared.images
                    let count = try CompletePasscodeStyleEngine.apply(images: images)
                    undoSnapshot.changedComponents.append(CompleteStyleComponent.passcode.rawValue)
                    persistUndoProgress()
                    results.append(.init(
                        component: .passcode,
                        state: .applied,
                        detail: LaraL10n.text(
                            en: "\(pack.passcodeName), \(count) files verified\(prepared.cameFromCache ? " · cached" : "")",
                            es: "\(pack.passcodeName), \(count) archivos verificados\(prepared.cameFromCache ? " · guardado" : "")"
                        )
                    ))
                } catch CompleteStyleEngineError.passcodeUnavailable {
                    results.append(.init(
                        component: .passcode,
                        state: .skipped,
                        detail: LaraL10n.text(en: "Unavailable on this device", es: "No disponible en este dispositivo")
                    ))
                } catch {
                    results.append(.init(
                        component: .passcode,
                        state: .failed,
                        detail: error.localizedDescription
                    ))
                }
                advance(LaraL10n.text(en: "Passcode complete", es: "Código terminado"))
            }

            if let pack = selection.cardPack {
                stage = LaraL10n.text(en: "Designing card", es: "Diseñando la tarjeta")
                do {
                    try CompleteCardStyleEngine.apply(pack: pack)
                    undoSnapshot.changedComponents.append(CompleteStyleComponent.card.rawValue)
                    persistUndoProgress()
                    results.append(.init(
                        component: .card,
                        state: .applied,
                        detail: LaraL10n.text(en: "Design created locally and backed up", es: "Diseño creado localmente y respaldado")
                    ))
                } catch CompleteStyleEngineError.cardUnavailable {
                    results.append(.init(
                        component: .card,
                        state: .skipped,
                        detail: LaraL10n.text(en: "No compatible card in Wallet", es: "No hay una tarjeta compatible en Wallet")
                    ))
                } catch {
                    results.append(.init(
                        component: .card,
                        state: .failed,
                        detail: error.localizedDescription
                    ))
                }
                advance(LaraL10n.text(en: "Card complete", es: "Tarjeta terminada"))
            }

            if let pack = selection.wallpaperPack {
                stage = LaraL10n.text(en: "Installing \(pack.wallpaperName)", es: "Instalando \(pack.wallpaperName)")
                do {
                    let prepared = try await installWallpaper(pack)
                    let install = prepared.result
                    installedWallpaperPaths = install.installedDestinations.map(\.path)
                    undoSnapshot.installedWallpaperPaths = installedWallpaperPaths
                    undoSnapshot.changedComponents.append(CompleteStyleComponent.wallpaper.rawValue)
                    persistUndoProgress()
                    results.append(.init(
                        component: .wallpaper,
                        state: .applied,
                        detail: install.installedCount > 0
                            ? LaraL10n.text(
                                en: "\(pack.wallpaperName) added to Wallpapers\(prepared.cameFromCache ? " · cached" : "")",
                                es: "\(pack.wallpaperName) agregado a Fondos\(prepared.cameFromCache ? " · guardado" : "")"
                            )
                            : LaraL10n.text(en: "\(pack.wallpaperName) was already installed", es: "\(pack.wallpaperName) ya estaba instalado")
                    ))
                } catch {
                    results.append(.init(
                        component: .wallpaper,
                        state: .failed,
                        detail: error.localizedDescription
                    ))
                }
                advance(LaraL10n.text(en: "Wallpaper complete", es: "Fondo terminado"))
            }

            let applied = results.filter { $0.state == .applied }.count
            let failed = results.filter { $0.state == .failed }.count
            if applied > 0 {
                persistUndoProgress()
                setActiveStyle(
                    name: selection.title,
                    packID: selection.uniformPackID,
                    visualPackID: selection.visualPack?.id
                )
                rememberWallpaperPaths(installedWallpaperPaths)
            } else {
                CompleteStyleUndoStore.shared.discardPending()
            }

            var message: String
            if applied == selectedCount {
                message = LaraL10n.text(en: "The selected parts were applied and verified successfully.", es: "Las partes elegidas se aplicaron y verificaron correctamente.")
            } else if applied > 0 {
                message = failed > 0
                    ? LaraL10n.text(en: "The style was partially applied. Review each result.", es: "El estilo se aplicó parcialmente. Revisa cada resultado.")
                    : LaraL10n.text(en: "Everything compatible with this iPhone was applied.", es: "Se aplicó todo lo compatible con este iPhone.")
            } else {
                message = LaraL10n.text(en: "None of the selected parts could be applied.", es: "No se pudo aplicar ninguna de las partes elegidas.")
            }
            if applied > 0, !undoSaved {
                message += LaraL10n.text(en: " The originals remain protected, but Undo is unavailable for this action.", es: " Los originales siguen protegidos, pero Deshacer no está disponible para esta acción.")
            }

            lastResult = CompleteStyleRunResult(
                title: applied > 0
                    ? LaraL10n.text(
                        en: "\(LaraL10n.localized(selection.title)) is ready",
                        es: "\(LaraL10n.localized(selection.title)) está listo"
                    )
                    : LaraL10n.text(en: "Style not applied", es: "No se aplicó el estilo"),
                message: message,
                components: results
            )
            progress = 1
            stage = LaraL10n.text(en: "Done", es: "Listo")
            isWorking = false
            refreshCompatibility()

            if results.contains(where: { $0.component == .wallpaper && $0.state == .applied }) {
                _ = PosterBoardWriter.refreshCollections()
            }
        }
    }

    func undoLastStyle() {
        guard !isWorking else { return }
        guard laramgr.shared.sbxready else {
            lastResult = CompleteStyleRunResult(
                title: LaraL10n.text(en: "Eagle needs access", es: "Eagle necesita acceso"),
                message: LaraL10n.text(en: "Prepare access before undoing the latest style.", es: "Prepara el acceso antes de deshacer el último estilo."),
                components: []
            )
            return
        }
        guard let snapshot = CompleteStyleUndoStore.shared.load() else {
            canUndo = false
            lastResult = CompleteStyleRunResult(
                title: LaraL10n.text(en: "Nothing to undo", es: "Nada que deshacer"),
                message: CompleteStyleEngineError.undoUnavailable.localizedDescription,
                components: []
            )
            return
        }

        isWorking = true
        progress = 0
        stage = LaraL10n.text(en: "Recovering previous style", es: "Recuperando el estilo anterior")
        lastResult = nil

        Task {
            let changed = Set(snapshot.changedComponents)
            var results: [CompleteStyleComponentResult] = []

            if changed.contains(CompleteStyleComponent.passcode.rawValue) {
                do {
                    let count = try CompletePasscodeStyleEngine.restoreSnapshot(snapshot.passcodeFiles)
                    results.append(.init(
                        component: .passcode,
                        state: .applied,
                        detail: LaraL10n.text(en: "Recovered \(count) previous files", es: "Se recuperaron \(count) archivos anteriores")
                    ))
                } catch {
                    results.append(.init(component: .passcode, state: .failed, detail: error.localizedDescription))
                }
            }
            progress = 0.34

            if changed.contains(CompleteStyleComponent.card.rawValue) {
                do {
                    guard let cardFile = snapshot.cardFile else {
                        throw CompleteStyleEngineError.undoPreparationFailed(
                            LaraL10n.text(en: "the card", es: "la tarjeta")
                        )
                    }
                    try CompleteCardStyleEngine.restoreSnapshot(cardFile)
                    results.append(.init(
                        component: .card,
                        state: .applied,
                        detail: LaraL10n.text(en: "The previous design was recovered", es: "Se recuperó el diseño anterior")
                    ))
                } catch {
                    results.append(.init(component: .card, state: .failed, detail: error.localizedDescription))
                }
            }
            progress = 0.67

            if changed.contains(CompleteStyleComponent.wallpaper.rawValue) {
                let removed = CompleteWallpaperStyleEngine.removeTrackedDescriptors(
                    paths: snapshot.installedWallpaperPaths
                )
                forgetWallpaperPaths(snapshot.installedWallpaperPaths)
                results.append(.init(
                    component: .wallpaper,
                    state: removed > 0 ? .applied : .skipped,
                    detail: removed > 0
                        ? LaraL10n.text(en: "The wallpaper from the latest change was removed", es: "Se retiró el fondo del último cambio")
                        : LaraL10n.text(en: "That wallpaper already existed, so it was not removed", es: "Ese fondo ya existía; no fue necesario retirarlo")
                ))
            }

            let failed = results.contains { $0.state == .failed }
            if !failed {
                setActiveStyle(
                    name: snapshot.previousActiveName,
                    packID: snapshot.previousActivePackID,
                    visualPackID: snapshot.previousVisualPackID
                )
                CompleteStyleUndoStore.shared.clear()
                canUndo = false
            }

            progress = 1
            stage = failed
                ? LaraL10n.text(en: "Undo incomplete", es: "Deshacer incompleto")
                : LaraL10n.text(en: "Change undone", es: "Cambio deshecho")
            isWorking = false
            lastResult = CompleteStyleRunResult(
                title: failed
                    ? LaraL10n.text(en: "Could not undo everything", es: "No se pudo deshacer todo")
                    : LaraL10n.text(en: "Previous style restored", es: "Volviste al estilo anterior"),
                message: failed
                    ? LaraL10n.text(en: "Some parts need another attempt. Eagle kept the snapshot.", es: "Algunas partes necesitan otro intento. Eagle conservó la instantánea.")
                    : LaraL10n.text(en: "Eagle recovered the exact state from before the latest change.", es: "Eagle recuperó el estado exacto que existía antes del último cambio."),
                components: results
            )
            _ = PosterBoardWriter.refreshCollections()
        }
    }

    func restoreOriginals() {
        guard !isWorking else { return }
        guard laramgr.shared.sbxready else {
            lastResult = CompleteStyleRunResult(
                title: LaraL10n.text(en: "Eagle needs access", es: "Eagle necesita acceso"),
                message: LaraL10n.text(en: "Prepare access before restoring.", es: "Prepara el acceso antes de restaurar."),
                components: []
            )
            return
        }

        isWorking = true
        progress = 0
        stage = LaraL10n.text(en: "Restoring originals", es: "Restaurando originales")

        Task {
            var results: [CompleteStyleComponentResult] = []

            do {
                let restored = try CompletePasscodeStyleEngine.restoreOriginals()
                results.append(.init(
                    component: .passcode,
                    state: restored ? .applied : .skipped,
                    detail: restored
                        ? LaraL10n.text(en: "Original digits restored", es: "Números originales restaurados")
                        : LaraL10n.text(en: "No passcode backup was available", es: "No había respaldo del código")
                ))
            } catch {
                results.append(.init(component: .passcode, state: .failed, detail: error.localizedDescription))
            }
            progress = 0.34

            do {
                let restored = try CompleteCardStyleEngine.restoreOriginal()
                results.append(.init(
                    component: .card,
                    state: restored ? .applied : .skipped,
                    detail: restored
                        ? LaraL10n.text(en: "Original card restored", es: "Tarjeta original restaurada")
                        : LaraL10n.text(en: "No card backup was available", es: "No había respaldo de tarjeta")
                ))
            } catch {
                results.append(.init(component: .card, state: .failed, detail: error.localizedDescription))
            }
            progress = 0.67

            let removed = CompleteWallpaperStyleEngine.removeTrackedDescriptors(
                paths: UserDefaults.standard.stringArray(forKey: wallpaperPathsKey) ?? []
            )
            results.append(.init(
                component: .wallpaper,
                state: removed > 0 ? .applied : .skipped,
                detail: removed > 0
                    ? LaraL10n.text(en: "Removed \(removed) wallpapers added by Styles", es: "Se retiraron \(removed) fondos agregados por Estilos")
                    : LaraL10n.text(en: "No wallpapers were recorded", es: "No había fondos registrados")
            ))
            UserDefaults.standard.removeObject(forKey: wallpaperPathsKey)
            setActiveStyle(name: nil, packID: nil, visualPackID: nil)
            CompleteStyleUndoStore.shared.clear()
            canUndo = false

            progress = 1
            stage = LaraL10n.text(en: "Originals restored", es: "Originales restaurados")
            isWorking = false
            lastResult = CompleteStyleRunResult(
                title: LaraL10n.text(en: "Restore complete", es: "Restauración terminada"),
                message: LaraL10n.text(en: "Eagle restored the available backups. You can restart the interface to see every change.", es: "Eagle restauró los respaldos disponibles. Puedes reiniciar la interfaz para ver todos los cambios."),
                components: results
            )
            _ = PosterBoardWriter.refreshCollections()
        }
    }

    func clearResult() {
        lastResult = nil
    }

    func openWallpaperPicker() {
        _ = "com.apple.PosterBoard".withCString { launch_app($0) }
    }

    func clearDownloadedStyles() {
        CompleteStyleResourceCache.shared.clear()
    }

    private func passcodeImages(
        for pack: CompleteStylePack
    ) async throws -> (images: [String: Data], cameFromCache: Bool) {
        let cache = CompleteStyleResourceCache.shared
        let first = try await cache.resource(
            at: pack.passcodeURL,
            maximumSize: 50 * 1024 * 1024
        )
        do {
            return (try CompletePasscodeStyleEngine.images(from: first.data), first.cameFromCache)
        } catch where first.cameFromCache {
            cache.remove(pack.passcodeURL)
            let refreshed = try await cache.resource(
                at: pack.passcodeURL,
                maximumSize: 50 * 1024 * 1024,
                forceRefresh: true
            )
            return (try CompletePasscodeStyleEngine.images(from: refreshed.data), false)
        }
    }

    private func installWallpaper(
        _ pack: CompleteStylePack
    ) async throws -> (result: TendiesInstallResult, cameFromCache: Bool) {
        let cache = CompleteStyleResourceCache.shared
        let first = try await cache.resource(
            at: pack.wallpaperURL,
            maximumSize: TendiesInstaller.maximumCompressedSize
        )
        do {
            return (try TendiesInstaller.install(data: first.data), first.cameFromCache)
        } catch where first.cameFromCache {
            cache.remove(pack.wallpaperURL)
            let refreshed = try await cache.resource(
                at: pack.wallpaperURL,
                maximumSize: TendiesInstaller.maximumCompressedSize,
                forceRefresh: true
            )
            return (try TendiesInstaller.install(data: refreshed.data), false)
        }
    }

    private func setActiveStyle(name: String?, packID: String?, visualPackID: String?) {
        activeStyleName = name
        activePackID = packID
        activeVisualPackID = visualPackID
        setDefault(name, forKey: activeNameKey)
        setDefault(packID, forKey: activePackKey)
        setDefault(visualPackID, forKey: activeVisualPackKey)
    }

    private func setDefault(_ value: String?, forKey key: String) {
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func rememberWallpaperPaths(_ paths: [String]) {
        guard !paths.isEmpty else { return }
        var stored = UserDefaults.standard.stringArray(forKey: wallpaperPathsKey) ?? []
        for path in paths where !stored.contains(path) {
            stored.append(path)
        }
        UserDefaults.standard.set(stored, forKey: wallpaperPathsKey)
    }

    private func forgetWallpaperPaths(_ paths: [String]) {
        guard !paths.isEmpty else { return }
        var stored = UserDefaults.standard.stringArray(forKey: wallpaperPathsKey) ?? []
        stored.removeAll { paths.contains($0) }
        UserDefaults.standard.set(stored, forKey: wallpaperPathsKey)
    }
}

enum CompletePasscodeStyleEngine {
    private static let telephonyOptions = (8...15).reversed().map { "TelephonyUI-\($0)" }

    static func basePath() -> String? {
        for version in telephonyOptions {
            let path = "/var/mobile/Library/Caches/\(version)"
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                return path
            }
        }
        return nil
    }

    static func images(from data: Data) throws -> [String: Data] {
        let archive = try ZipArchive(data: data)
        var result: [String: Data] = [:]

        for entry in archive.entries where !entry.isDirectory {
            let path = entry.path.replacingOccurrences(of: "\\", with: "/")
            let lower = path.lowercased()
            guard !lower.contains("__macosx/"),
                  ["png", "jpg", "jpeg"].contains((path as NSString).pathExtension.lowercased()),
                  let digit = digit(in: lower) else { continue }
            result[digit] = try archive.extract(entry)
        }

        guard result.count == 10 else { throw CompleteStyleEngineError.incompletePasscode }
        return result
    }

    static func snapshot() throws -> [CompleteStyleFileSnapshot] {
        guard let basePath = basePath() else {
            throw CompleteStyleEngineError.passcodeUnavailable
        }
        let paths = targetPaths(in: basePath).values.flatMap { $0 }
        guard !paths.isEmpty else {
            throw CompleteStyleEngineError.undoPreparationFailed(
                LaraL10n.text(en: "the passcode", es: "el código")
            )
        }

        return try paths.map { path in
            guard let data = read(path, maximumSize: 8 * 1024 * 1024) else {
                throw CompleteStyleEngineError.undoPreparationFailed(
                    LaraL10n.text(en: "the passcode", es: "el código")
                )
            }
            return CompleteStyleFileSnapshot(path: path, data: data)
        }
    }

    static func currentPreviewImages() -> [String: UIImage] {
        guard let basePath = basePath() else { return [:] }
        let targets = targetPaths(in: basePath)
        var result: [String: UIImage] = [:]
        for digit in (0...9).map(String.init) {
            guard let path = targets[digit]?.first,
                  let data = read(path, maximumSize: 8 * 1024 * 1024),
                  let image = UIImage(data: data) else { continue }
            result[digit] = image
        }
        return result
    }

    static func restoreSnapshot(_ files: [CompleteStyleFileSnapshot]) throws -> Int {
        guard !files.isEmpty else {
            throw CompleteStyleEngineError.undoPreparationFailed(
                LaraL10n.text(en: "the passcode", es: "el código")
            )
        }
        var restored = 0
        for file in files {
            let result = laramgr.shared.lara_overwritefile(target: file.path, data: file.data)
            guard result.ok else {
                throw CompleteStyleEngineError.undoWriteFailed(result.message)
            }
            restored += 1
        }
        return restored
    }

    @MainActor
    static func apply(images: [String: Data]) throws -> Int {
        guard let basePath = basePath() else { throw CompleteStyleEngineError.passcodeUnavailable }
        let targets = targetPaths(in: basePath)
        var applied = 0

        for digit in (0...9).map(String.init) {
            guard let image = images[digit] else { continue }
            for path in targets[digit] ?? [] {
                try PasscodeThemeManager.shared.applyImage(data: image, to: path)
                applied += 1
            }
        }

        guard applied > 0 else { throw CompleteStyleEngineError.passcodeUnavailable }
        return applied
    }

    @MainActor
    static func restoreOriginals() throws -> Bool {
        guard let basePath = basePath() else { return false }
        let targets = targetPaths(in: basePath).values.flatMap { $0 }
        guard targets.contains(where: PasscodeThemeManager.shared.hasBackup(targetPath:)) else {
            return false
        }
        try PasscodeThemeManager.shared.restoreAll(basePath: basePath)
        return true
    }

    private static func targetPaths(in basePath: String) -> [String: [String]] {
        guard let enumerator = FileManager.default.enumerator(atPath: basePath) else { return [:] }
        var result: [String: [String]] = [:]
        for case let file as String in enumerator where file.lowercased().hasSuffix(".png") {
            if let digit = digit(in: file.lowercased()) {
                result[digit, default: []].append("\(basePath)/\(file)")
            }
        }
        return result
    }

    private static func read(_ path: String, maximumSize: Int) -> Data? {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) {
            return data.count <= maximumSize ? data : nil
        }
        return laramgr.shared.vfsready
            ? laramgr.shared.vfsread(path: path, maxSize: maximumSize)
            : nil
    }

    private static func digit(in lower: String) -> String? {
        for value in 0...9 {
            if lower.contains("other-2-\(value)--dark") ||
                lower.contains("-\(value)-") ||
                lower.contains("-\(value)@") ||
                lower.contains("_\(value)_") ||
                lower.contains("_\(value)@") ||
                lower.hasSuffix("/\(value).png") ||
                lower.hasSuffix("/\(value).jpg") ||
                lower.hasSuffix("/\(value).jpeg") {
                return String(value)
            }
        }
        return nil
    }
}

@MainActor
enum CompleteCardStyleEngine {
    private struct CardTarget {
        let imagePath: String
        let directoryPath: String
    }

    private static let fileNames = [
        "cardBackground@2x.png",
        "cardBackgroundCombined@2x.png",
        "cardBackgroundCombined-watch@2x.png"
    ]

    static func hasCompatibleCard() -> Bool {
        firstCard() != nil
    }

    static func snapshot() throws -> CompleteStyleFileSnapshot {
        guard let card = firstCard() else { throw CompleteStyleEngineError.cardUnavailable }
        guard let data = read(card.imagePath, maximumSize: 20 * 1024 * 1024) else {
            throw CompleteStyleEngineError.undoPreparationFailed("la tarjeta")
        }
        return CompleteStyleFileSnapshot(path: card.imagePath, data: data)
    }

    static func restoreSnapshot(_ file: CompleteStyleFileSnapshot) throws {
        let result = laramgr.shared.lara_overwritefile(target: file.path, data: file.data)
        guard result.ok else { throw CompleteStyleEngineError.cardWriteFailed(result.message) }
        clearCache(for: CardTarget(
            imagePath: file.path,
            directoryPath: URL(fileURLWithPath: file.path).deletingLastPathComponent().path
        ))
    }

    static func previewImage(pack: CompleteStylePack) -> UIImage? {
        guard let data = renderCard(pack: pack) else { return nil }
        return UIImage(data: data)
    }

    static func currentPreviewImage() -> UIImage? {
        guard let card = firstCard(),
              let data = read(card.imagePath, maximumSize: 20 * 1024 * 1024) else {
            return nil
        }
        return UIImage(data: data)
    }

    static func apply(pack: CompleteStylePack) throws {
        guard let card = firstCard() else { throw CompleteStyleEngineError.cardUnavailable }
        guard let imageData = renderCard(pack: pack) else {
            throw CompleteStyleEngineError.cardImageFailed
        }

        let backup = card.imagePath + ".backup"
        if !FileManager.default.fileExists(atPath: backup) {
            guard let original = read(card.imagePath, maximumSize: 20 * 1024 * 1024),
                  write(backup, data: original),
                  FileManager.default.fileExists(atPath: backup) else {
                throw CompleteStyleEngineError.cardBackupFailed
            }
        }

        let result = laramgr.shared.lara_overwritefile(target: card.imagePath, data: imageData)
        guard result.ok else { throw CompleteStyleEngineError.cardWriteFailed(result.message) }
        clearCache(for: card)
    }

    static func restoreOriginal() throws -> Bool {
        guard let card = firstCard() else { return false }
        let backup = card.imagePath + ".backup"
        guard let data = read(backup, maximumSize: 20 * 1024 * 1024) else { return false }
        let result = laramgr.shared.lara_overwritefile(target: card.imagePath, data: data)
        guard result.ok else { throw CompleteStyleEngineError.cardWriteFailed(result.message) }
        clearCache(for: card)
        return true
    }

    private static func firstCard() -> CardTarget? {
        let roots = [
            "/var/mobile/Library/Passes/Cards",
            "/private/var/mobile/Library/Passes/Cards",
            "/var/mobile/Library/Passes/Passes/Cards",
            "/private/var/mobile/Library/Passes/Passes/Cards"
        ]

        for root in roots {
            if let found = findCard(in: root, depth: 0) { return found }
        }
        return nil
    }

    private static func findCard(in directory: String, depth: Int) -> CardTarget? {
        guard depth <= 2,
              let entries = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return nil
        }

        for fileName in fileNames where entries.contains(fileName) {
            return CardTarget(
                imagePath: (directory as NSString).appendingPathComponent(fileName),
                directoryPath: directory
            )
        }

        for entry in entries where !entry.hasPrefix(".") {
            let nested = (directory as NSString).appendingPathComponent(entry)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: nested, isDirectory: &isDirectory),
               isDirectory.boolValue,
               let found = findCard(in: nested, depth: depth + 1) {
                return found
            }
        }
        return nil
    }

    private static func renderCard(pack: CompleteStylePack) -> Data? {
        let size = CGSize(width: 1016, height: 640)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { context in
            let cg = context.cgContext
            let colors = pack.tones.map { $0.uiColor.cgColor } as CFArray
            let locations: [CGFloat] = [0, 0.56, 1]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: locations
            ) {
                cg.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            drawMotif(pack.motif, in: CGRect(origin: .zero, size: size), context: cg, accent: pack.tertiary.uiColor)

            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.14).cgColor)
            cg.setLineWidth(2)
            cg.stroke(CGRect(x: 22, y: 22, width: size.width - 44, height: size.height - 44))

            let shine = UIBezierPath()
            shine.move(to: CGPoint(x: -80, y: 100))
            shine.addLine(to: CGPoint(x: size.width * 0.74, y: -40))
            shine.addLine(to: CGPoint(x: size.width * 0.43, y: size.height + 40))
            shine.close()
            UIColor.white.withAlphaComponent(0.035).setFill()
            shine.fill()
        }
        return image.pngData()
    }

    private static func drawMotif(
        _ motif: CompleteStyleMotif,
        in rect: CGRect,
        context: CGContext,
        accent: UIColor
    ) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineCap(.round)

        switch motif {
        case .orbit:
            context.setStrokeColor(accent.withAlphaComponent(0.28).cgColor)
            for index in 0..<5 {
                let inset = CGFloat(index * 54)
                context.setLineWidth(index == 0 ? 7 : 2)
                context.strokeEllipse(in: CGRect(x: rect.width * 0.57 - inset / 2, y: -180 + inset / 2, width: 620 - inset, height: 620 - inset))
            }
        case .ribbons:
            for index in 0..<4 {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: -80, y: 130 + CGFloat(index * 92)))
                path.addCurve(
                    to: CGPoint(x: rect.width + 80, y: 80 + CGFloat(index * 110)),
                    controlPoint1: CGPoint(x: rect.width * 0.28, y: 420 + CGFloat(index * 20)),
                    controlPoint2: CGPoint(x: rect.width * 0.68, y: -80 + CGFloat(index * 80))
                )
                accent.withAlphaComponent(0.11 + CGFloat(index) * 0.035).setStroke()
                path.lineWidth = 28 - CGFloat(index * 4)
                path.stroke()
            }
        case .grid:
            context.setStrokeColor(accent.withAlphaComponent(0.16).cgColor)
            context.setLineWidth(1)
            for x in stride(from: CGFloat(0), through: rect.width, by: 64) {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x, y: rect.height))
            }
            for y in stride(from: CGFloat(0), through: rect.height, by: 64) {
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: rect.width, y: y))
            }
            context.strokePath()
        case .prism:
            for index in 0..<7 {
                let width = CGFloat(240 + index * 34)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: rect.width - CGFloat(index * 62), y: -60))
                path.addLine(to: CGPoint(x: rect.width + 80, y: width * 0.52))
                path.addLine(to: CGPoint(x: rect.width - width * 0.42, y: width))
                path.close()
                accent.withAlphaComponent(0.035 + CGFloat(index) * 0.018).setFill()
                path.fill()
            }
        case .bubbles:
            for index in 0..<10 {
                let diameter = CGFloat(48 + (index % 4) * 38)
                let x = CGFloat((index * 137) % 940)
                let y = CGFloat((index * 83) % 560)
                context.setFillColor(accent.withAlphaComponent(0.06 + CGFloat(index % 3) * 0.035).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: diameter, height: diameter))
            }
        case .circuit:
            context.setStrokeColor(accent.withAlphaComponent(0.25).cgColor)
            context.setFillColor(accent.withAlphaComponent(0.55).cgColor)
            context.setLineWidth(3)
            for index in 0..<7 {
                let y = CGFloat(90 + index * 72)
                context.move(to: CGPoint(x: 60, y: y))
                context.addLine(to: CGPoint(x: 240 + CGFloat(index * 42), y: y))
                context.addLine(to: CGPoint(x: 300 + CGFloat(index * 42), y: y - 34))
                context.addLine(to: CGPoint(x: rect.width - 50, y: y - 34))
                context.strokePath()
                context.fillEllipse(in: CGRect(x: rect.width - 56, y: y - 40, width: 12, height: 12))
            }
        }
    }

    private static func read(_ path: String, maximumSize: Int) -> Data? {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) {
            return data.count <= maximumSize ? data : nil
        }
        return laramgr.shared.vfsready
            ? laramgr.shared.vfsread(path: path, maxSize: maximumSize)
            : nil
    }

    private static func write(_ path: String, data: Data) -> Bool {
        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            return true
        } catch {
            // Files outside the app container need Lara's privileged writer.
        }

        let result = laramgr.shared.lara_overwritefile(target: path, data: data)
        return result.ok
    }

    private static func clearCache(for card: CardTarget) {
        let cache = card.directoryPath.lowercased().hasSuffix(".pkpass")
            ? String(card.directoryPath.dropLast("pkpass".count)) + "cache"
            : card.directoryPath + ".cache"
        try? FileManager.default.removeItem(atPath: cache)
    }
}

private enum CompleteWallpaperStyleEngine {
    static func removeTrackedDescriptors(paths: [String]) -> Int {
        var removed = 0
        for path in paths {
            let url = URL(fileURLWithPath: path, isDirectory: true)
            let normalized = url.standardizedFileURL.path
            guard normalized.contains("/Library/Application Support/PRBPosterExtensionDataStore/"),
                  normalized.contains("/Extensions/"),
                  normalized.contains("/descriptors/"),
                  url.lastPathComponent.lowercased() != "descriptors" else { continue }
            do {
                try FileManager.default.removeItem(at: url)
                removed += 1
            } catch {
                laramgr.shared.logmsg("(styles) could not remove wallpaper descriptor: \(error.localizedDescription)")
            }
        }
        return removed
    }
}

struct CompleteStylesView: View {
    @ObservedObject private var manager = CompleteStyleManager.shared
    @ObservedObject private var mgr = laramgr.shared
    @State private var confirmRestore = false
    @State private var showAdvanced = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                intro

                if !mgr.sbxready {
                    LaraAccessView(compact: true) {
                        manager.refreshCompatibility()
                    }
                }

                if manager.hasActiveStyle,
                   let visual = manager.activeVisualPack {
                    activeStyle(
                        visual,
                        name: LaraL10n.localized(manager.activeStyleName ?? visual.name)
                    )
                }

                NavigationLink {
                    LaraMatchView()
                } label: {
                    HStack(spacing: 15) {
                        ZStack {
                            LinearGradient(
                                colors: [.indigo, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "camera.filters")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Eagle Match")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Crea un estilo desde una foto o video")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(15)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 21, style: .continuous)
                            .strokeBorder(Color.purple.opacity(0.12), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Colección Eagle")
                        .font(.title3.bold())
                    Text("Seis estilos completos. Ningún ajuste innecesario.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(CompleteStylePack.all) { pack in
                        NavigationLink {
                            CompleteStyleDetailView(pack: pack)
                        } label: {
                            CompleteStyleCard(
                                pack: pack,
                                isActive: manager.activePackID == pack.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                DisclosureGroup(isExpanded: $showAdvanced) {
                    NavigationLink {
                        CompleteStyleMixerView()
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: "slider.horizontal.2.square")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.indigo)
                                .frame(width: 42, height: 42)
                                .background(Color.indigo.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Crear combinación")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Mezcla fondo, código y tarjeta")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 12)
                    }
                    .buttonStyle(.plain)
                } label: {
                    Label("Crear algo propio", systemImage: "wand.and.sparkles")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("Los fondos y números provienen de la colección abierta de Nugget Wallpapers. Los diseños de tarjeta se generan en el dispositivo y Eagle conserva los originales.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Estilos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { manager.refreshCompatibility() }
        .onChange(of: mgr.sbxready) { _ in manager.refreshCompatibility() }
        .confirmationDialog(
            "¿Restaurar los originales?",
            isPresented: $confirmRestore,
            titleVisibility: .visible
        ) {
            Button("Restaurar cambios", role: .destructive) {
                manager.restoreOriginals()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Eagle restaurará los respaldos del código y la tarjeta, y retirará los fondos agregados desde Estilos.")
        }
        .sheet(item: $manager.lastResult) { result in
            CompleteStyleResultView(result: result)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Un aspecto completo, en un toque")
                .font(.title2.bold())
            Text("Elige una dirección visual. Eagle coordina el fondo, el código y la tarjeta, y te muestra el resultado de cada parte.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func activeStyle(_ pack: CompleteStylePack, name: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: pack.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [pack.secondary.color, pack.tertiary.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Estilo actual")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.headline)
            }
            Spacer()
            if manager.canUndo {
                Button("Deshacer") { manager.undoLastStyle() }
                    .font(.subheadline.weight(.semibold))
                    .disabled(manager.isWorking || !mgr.sbxready)
            }
            Menu {
                Button(role: .destructive) { confirmRestore = true } label: {
                    Label("Restaurar originales", systemImage: "arrow.uturn.backward")
                }
                Button { manager.clearDownloadedStyles() } label: {
                    Label("Vaciar descargas", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .disabled(manager.isWorking)
        }
        .padding(15)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(pack.secondary.color.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct CompleteStyleCard: View {
    let pack: CompleteStylePack
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: pack.tones.map(\.color),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                motif

                Image(systemName: pack.symbol)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white.opacity(0.94))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 5)

                if isActive {
                    Label("Activo", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.26), in: Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(10)
                }
            }
            .frame(height: 132)

            VStack(alignment: .leading, spacing: 5) {
                Text(pack.localizedName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(pack.localizedTagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
        }
    }

    private var motif: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 2)
                .frame(width: 150, height: 150)
                .offset(x: 64, y: -48)
            Circle()
                .fill(pack.tertiary.color.opacity(0.18))
                .frame(width: 70, height: 70)
                .offset(x: -72, y: 58)
        }
    }
}

private struct CompleteStyleDetailView: View {
    let pack: CompleteStylePack
    @ObservedObject private var manager = CompleteStyleManager.shared
    @ObservedObject private var mgr = laramgr.shared
    @State private var includeWallpaper = true
    @State private var includePasscode = true
    @State private var includeCard = true
    @State private var showOptions = false
    @State private var showLivePreview = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CompleteStylePreview(pack: pack)

                Button {
                    showLivePreview = true
                } label: {
                    Label("Ver vista previa real", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!(includeWallpaper || includePasscode || includeCard))

                VStack(alignment: .leading, spacing: 7) {
                    Text(pack.localizedName)
                        .font(.largeTitle.bold())
                    Text(pack.localizedTagline)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(pack.tertiary.color)
                    Text(pack.localizedSummary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                componentSummary

                if !mgr.sbxready {
                    LaraAccessView(compact: true) {
                        manager.refreshCompatibility()
                    }
                }

                DisclosureGroup(isExpanded: $showOptions) {
                    VStack(spacing: 0) {
                        optionToggle(
                            "Fondo",
                            detail: pack.wallpaperName,
                            systemImage: CompleteStyleComponent.wallpaper.systemImage,
                            isOn: $includeWallpaper,
                            available: true
                        )
                        Divider().padding(.leading, 50)
                        optionToggle(
                            "Código",
                            detail: manager.passcodeAvailable ? pack.passcodeName : "Se comprobará al preparar Eagle",
                            systemImage: CompleteStyleComponent.passcode.systemImage,
                            isOn: $includePasscode,
                            available: mgr.sbxready ? manager.passcodeAvailable : true
                        )
                        Divider().padding(.leading, 50)
                        optionToggle(
                            "Tarjeta",
                            detail: manager.cardAvailable ? "Diseño coordinado" : "Se omitirá si no hay tarjeta compatible",
                            systemImage: CompleteStyleComponent.card.systemImage,
                            isOn: $includeCard,
                            available: mgr.sbxready ? manager.cardAvailable : true
                        )
                    }
                    .padding(.top, 8)
                } label: {
                    Label("Personalizar antes de aplicar", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                if manager.isWorking {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text(manager.stage)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(Int(manager.progress * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: manager.progress)
                            .tint(pack.tertiary.color)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button {
                    manager.apply(
                        pack: pack,
                        wallpaper: includeWallpaper,
                        passcode: includePasscode,
                        card: includeCard
                    )
                } label: {
                    HStack(spacing: 10) {
                        if manager.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(manager.isWorking
                            ? LaraL10n.text(en: "Applying \(pack.localizedName)…", es: "Aplicando \(pack.localizedName)…")
                            : LaraL10n.text(en: "Apply style", es: "Aplicar estilo"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(pack.secondary.color)
                .controlSize(.large)
                .disabled(manager.isWorking || !mgr.sbxready || !(includeWallpaper || includePasscode || includeCard))

                credits
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(pack.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { manager.refreshCompatibility() }
        .onChange(of: mgr.sbxready) { _ in manager.refreshCompatibility() }
        .fullScreenCover(isPresented: $showLivePreview) {
            CompleteStyleLivePreviewView(
                title: pack.localizedName,
                wallpaperPack: includeWallpaper ? pack : nil,
                passcodePack: includePasscode ? pack : nil,
                cardPack: includeCard ? pack : nil
            ) {
                manager.apply(
                    pack: pack,
                    wallpaper: includeWallpaper,
                    passcode: includePasscode,
                    card: includeCard
                )
            }
        }
    }

    private var componentSummary: some View {
        VStack(spacing: 0) {
            componentRow(.wallpaper, value: pack.wallpaperName)
            Divider().padding(.leading, 52)
            componentRow(.passcode, value: pack.passcodeName)
            Divider().padding(.leading, 52)
            componentRow(.card, value: LaraL10n.text(en: "Eagle design", es: "Diseño Eagle"))
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
    }

    private func componentRow(_ component: CompleteStyleComponent, value: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: component.systemImage)
                .foregroundStyle(pack.tertiary.color)
                .frame(width: 34, height: 34)
                .background(pack.tertiary.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(component.title).font(.subheadline.weight(.semibold))
                Text(value).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(.green)
        }
        .padding(14)
    }

    private func optionToggle(
        _ title: String,
        detail: String,
        systemImage: String,
        isOn: Binding<Bool>,
        available: Bool
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(pack.tertiary.color)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LaraL10n.localized(title)).font(.subheadline.weight(.medium))
                    Text(LaraL10n.localized(detail)).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .tint(pack.secondary.color)
        .padding(.vertical, 10)
        .disabled(!available)
    }

    private var credits: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Créditos")
                .font(.footnote.weight(.semibold))
            Text("Fondo \(pack.wallpaperName) por \(pack.wallpaperAuthor). Código \(pack.passcodeName) por \(pack.passcodeAuthor). Curaduría y tarjeta por Eagle.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Link(
                "Abrir Nugget Wallpapers",
                destination: URL(string: "https://github.com/SerStars/Nugget-Wallpapers")!
            )
            .font(.footnote.weight(.medium))
        }
    }
}

private struct CompleteStylePreview: View {
    let pack: CompleteStylePack

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pack.tones.map(\.color),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(pack.tertiary.color.opacity(0.24))
                .frame(width: 210, height: 210)
                .blur(radius: 2)
                .offset(x: 130, y: -130)

            HStack(alignment: .bottom, spacing: -20) {
                phonePreview
                cardPreview
                    .offset(y: -24)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 350)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: pack.primary.color.opacity(0.22), radius: 22, y: 12)
    }

    private var phonePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black)

            LaraRemoteMediaPreview(
                url: pack.wallpaperPreviewURL,
                animated: false,
                contentMode: .fill,
                showsRetry: false,
                background: pack.secondary.color
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(4)

            VStack(spacing: 2) {
                Text("jueves, 13 de agosto")
                    .font(.system(size: 7, weight: .semibold))
                Text("9:41")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                Spacer()
                VStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(1..<4, id: \.self) { column in
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 25, height: 25)
                                    .overlay {
                                        Text("\(row * 3 + column)")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                            }
                        }
                    }
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 5, y: 2)
            .padding(.top, 26)
            .padding(.bottom, 22)
        }
        .frame(width: 150, height: 304)
        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }

    private var cardPreview: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [pack.primary.color, pack.secondary.color, pack.tertiary.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 178, height: 112)
            .overlay(alignment: .topLeading) {
                Image(systemName: pack.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(16)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "wave.3.right")
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(16)
            }
            .rotationEffect(.degrees(4))
            .shadow(color: .black.opacity(0.25), radius: 14, y: 9)
    }
}

private struct CompleteStyleResultView: View {
    let result: CompleteStyleRunResult
    @ObservedObject private var manager = CompleteStyleManager.shared
    @ObservedObject private var mgr = laramgr.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 7) {
                        Image(systemName: result.components.contains(where: { $0.state == .applied })
                              ? "checkmark.seal.fill"
                              : "exclamationmark.triangle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(result.components.contains(where: { $0.state == .applied }) ? Color.green : Color.orange)
                        Text(result.title)
                            .font(.title2.bold())
                        Text(result.message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    if !result.components.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(result.components.enumerated()), id: \.element.id) { index, item in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: item.state.systemImage)
                                        .foregroundStyle(item.state.color)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.component.title)
                                            .font(.headline)
                                        Text(item.detail)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(15)
                                if index < result.components.count - 1 {
                                    Divider().padding(.leading, 50)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    VStack(spacing: 10) {
                        if result.installedWallpaper {
                            Button {
                                manager.openWallpaperPicker()
                            } label: {
                                Label("Elegir el fondo", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }

                        if result.changedSystemArtwork {
                            Button {
                                mgr.respring()
                            } label: {
                                Label("Reiniciar interfaz", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }

                        if manager.canUndo,
                           result.components.contains(where: { $0.state == .applied }) {
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    manager.undoLastStyle()
                                }
                            } label: {
                                Label("Deshacer este cambio", systemImage: "arrow.uturn.backward")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onDisappear { manager.clearResult() }
    }
}
