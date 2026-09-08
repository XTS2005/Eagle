import SwiftUI
import UIKit

enum IslandGalleryStyle: Int, CaseIterable, Identifiable {
    case starlight = 9
    case inferno = 10
    case horizon = 11
    case vortex = 12
    case bubblegum = 13
    case traffic = 14
    case duckMood = 32
    case blueScreen = 33
    case walkingFlame = 34
    case singularityLive = 36

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .starlight: return LaraL10n.text(en: "Starlight", es: "Luz estelar")
        case .inferno: return LaraL10n.text(en: "Inferno", es: "Inferno")
        case .horizon: return LaraL10n.text(en: "Horizon", es: "Horizonte")
        case .vortex: return LaraL10n.text(en: "Vortex", es: "Vórtice")
        case .bubblegum: return LaraL10n.text(en: "Bubblegum", es: "Chicle")
        case .traffic: return LaraL10n.text(en: "Traffic", es: "Tráfico")
        case .duckMood: return LaraL10n.text(en: "Duck Mood", es: "Humor de pato")
        case .blueScreen: return LaraL10n.text(en: "Blue Screen", es: "Pantalla azul")
        case .walkingFlame: return LaraL10n.text(en: "Walking Flame", es: "Llama ambulante")
        case .singularityLive: return "Singularity"
        }
    }

    var subtitle: String {
        switch self {
        case .starlight:
            return LaraL10n.text(en: "Glossy color and gold stars", es: "Color brillante y estrellas doradas")
        case .inferno:
            return LaraL10n.text(en: "Crimson stone and dark emblems", es: "Piedra carmesí y emblemas oscuros")
        case .horizon:
            return LaraL10n.text(en: "Blue horizon and gold clouds", es: "Horizonte azul y nubes doradas")
        case .vortex:
            return LaraL10n.text(en: "Green energy vortex", es: "Vórtice de energía verde")
        case .bubblegum:
            return LaraL10n.text(en: "Pink and yellow bubbles", es: "Burbujas rosas y amarillas")
        case .traffic:
            return LaraL10n.text(en: "Painted road signs", es: "Señales de tránsito pintadas")
        case .duckMood:
            return LaraL10n.text(en: "Classic animated duck close-up", es: "Primer plano de pato animado clásico")
        case .blueScreen:
            return LaraL10n.text(en: "Electric blue system portrait", es: "Retrato de sistema azul eléctrico")
        case .walkingFlame:
            return LaraL10n.text(en: "Surreal street fire portrait", es: "Retrato surrealista de fuego urbano")
        case .singularityLive:
            return LaraL10n.text(en: "Live video · Vortex fit", es: "Video Live · ajuste de Vortex")
        }
    }

    var assetName: String {
        switch self {
        case .starlight: return "PhotoAuraRainbow"
        case .inferno: return "PhotoAuraInferno"
        case .horizon: return "PhotoAuraSky"
        case .vortex: return "PhotoAuraVortex"
        case .bubblegum: return "PhotoAuraBubblegum"
        case .traffic: return "PhotoAuraTraffic"
        case .duckMood: return "PhotoAuraDuckMood"
        case .blueScreen: return "PhotoAuraBlueScreen"
        case .walkingFlame: return "PhotoAuraWalkingFlame"
        case .singularityLive: return "PhotoAuraVortex"
        }
    }

    var accent: Color {
        switch self {
        case .starlight: return Color(red: 1.00, green: 0.18, blue: 0.67)
        case .inferno: return Color(red: 1.00, green: 0.14, blue: 0.14)
        case .horizon: return Color(red: 0.15, green: 0.69, blue: 1.00)
        case .vortex: return Color(red: 0.36, green: 1.00, blue: 0.08)
        case .bubblegum: return Color(red: 1.00, green: 0.25, blue: 0.60)
        case .traffic: return Color(red: 1.00, green: 0.32, blue: 0.08)
        case .duckMood: return Color(red: 1.00, green: 0.47, blue: 0.08)
        case .blueScreen: return Color(red: 0.10, green: 0.28, blue: 1.00)
        case .walkingFlame: return Color(red: 1.00, green: 0.30, blue: 0.06)
        case .singularityLive: return Color(white: 0.85)
        }
    }

    var rgb: (red: Int32, green: Int32, blue: Int32) {
        switch self {
        case .starlight: return (255, 45, 170)
        case .inferno: return (255, 36, 36)
        case .horizon: return (39, 176, 255)
        case .vortex: return (92, 255, 20)
        case .bubblegum: return (255, 64, 154)
        case .traffic: return (255, 82, 20)
        case .duckMood: return (255, 120, 20)
        case .blueScreen: return (26, 71, 255)
        case .walkingFlame: return (255, 77, 15)
        case .singularityLive: return (217, 217, 217)
        }
    }
}

