import SwiftUI
import Combine
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
        case .wallpaper: return "Fondo"
        case .passcode: return "Código"
        case .card: return "Tarjeta"
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
    case nothingToRestore

    var errorDescription: String? {
        switch self {
        case .badDownload:
            return "No se pudo descargar uno de los recursos del estilo."
        case .incompletePasscode:
            return "El tema del código no contiene los diez números."
        case .passcodeUnavailable:
            return "No se encontró la caché del código en este iPhone."
        case .cardUnavailable:
            return "No se encontró una tarjeta de Wallet compatible."
        case .cardImageFailed:
            return "No se pudo generar el diseño de la tarjeta."
        case .cardBackupFailed:
            return "No se pudo conservar la tarjeta original; Lara no realizó el cambio."
        case .cardWriteFailed(let message):
            return "No se pudo actualizar la tarjeta: \(message)"
        case .nothingToRestore:
            return "Todavía no hay cambios de Estilos para restaurar."
        }
    }
}

@MainActor
final class CompleteStyleManager: ObservableObject {
    static let shared = CompleteStyleManager()

    @Published private(set) var isWorking = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var stage = "Preparando"
    @Published private(set) var passcodeAvailable = false
    @Published private(set) var cardAvailable = false
    @Published var lastResult: CompleteStyleRunResult?
    @Published private(set) var activePackID: String?

    private let activePackKey = "lara.completeStyles.activePack"
    private let wallpaperPathsKey = "lara.completeStyles.wallpaperPaths"

    private init() {
        activePackID = UserDefaults.standard.string(forKey: activePackKey)
    }

    var activePack: CompleteStylePack? {
        CompleteStylePack.all.first { $0.id == activePackID }
    }

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
        guard !isWorking else { return }
        guard laramgr.shared.sbxready else {
            lastResult = CompleteStyleRunResult(
                title: "Lara necesita acceso",
                message: "Pulsa Continuar en Preparar acceso antes de aplicar un estilo.",
                components: []
            )
            return
        }

        let selectedCount = [wallpaper, passcode, card].filter { $0 }.count
        guard selectedCount > 0 else {
            lastResult = CompleteStyleRunResult(
                title: "Elige al menos una parte",
                message: "Activa Fondo, Código o Tarjeta en las opciones del estilo.",
                components: []
            )
            return
        }

        isWorking = true
        progress = 0
        stage = "Comprobando compatibilidad"
        lastResult = nil