private final class IslandGalleryRemoteCallBox: @unchecked Sendable {
    let value: RemoteCall

    init(_ value: RemoteCall) {
        self.value = value
    }
}

private struct IslandGalleryNativeResponse: @unchecked Sendable {
    let result: Int32
    let targetPID: Int32
    let springBoardPID: Int32
    let healthy: Bool
    let timedOut: Bool
    let error: String?
}

struct IslandGalleryApplyResult {
    let succeeded: Bool
    let message: String
}

/// Runs the same isolated, one-surface native transaction as Aura Studio.
/// Gallery styles differ by native mode/asset, halo color and user-selected
/// shadow strength; every style is installed and read back by one verifier.
@MainActor
final class IslandGalleryExecutor {
    static let shared = IslandGalleryExecutor()

    private let manager = laramgr.shared
    private let islandFlag: UInt32 = 1
    private let supportedFlags: UInt32 = 1 | (1 << 5)
    private var operationInProgress = false

    private init() {}

    func apply(_ style: IslandGalleryStyle, shadowIntensity: Double) async -> IslandGalleryApplyResult {
        await run(style: style, restoring: false, shadowIntensity: shadowIntensity)
    }

    func applyLive(_ theme: IslandLiveTheme, shadowIntensity: Double) async -> IslandGalleryApplyResult {
        await run(
            style: .singularityLive,
            restoring: false,
            liveTheme: theme,
            shadowIntensity: shadowIntensity
        )
    }

    func restore() async -> IslandGalleryApplyResult {
        await run(style: nil, restoring: true)
    }