        Task {
            var completed = 0
            var results: [CompleteStyleComponentResult] = []
            var installedWallpaperPaths: [String] = []

            @MainActor func advance(_ nextStage: String) {
                completed += 1
                progress = Double(completed) / Double(selectedCount)
                stage = nextStage
            }

            if passcode {
                stage = "Preparando \(pack.passcodeName)"
                do {
                    guard CompletePasscodeStyleEngine.basePath() != nil else {
                        throw CompleteStyleEngineError.passcodeUnavailable
                    }
                    let data = try await download(pack.passcodeURL, maximumSize: 50 * 1024 * 1024)
                    let images = try CompletePasscodeStyleEngine.images(from: data)
                    let count = try CompletePasscodeStyleEngine.apply(images: images)
                    results.append(.init(
                        component: .passcode,
                        state: .applied,
                        detail: "\(pack.passcodeName), \(count) archivos verificados"
                    ))
                } catch CompleteStyleEngineError.passcodeUnavailable {
                    results.append(.init(
                        component: .passcode,
                        state: .skipped,
                        detail: "No disponible en este dispositivo"
                    ))
                } catch {
                    results.append(.init(
                        component: .passcode,
                        state: .failed,
                        detail: error.localizedDescription
                    ))
                }
                advance("Código terminado")
            }

            if card {
                stage = "Diseñando la tarjeta"
                do {
                    try CompleteCardStyleEngine.apply(pack: pack)
                    results.append(.init(
                        component: .card,
                        state: .applied,
                        detail: "Diseño creado localmente y respaldado"
                    ))
                } catch CompleteStyleEngineError.cardUnavailable {
                    results.append(.init(
                        component: .card,
                        state: .skipped,
                        detail: "No hay una tarjeta compatible en Wallet"
                    ))
                } catch {
                    results.append(.init(
                        component: .card,
                        state: .failed,
                        detail: error.localizedDescription
                    ))
                }
                advance("Tarjeta terminada")
            }

            if wallpaper {
                stage = "Instalando \(pack.wallpaperName)"
                do {
                    let data = try await download(
                        pack.wallpaperURL,
                        maximumSize: TendiesInstaller.maximumCompressedSize
                    )
                    let install = try TendiesInstaller.install(data: data)
                    installedWallpaperPaths = install.installedDestinations.map(\.path)
                    results.append(.init(
                        component: .wallpaper,
                        state: .applied,
                        detail: install.installedCount > 0
                            ? "\(pack.wallpaperName) agregado a Fondos"
                            : "\(pack.wallpaperName) ya estaba instalado"
                    ))
                } catch {
                    results.append(.init(
                        component: .wallpaper,
                        state: .failed,
                        detail: error.localizedDescription
                    ))
                }
                advance("Fondo terminado")
            }

            let applied = results.filter { $0.state == .applied }.count
            let failed = results.filter { $0.state == .failed }.count
            if applied > 0 {
                activePackID = pack.id
                UserDefaults.standard.set(pack.id, forKey: activePackKey)
                rememberWallpaperPaths(installedWallpaperPaths)
            }

            let message: String
            if applied == selectedCount {
                message = "Las partes elegidas se aplicaron y verificaron correctamente."
            } else if applied > 0 {
                message = failed > 0
                    ? "El estilo se aplicó parcialmente. Revisa cada resultado."
                    : "Se aplicó todo lo compatible con este iPhone."
            } else {
                message = "No se pudo aplicar ninguna de las partes elegidas."
            }

            lastResult = CompleteStyleRunResult(
                title: applied > 0 ? "\(pack.name) está listo" : "No se aplicó el estilo",
                message: message,
                components: results
            )
            progress = 1
            stage = "Listo"
            isWorking = false
            refreshCompatibility()

            if results.contains(where: { $0.component == .wallpaper && $0.state == .applied }) {
                _ = PosterBoardWriter.refreshCollections()
            }
        }
    }

    func restoreOriginals() {
        guard !isWorking else { return }
        guard laramgr.shared.sbxready else {
            lastResult = CompleteStyleRunResult(
                title: "Lara necesita acceso",
                message: "Prepara el acceso antes de restaurar.",
                components: []
            )
            return
        }

        isWorking = true
        progress = 0
        stage = "Restaurando originales"

        Task {
            var results: [CompleteStyleComponentResult] = []

            do {
                let restored = try CompletePasscodeStyleEngine.restoreOriginals()
                results.append(.init(
                    component: .passcode,
                    state: restored ? .applied : .skipped,
                    detail: restored ? "Números originales restaurados" : "No había respaldo del código"
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
                    detail: restored ? "Tarjeta original restaurada" : "No había respaldo de tarjeta"
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
                detail: removed > 0 ? "Se retiraron \(removed) fondos agregados por Estilos" : "No había fondos registrados"
            ))
            UserDefaults.standard.removeObject(forKey: wallpaperPathsKey)
            UserDefaults.standard.removeObject(forKey: activePackKey)
            activePackID = nil

            progress = 1
            stage = "Originales restaurados"
            isWorking = false
            lastResult = CompleteStyleRunResult(
                title: "Restauración terminada",
                message: "Lara restauró los respaldos disponibles. Puedes reiniciar la interfaz para ver todos los cambios.",
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

    private func download(_ url: URL, maximumSize: Int) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 120
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              data.count <= maximumSize else {
            throw CompleteStyleEngineError.badDownload
        }
        return data
    }

    private func rememberWallpaperPaths(_ paths: [String]) {
        guard !paths.isEmpty else { return }
        var stored = UserDefaults.standard.stringArray(forKey: wallpaperPathsKey) ?? []
        for path in paths where !stored.contains(path) {
            stored.append(path)
        }
        UserDefaults.standard.set(stored, forKey: wallpaperPathsKey)
    }
}

private enum CompletePasscodeStyleEngine {
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
private enum CompleteCardStyleEngine {
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

                if let active = manager.activePack {
                    activeStyle(active)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Colección Lara")
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

                Text("Los fondos y números provienen de la colección abierta de Nugget Wallpapers. Los diseños de tarjeta se generan en el dispositivo y Lara conserva los originales.")
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
            Text("Lara restaurará los respaldos del código y la tarjeta, y retirará los fondos agregados desde Estilos.")
        }
        .sheet(item: $manager.lastResult) { result in
            CompleteStyleResultView(result: result)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Un aspecto completo, en un toque")
                .font(.title2.bold())
            Text("Elige una dirección visual. Lara coordina el fondo, el código y la tarjeta, y te muestra el resultado de cada parte.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func activeStyle(_ pack: CompleteStylePack) -> some View {
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
                Text(pack.name)
                    .font(.headline)
            }
            Spacer()
            Button("Restaurar") { confirmRestore = true }
                .font(.subheadline.weight(.semibold))
                .disabled(manager.isWorking || !mgr.sbxready)
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
                Text(pack.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(pack.tagline)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CompleteStylePreview(pack: pack)

                VStack(alignment: .leading, spacing: 7) {
                    Text(pack.name)
                        .font(.largeTitle.bold())
                    Text(pack.tagline)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(pack.tertiary.color)
                    Text(pack.summary)
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
                            detail: manager.passcodeAvailable ? pack.passcodeName : "Se comprobará al preparar Lara",
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
                        Text(manager.isWorking ? "Aplicando \(pack.name)…" : "Aplicar estilo")
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
        .navigationTitle(pack.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { manager.refreshCompatibility() }
        .onChange(of: mgr.sbxready) { _ in manager.refreshCompatibility() }
    }

    private var componentSummary: some View {
        VStack(spacing: 0) {
            componentRow(.wallpaper, value: pack.wallpaperName)
            Divider().padding(.leading, 52)
            componentRow(.passcode, value: pack.passcodeName)
            Divider().padding(.leading, 52)
            componentRow(.card, value: "Diseño Lara")
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
                    Text(title).font(.subheadline.weight(.medium))
                    Text(detail).font(.caption).foregroundStyle(.secondary)
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
            Text("Fondo \(pack.wallpaperName) por \(pack.wallpaperAuthor). Código \(pack.passcodeName) por \(pack.passcodeAuthor). Curaduría y tarjeta por Lara.")
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

            AsyncImage(url: pack.wallpaperPreviewURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: [pack.primary.color, pack.secondary.color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
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