    private func run(
        style: IslandGalleryStyle?,
        restoring: Bool,
        liveTheme: IslandLiveTheme? = nil,
        shadowIntensity: Double = 0.72
    ) async -> IslandGalleryApplyResult {
        // Views can disappear and be reopened while a package is downloading.
        // The singleton owns the lock across every suspension, not just the UI.
        guard !operationInProgress else {
            return failure(en: "An Island update is already running. Please wait.",
                           es: "Ya hay una actualización de Island en curso. Espera a que termine.")
        }
        operationInProgress = true
        defer { operationInProgress = false }
        guard !Task.isCancelled, UIApplication.shared.applicationState == .active else {
            return failure(en: "Return to Eagle before applying a theme.",
                           es: "Vuelve a Eagle antes de aplicar un tema.")
        }
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let compatibility = EagleDynamicIslandCompatibility.current

        guard manager.dsready else {
            return failure(
                en: "Prepare Eagle access before changing Dynamic Island.",
                es: "Prepara el acceso de Eagle antes de cambiar Dynamic Island."
            )
        }
        guard !manager.rcSafetyLocked else {
            return failure(
                en: "The protected call channel is safety locked. Fully close and reopen Eagle before retrying.",
                es: "El canal protegido está bloqueado por seguridad. Cierra Eagle completamente y vuelve a abrirlo antes de reintentar."
            )
        }
        guard !isdebugged() else {
            return failure(
                en: "Stop the Xcode run and open Eagle manually from the Home Screen before applying a style.",
                es: "Detén la ejecución de Xcode y abre Eagle manualmente desde Inicio antes de aplicar un estilo."
            )
        }
        guard version.majorVersion == 17 || version.majorVersion == 18 else {
            return failure(
                en: "Island Gallery is verified only on iOS 17 and iOS 18.",
                es: "Galería Island está verificada solo en iOS 17 y iOS 18."
            )
        }
        guard compatibility.canAttemptLiveIslandAura else {
            return failure(
                en: "This physical iPhone does not expose a verified Dynamic Island host.",
                es: "Este iPhone físico no expone un host verificado de Dynamic Island."
            )
        }
        if !restoring {
            guard style != nil,
                  EagleFeaturePolicy.allows(.auraRainbow) else {
                return failure(
                    en: "Island Gallery requires the same feature level as advanced Island styles.",
                    es: "Galería Island requiere el mismo nivel de funciones que los estilos avanzados de Island."
                )
            }
        }

        let liveDirectory: URL?
        if style == .singularityLive && !restoring {
            do {
                liveDirectory = try await IslandLiveMedia.prepare(theme: liveTheme)
            } catch {
                return failure(
                    en: "The Island video could not be downloaded or verified. Your current Island was not changed.",
                    es: "No se pudo descargar o verificar el video de Island. Tu Island actual no se cambió."
                )
            }
        } else {
            liveDirectory = nil
        }

        guard !Task.isCancelled, UIApplication.shared.applicationState == .active,
              manager.dsready, !manager.rcSafetyLocked else {
            return failure(en: "The theme is ready. Return to Eagle and apply it again.",
                           es: "El tema está listo. Vuelve a Eagle y aplícalo de nuevo.")
        }

        let operationID = String(UUID().uuidString.prefix(8))
        log(
            "begin",
            "op=\(operationID) action=\(restoring ? "restore" : "apply") " +
                "mode=\(style?.rawValue ?? 0) liveID=\(liveTheme?.id ?? "singularity-live") device=\(compatibility.modelIdentifier) " +
                "display=\(AuraStudioDisplayGeometry.current.isDisplayZoomed ? "zoomed" : "standard")"
        )

        let preparation: (RemoteCall?, String?) = await withCheckedContinuation { continuation in
            manager.prepareFreshRemoteCall(process: "SpringBoard", timeout: 20) { process, error in
                continuation.resume(returning: (process, error))
            }
        }
        guard let process = preparation.0 else {
            return failure(
                en: "A fresh SpringBoard session could not be prepared. Nothing was changed. \(preparation.1 ?? "")",
                es: "No se pudo preparar una sesión nueva de SpringBoard. No se cambió nada. \(preparation.1 ?? "")"
            )
        }

        let label = "Island Gallery \(operationID)"
        guard !Task.isCancelled,
              manager.beginExclusiveRemoteCall(label: label, expectedSession: process) else {
            return failure(
                en: "Another protected SpringBoard operation is still active.",
                es: "Otra operación protegida de SpringBoard sigue activa."
            )
        }
        defer { manager.endExclusiveRemoteCall(label: label) }

        let targetPID = process.pid
        let currentPID = Self.readSpringBoardPID()
        guard targetPID > 0,
              targetPID == currentPID,
              process.creatingExtraThread else {
            return failure(
                en: "The SpringBoard session identity changed before Apply. Nothing was sent.",
                es: "La identidad de la sesión de SpringBoard cambió antes de Aplicar. No se envió nada."
            )
        }

        let processBox = IslandGalleryRemoteCallBox(process)
        let mode = Int32(style?.rawValue ?? 0)
        let rgb = liveTheme?.rgb ?? style?.rgb ?? (red: 0, green: 0, blue: 0)
        let requestedFlag = islandFlag
        let requestedShadowIntensity = Int32(
            (min(max(shadowIntensity.isFinite ? shadowIntensity : 0.72, 0), 1) * 100).rounded()
        )
        let response: IslandGalleryNativeResponse = await withCheckedContinuation { continuation in
            let workItem = DispatchWorkItem {
                let nativeResult = autoreleasepool {
                    if let liveDirectory {
                        liveDirectory.path.withCString { eagle_configure_island_live_gallery($0) }
                    } else {
                        eagle_configure_island_live_gallery(nil)
                    }
                    defer { eagle_configure_island_live_gallery(nil) }
                    eagle_set_island_gallery_shadow_intensity(requestedShadowIntensity)
                    return eagle_set_aura_studio(
                        processBox.value,
                        rgb.red,
                        rgb.green,
                        rgb.blue,
                        mode,
                        requestedFlag
                    )
                }
                continuation.resume(returning: IslandGalleryNativeResponse(
                    result: nativeResult,
                    targetPID: targetPID,
                    springBoardPID: Self.readSpringBoardPID(),
                    healthy: processBox.value.isHealthy,
                    timedOut: processBox.value.lastCallTimedOut,
                    error: processBox.value.lastError
                ))
            }
            DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        }
        log(
            "native.end",
            "op=\(operationID) result=\(response.result) target=\(response.targetPID) " +
                "current=\(response.springBoardPID) healthy=\(response.healthy) " +
                "timeout=\(response.timedOut) error=\(response.error ?? "none")"
        )

        guard response.targetPID == response.springBoardPID else {
            clearVerifiedIsland()
            manager.quarantineRemoteCall(reason: "SpringBoard restarted during Island Gallery verification")
            return failure(
                en: "SpringBoard restarted during verification. The style was not reported as applied.",
                es: "SpringBoard se reinició durante la verificación. El estilo no se marcó como aplicado."
            )
        }
        guard response.healthy,
              !response.timedOut,
              response.error?.isEmpty != false else {
            clearVerifiedIsland()
            manager.quarantineRemoteCall(
                reason: response.error ?? "Island Gallery transport became unhealthy"
            )
            return failure(
                en: "The protected call channel became unhealthy. Fully close and reopen Eagle before retrying.",
                es: "El canal protegido dejó de estar disponible. Cierra Eagle completamente y vuelve a abrirlo antes de reintentar."
            )
        }
        if response.result == -12 {
            return failure(
                en: "The new Island could not be read back safely, so Eagle removed it and preserved the previous verified Island. You may retry without restarting.",
                es: "No se pudo verificar la Island nueva, así que Eagle la eliminó y conservó la Island verificada anterior. Puedes reintentar sin reiniciar."
            )
        }
        if [-2, -17, -20].contains(response.result) {
            return failure(
                en: "SpringBoard did not expose the verified Island surface in its current state. Nothing was changed.",
                es: "SpringBoard no expuso la superficie Island verificada en su estado actual. No se cambió nada."
            )
        }
        guard response.result >= 0 else {
            clearVerifiedIsland()
            manager.quarantineRemoteCall(
                reason: "Island Gallery returned unverified result \(response.result)"
            )
            return failure(
                en: "Native Apply returned unverified result \(response.result). Fully close and reopen Eagle before retrying.",
                es: "Aplicar devolvió el resultado no verificado \(response.result). Cierra Eagle completamente y vuelve a abrirlo antes de reintentar."
            )
        }

        let flags = UInt32(bitPattern: response.result)
        guard flags & islandFlag == islandFlag else {
            clearVerifiedIsland()
            manager.quarantineRemoteCall(reason: "Island Gallery did not verify its requested host")
            return failure(
                en: "SpringBoard returned without verifying Dynamic Island.",
                es: "SpringBoard terminó sin verificar Dynamic Island."
            )
        }

        if restoring {
            clearVerifiedIsland(springBoardPID: response.springBoardPID)
            return IslandGalleryApplyResult(
                succeeded: true,
                message: LaraL10n.text(
                    en: "The original Dynamic Island appearance was restored and verified.",
                    es: "Se restauró y verificó la apariencia original de Dynamic Island."
                )
            )
        }
        guard let style else {
            return failure(en: "No style was selected.", es: "No se seleccionó ningún estilo.")
        }
        persistVerified(
            style: style,
            springBoardPID: response.springBoardPID,
            liveTheme: liveTheme,
            shadowIntensity: Double(requestedShadowIntensity) / 100.0
        )
        let title = liveTheme.map { LaraL10n.text(en: $0.title, es: $0.titleES) } ?? style.title
        if style == .singularityLive && UIAccessibility.isReduceMotionEnabled {
            return IslandGalleryApplyResult(
                succeeded: true,
                message: LaraL10n.text(
                    en: "\(title) was applied as a still image because Reduce Motion is enabled.",
                    es: "\(title) se aplicó como imagen fija porque Reducir movimiento está activado."
                )
            )
        }
        if style == .singularityLive {
            return IslandGalleryApplyResult(succeeded: true, message: LaraL10n.text(
                en: "\(title) was applied with Live playback.",
                es: "\(title) se aplicó con reproducción Live."
            ))
        }
        return IslandGalleryApplyResult(
            succeeded: true,
            message: LaraL10n.text(
                en: "\(style.title) was applied and verified with its \(haloName(for: style)) halo.",
                es: "\(style.title) se aplicó y verificó con su halo \(haloName(for: style))."
            )
        )
    }

    private func persistVerified(
        style: IslandGalleryStyle,
        springBoardPID: Int32,
        liveTheme: IslandLiveTheme? = nil,
        shadowIntensity: Double
    ) {
        let defaults = UserDefaults.standard
        let savedPID = defaults.integer(forKey: "eagle.auraStudio.activeSpringBoardPID")
        var flags = savedPID == Int(springBoardPID)
            ? EagleStoredThemeValues.flags(defaults.integer(forKey: "eagle.auraStudio.activeFlags")) & supportedFlags
            : 0
        flags |= islandFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(Int(springBoardPID), forKey: "eagle.auraStudio.activeSpringBoardPID")
        defaults.set(style.rawValue, forKey: "eagle.auraStudio.island.mode")
        defaults.set(style.rawValue, forKey: "eagle.auraStudio.activeMode")
        defaults.set(style.rawValue, forKey: "eagle.auraStudio.activeIslandMode")
        defaults.set(style.rawValue, forKey: "eagle.islandGallery.selectedStyle")
        defaults.set(shadowIntensity, forKey: "eagle.islandGallery.appliedShadowIntensity")
        let rgb = liveTheme?.rgb ?? style.rgb
        defaults.set(Int(rgb.red), forKey: "eagle.auraStudio.activeIslandRed")
        defaults.set(Int(rgb.green), forKey: "eagle.auraStudio.activeIslandGreen")
        defaults.set(Int(rgb.blue), forKey: "eagle.auraStudio.activeIslandBlue")
        if style == .singularityLive {
            defaults.set(liveTheme?.id ?? "singularity-live", forKey: "eagle.islandGallery.activeLiveID")
        } else {
            defaults.removeObject(forKey: "eagle.islandGallery.activeLiveID")
        }
    }

    private func clearVerifiedIsland(springBoardPID: Int32? = nil) {
        let defaults = UserDefaults.standard
        var flags = EagleStoredThemeValues.flags(defaults.integer(forKey: "eagle.auraStudio.activeFlags")) & supportedFlags
        flags &= ~islandFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(0, forKey: "eagle.auraStudio.activeIslandMode")
        defaults.set(0, forKey: "eagle.auraStudio.activeMode")
        defaults.removeObject(forKey: "eagle.islandGallery.activeLiveID")
        if flags == 0 {
            defaults.set(0, forKey: "eagle.auraStudio.activeSpringBoardPID")
        } else if let springBoardPID {
            defaults.set(Int(springBoardPID), forKey: "eagle.auraStudio.activeSpringBoardPID")
        }
    }

    private func haloName(for style: IslandGalleryStyle) -> String {
        switch style {
        case .starlight: return LaraL10n.text(en: "magenta", es: "magenta")
        case .inferno: return LaraL10n.text(en: "red", es: "rojo")
        case .horizon: return LaraL10n.text(en: "blue", es: "azul")
        case .vortex: return LaraL10n.text(en: "green", es: "verde")
        case .bubblegum: return LaraL10n.text(en: "pink", es: "rosa")
        case .traffic: return LaraL10n.text(en: "orange", es: "naranja")
        case .duckMood: return LaraL10n.text(en: "orange", es: "naranja")
        case .blueScreen: return LaraL10n.text(en: "blue", es: "azul")
        case .walkingFlame: return LaraL10n.text(en: "fire orange", es: "naranja fuego")
        case .singularityLive: return LaraL10n.text(en: "silver", es: "plateado")
        }
    }

    private func failure(en: String, es: String) -> IslandGalleryApplyResult {
        IslandGalleryApplyResult(
            succeeded: false,
            message: LaraL10n.text(en: en, es: es)
        )
    }

    nonisolated private static func readSpringBoardPID() -> Int32 {
        "SpringBoard".withCString { find_process_pid($0) }
    }

    private func log(_ stage: String, _ detail: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        globallogger.log(
            "[\(formatter.string(from: Date()))] (eagle.island.gallery) stage=\(stage) \(detail)"
        )
    }
}
