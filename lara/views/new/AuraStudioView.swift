import SwiftUI
import UIKit
import Darwin

private struct AuraStudioNotice: Identifiable {
    let id = UUID()
    let message: String
    let offersRespring: Bool

    init(message: String, offersRespring: Bool = false) {
        self.message = message
        self.offersRespring = offersRespring
    }
}

struct AuraStudioDisplayGeometry {
    let logicalSize: CGSize
    let nativePixelSize: CGSize
    let standardLogicalSize: CGSize
    let renderScale: CGFloat
    let nativeScale: CGFloat
    let xFactor: CGFloat
    let yFactor: CGFloat
    let isDisplayZoomed: Bool

    func scaleStandardFrame(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.origin.x * xFactor,
            y: frame.origin.y * yFactor,
            width: frame.width * xFactor,
            height: frame.height * yFactor
        )
    }

    var compactIslandFrame: CGRect {
        let model = devicemachine()
        let firstGenerationIsland = model == "iPhone15,2" || model == "iPhone15,3"
        let baseY: CGFloat = firstGenerationIsland ? 10 : (model == "iPhone17,3" ? 10 : 13)
        return CGRect(
            x: (logicalSize.width - 134) / 2,
            y: baseY,
            width: 134,
            height: 39
        )
    }

    var dockAuraFrame: CGRect {
        let firstGenerationIsland = devicemachine() == "iPhone15,2" ||
            devicemachine() == "iPhone15,3"
        let inset: CGFloat = firstGenerationIsland ? 18 : 15
        return scaleStandardFrame(CGRect(
            x: inset,
            y: firstGenerationIsland ? 3 : 1,
            width: standardLogicalSize.width - (inset * 2),
            height: firstGenerationIsland ? 90 : 94
        ))
    }

    static var current: AuraStudioDisplayGeometry {
        let screen = UIScreen.main
        let logical = CGSize(
            width: min(screen.bounds.width, screen.bounds.height),
            height: max(screen.bounds.width, screen.bounds.height)
        )
        let native = CGSize(
            width: min(screen.nativeBounds.width, screen.nativeBounds.height),
            height: max(screen.nativeBounds.width, screen.nativeBounds.height)
        )
        let renderScale = max(screen.scale, 1)
        let nativeScale = max(screen.nativeScale, 1)
        let standard = CGSize(
            width: native.width / renderScale,
            height: native.height / renderScale
        )
        let rawX = standard.width > 0 ? logical.width / standard.width : 1
        let rawY = standard.height > 0 ? logical.height / standard.height : 1
        var xFactor = (0.75...1.015).contains(rawX) ? rawX : 1
        var yFactor = (0.75...1.015).contains(rawY) ? rawY : 1
        if xFactor >= 0.985,
           yFactor >= 0.985,
           nativeScale > renderScale * 1.015 {
            let uniformFactor = renderScale / nativeScale
            if (0.75..<0.985).contains(uniformFactor) {
                xFactor = uniformFactor
                yFactor = uniformFactor
            }
        }
        return AuraStudioDisplayGeometry(
            logicalSize: logical,
            nativePixelSize: native,
            standardLogicalSize: standard,
            renderScale: renderScale,
            nativeScale: nativeScale,
            xFactor: xFactor,
            yFactor: yFactor,
            isDisplayZoomed: xFactor < 0.985 || yFactor < 0.985
        )
    }
}

private enum AuraStudioDiagnostics {
    static func log(_ stage: String, _ detail: String = "") {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let suffix = detail.isEmpty ? "" : " \(detail)"
        globallogger.log("[\(formatter.string(from: Date()))] (eagle.aura.apply) stage=\(stage)\(suffix)")
    }
}

@MainActor
private enum AuraStudioApplyGate {
    private static var operationInFlight = false
    private static var safetyLocked = false

    static func begin() -> Bool {
        guard !operationInFlight, !safetyLocked else { return false }
        operationInFlight = true
        return true
    }

    static func end() {
        operationInFlight = false
    }

    static func lock() {
        operationInFlight = false
        safetyLocked = true
    }
}

private enum AuraStudioMode: Int, CaseIterable, Identifiable {
    case glow = 1
    case pulse = 2
    case tint = 3
    case rainbow = 4
    case orbit = 5
    case chase = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .glow: return LaraL10n.text(en: "Glow", es: "Brillo")
        case .pulse: return LaraL10n.text(en: "Pulse", es: "Pulso")
        case .tint: return LaraL10n.text(en: "Tint", es: "Color")
        case .rainbow: return LaraL10n.text(en: "Rainbow", es: "Arcoíris")
        case .orbit: return LaraL10n.text(en: "Orbit", es: "Órbita")
        case .chase: return LaraL10n.text(en: "Chase", es: "Carrera")
        }
    }

    var summary: String {
        switch self {
        case .glow:
            return LaraL10n.text(
                en: "Keeps the system-black center and adds a thick, bright outer light.",
                es: "Mantiene el centro negro del sistema y añade una luz exterior gruesa e intensa."
            )
        case .pulse:
            return LaraL10n.text(
                en: "The current surface breathes gently without changing the other profile.",
                es: "La superficie actual respira suavemente sin cambiar el otro perfil."
            )
        case .tint:
            return LaraL10n.text(
                en: "Replaces the software-black center with color; only the physical camera cutouts stay black.",
                es: "Reemplaza el centro negro generado por software con color; solo los recortes físicos de la cámara permanecen negros."
            )
        case .rainbow:
            return LaraL10n.text(
                en: "A vivid spectrum moves through the background, bright edge, and outer light.",
                es: "Un espectro intenso recorre el fondo, el borde brillante y la luz exterior."
            )
        case .orbit:
            return LaraL10n.text(
                en: "A cyan, violet, pink and orange light travels smoothly around the Island edge.",
                es: "Una luz cian, violeta, rosa y naranja recorre suavemente el borde de la Island."
            )
        case .chase:
            return LaraL10n.text(
                en: "Cyan and orange neon segments chase each other around the compact Island.",
                es: "Segmentos de neón cian y naranja se persiguen alrededor de la Island compacta."
            )
        }
    }

    var usesFixedPalette: Bool {
        self == .rainbow || self == .orbit || self == .chase
    }

    var fillsIslandBackground: Bool {
        self == .tint || self == .rainbow
    }
}

private enum AuraStudioTarget: Int, CaseIterable, Identifiable {
    case island = 1
    case dock = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .island: return "Dynamic Island"
        case .dock: return "Dock"
        }
    }

}

private struct AuraStudioOperationStep {
    let flag: UInt32
    let englishName: String
    let spanishName: String

    var localizedName: String {
        LaraL10n.text(en: englishName, es: spanishName)
    }
}

private enum AuraStudioOperation {
    case apply(AuraStudioMode)
    case remove

    var nativeMode: Int {
        switch self {
        case .apply(let mode): return mode.rawValue
        case .remove: return 0
        }
    }

    var isRemoving: Bool {
        if case .remove = self { return true }
        return false
    }
}

/// Pure validation for the one-surface native boundary. Keep these rules in
/// Swift as well as Objective-C so a mismatched native result can never update
/// the wrong profile badge or be presented as a successful fallback.
private enum AuraStudioNativeContract {
    static func target(
        for flags: UInt32,
        islandFlag: UInt32,
        dockFlag: UInt32
    ) -> AuraStudioTarget? {
        switch flags {
        case islandFlag: return .island
        case dockFlag: return .dock
        default: return nil
        }
    }

    static func isScopedUnavailable(
        result: Int32,
        target: AuraStudioTarget,
        mode: AuraStudioMode,
        isRemoval: Bool
    ) -> Bool {
        guard !isRemoval else { return false }
        switch (result, target, mode) {
        case (-2, .island, _),
             (-17, .island, .tint),
             (-20, .dock, _):
            return true
        default:
            return false
        }
    }

    static func verifiedFallbackMode(
        result: Int32,
        target: AuraStudioTarget,
        requestedMode: AuraStudioMode
    ) -> AuraStudioMode? {
        switch (result, target, requestedMode) {
        case (-15, .island, .rainbow),
             (-16, .island, .tint):
            return .glow
        default:
            return nil
        }
    }

    static func isScopedVerifiedRollback(
        result: Int32,
        target: AuraStudioTarget,
        isRemoval: Bool
    ) -> Bool {
        !isRemoval && result == -12 && target == .island
    }

    static func hasExactAppliedSurface(
        result: Int32,
        requestedFlag: UInt32,
        supportedFlags: UInt32
    ) -> Bool {
        guard result >= 0 else { return false }
        return UInt32(bitPattern: result) & supportedFlags == requestedFlag
    }

#if DEBUG
    /// Lightweight pure contract checks for projects that currently have no
    /// XCTest target. They log rather than trap on a physical beta device.
    static var invariantsHold: Bool {
        let island: UInt32 = 1
        let dock: UInt32 = 1 << 5
        let supported = island | dock
        return target(for: island, islandFlag: island, dockFlag: dock) == .island &&
            target(for: dock, islandFlag: island, dockFlag: dock) == .dock &&
            target(for: supported, islandFlag: island, dockFlag: dock) == nil &&
            isScopedUnavailable(
                result: -20,
                target: .dock,
                mode: .glow,
                isRemoval: false
            ) &&
            !isScopedUnavailable(
                result: -20,
                target: .island,
                mode: .glow,
                isRemoval: false
            ) &&
            !isScopedUnavailable(
                result: -20,
                target: .dock,
                mode: .glow,
                isRemoval: true
            ) &&
            verifiedFallbackMode(
                result: -16,
                target: .island,
                requestedMode: .tint
            ) == .glow &&
            verifiedFallbackMode(
                result: -16,
                target: .dock,
                requestedMode: .glow
            ) == nil &&
            hasExactAppliedSurface(
                result: Int32(island),
                requestedFlag: island,
                supportedFlags: supported
            ) &&
            !hasExactAppliedSurface(
                result: Int32(supported),
                requestedFlag: island,
                supportedFlags: supported
            )
    }
#endif
}

struct AuraStudioView: View {
    private enum Flag {
        static let island: UInt32 = 1 << 0
        static let screen: UInt32 = 1 << 1
        static let battery: UInt32 = 1 << 2
        // Bits 3 and 4 remain reserved so existing installs keep the stable
        // Dock and Lock flag values after Volume/Notification Aura removal.
        static let dock: UInt32 = 1 << 5
        static let lock: UInt32 = 1 << 6
        static let motionDegraded: UInt32 = 1 << 30
        // Aura Studio now exposes only device-verified surfaces. The reserved
        // values stay intact so future rebuilt modules remain migration-safe.
        static let supported = island | dock
    }

    @ObservedObject private var mgr = laramgr.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // Island and Dock intentionally own separate draft profiles. Reusing the
    // original Island RGB keys preserves existing user choices while Dock
    // starts with its own independent color and style.
    @AppStorage("eagle.islandAura.red") private var islandRed = 0.10
    @AppStorage("eagle.islandAura.green") private var islandGreen = 0.78
    @AppStorage("eagle.islandAura.blue") private var islandBlue = 1.0
    @AppStorage("eagle.auraStudio.island.mode") private var islandModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.dockAura.red") private var dockRed = 0.62
    @AppStorage("eagle.dockAura.green") private var dockGreen = 0.25
    @AppStorage("eagle.dockAura.blue") private var dockBlue = 1.0
    @AppStorage("eagle.auraStudio.dock.mode") private var dockModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.auraStudio.editingTarget") private var selectedTargetRaw = AuraStudioTarget.island.rawValue
    @AppStorage("eagle.auraStudio.editingIcons") private var editingIcons = false
    @AppStorage("eagle.auraStudio.mode") private var legacySelectedModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.auraStudio.independentProfilesMigrated") private var independentProfilesMigrated = false
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0
    @AppStorage("eagle.auraStudio.activeMode") private var activeModeRaw = 0
    @AppStorage("eagle.auraStudio.activeIslandMode") private var activeIslandModeRaw = 0
    @AppStorage("eagle.auraStudio.activeDockMode") private var activeDockModeRaw = 0
    @AppStorage("eagle.auraStudio.activeSpringBoardPID") private var activeSpringBoardPID = 0
    @AppStorage("eagle.auraStudio.activeIslandRed") private var activeIslandRed = 26
    @AppStorage("eagle.auraStudio.activeIslandGreen") private var activeIslandGreen = 199
    @AppStorage("eagle.auraStudio.activeIslandBlue") private var activeIslandBlue = 255
    @AppStorage("eagle.auraStudio.activeDockRed") private var activeDockRed = 158
    @AppStorage("eagle.auraStudio.activeDockGreen") private var activeDockGreen = 64
    @AppStorage("eagle.auraStudio.activeDockBlue") private var activeDockBlue = 255
    @AppStorage(EagleReleaseChannel.storageKey) private var releaseChannelRaw =
        EagleReleaseChannel.stable.rawValue
    @State private var isApplying = false
    @State private var notice: AuraStudioNotice?
    @State private var applyStage = ""
    @State private var applySafetyBlocked = false
    @State private var activeOperationID: String?
    @State private var diagnosticsURL: URL?
    @State private var operationStepIndex = 0
    @State private var operationStepCount = 0
    @State private var operationIsRemoval = false
    @State private var systemIslandSuppressed = false
    @State private var isReadingSystemIslandSetting = false

    private let springBoardPreferencesPath =
        "/var/Managed Preferences/mobile/com.apple.springboard.plist"
    private let suppressSystemIslandKey = "SBSuppressDynamicIslandCompletely"

    private let auraEngineBuild = "2026.08.30-r37-spatial-island-styles"

    private var islandCompatibility: EagleDynamicIslandCompatibility {
        .current
    }

    private var islandProfileAvailable: Bool {
        islandCompatibility.availability == .supported
    }

    private var deviceSupportedFlags: UInt32 {
        islandProfileAvailable ? Flag.supported : Flag.dock
    }

    private var islandHardwareUnavailableMessage: String {
        if islandCompatibility.isSimulator {
            return LaraL10n.text(
                en: "Simulator can preview this model, but it cannot apply Island Aura to SpringBoard. Build for a supported physical iPhone. Dock remains unchanged.",
                es: "El simulador puede previsualizar este modelo, pero no puede aplicar el aura de Island a SpringBoard. Compila para un iPhone físico compatible. El Dock no cambió."
            )
        }
        switch islandCompatibility.availability {
        case .supported:
            return LaraL10n.text(
                en: "Dynamic Island hardware is recognized, but this device is not available for a live SpringBoard change. Nothing was changed.",
                es: "El hardware de Dynamic Island fue reconocido, pero este dispositivo no está disponible para cambiar SpringBoard en vivo. No se cambió nada."
            )
        case .unsupported:
            return LaraL10n.text(
                en: "This iPhone model does not have Dynamic Island. Island Aura was not sent to SpringBoard, and Dock remains available.",
                es: "Este modelo de iPhone no tiene Dynamic Island. El aura de Island no se envió a SpringBoard y el Dock sigue disponible."
            )
        case .unknown:
            return LaraL10n.text(
                en: "This iPhone model has not been verified for Dynamic Island. Eagle stopped before contacting SpringBoard; Dock remains available.",
                es: "Este modelo de iPhone no ha sido verificado para Dynamic Island. Eagle se detuvo antes de contactar SpringBoard; el Dock sigue disponible."
            )
        }
    }

    private var selectedTarget: AuraStudioTarget {
        get {
            let stored = AuraStudioTarget(rawValue: selectedTargetRaw) ?? .dock
            // A persisted Island selection from another device must never
            // hide or block Dock on hardware without a verified Island.
            return stored == .island && !islandProfileAvailable ? .dock : stored
        }
        nonmutating set { selectedTargetRaw = newValue.rawValue }
    }

    private var releaseChannel: EagleReleaseChannel {
        EagleFeaturePolicy.channel(from: releaseChannelRaw)
    }

    private func policyAllows(
        _ mode: AuraStudioMode,
        for target: AuraStudioTarget
    ) -> Bool {
        switch mode {
        case .glow:
            return true
        case .pulse:
            return EagleFeaturePolicy.allows(.auraPulse, channel: releaseChannel)
        case .rainbow, .orbit, .chase:
            // Animated palettes are Island-only. Dock keeps its independently
            // verified static renderer and cannot receive these modes.
            return target == .island &&
                EagleFeaturePolicy.allows(.auraRainbow, channel: releaseChannel)
        case .tint:
            // Keep the implementation available for future validation, but do
            // not expose or reselect Tint in the public Aura Studio build.
            return false
        }
    }

    private func normalizedMode(
        rawValue: Int,
        for target: AuraStudioTarget
    ) -> AuraStudioMode {
        let stored = AuraStudioMode(rawValue: rawValue) ?? .glow
        return policyAllows(stored, for: target) ? stored : .glow
    }

    private func normalizeDraftModesForPolicy() {
        let island = normalizedMode(rawValue: islandModeRaw, for: .island)
        let dock = normalizedMode(rawValue: dockModeRaw, for: .dock)
        if islandModeRaw != island.rawValue { islandModeRaw = island.rawValue }
        if dockModeRaw != dock.rawValue { dockModeRaw = dock.rawValue }
    }

    private var selectedMode: AuraStudioMode {
        get {
            let rawValue = selectedTarget == .island
                ? islandModeRaw
                : dockModeRaw
            return normalizedMode(rawValue: rawValue, for: selectedTarget)
        }
        nonmutating set {
            guard policyAllows(newValue, for: selectedTarget) else { return }
            if selectedTarget == .island {
                islandModeRaw = newValue.rawValue
            } else {
                dockModeRaw = newValue.rawValue
            }
        }
    }

    private var availableModes: [AuraStudioMode] {
        AuraStudioMode.allCases.filter { policyAllows($0, for: selectedTarget) }
    }

    private var auraColor: Color {
        color(for: selectedTarget)
    }

    private var displayGeometry: AuraStudioDisplayGeometry {
        .current
    }

    private var compactIslandPreviewSize: CGSize {
        let logicalWidth = max(displayGeometry.logicalSize.width, 1)
        let canvasWidth: CGFloat = 318
        let scaledWidth = displayGeometry.compactIslandFrame.width /
            logicalWidth * canvasWidth
        let aspect = displayGeometry.compactIslandFrame.height /
            max(displayGeometry.compactIslandFrame.width, 1)
        let width = max(96, min(122, scaledWidth))
        return CGSize(width: width, height: max(31, width * aspect))
    }

    private var selectedCapabilityTitle: String {
        if applySafetyBlocked || mgr.rcSafetyLocked {
            return LaraL10n.text(
                en: "Safety lock active",
                es: "Bloqueo de seguridad activo"
            )
        }
        if !mgr.dsready {
            return LaraL10n.text(
                en: "System access required",
                es: "Se requiere acceso al sistema"
            )
        }
        return LaraL10n.text(
            en: "\(selectedTarget.title) ready for live verification",
            es: "\(selectedTarget.title) listo para verificación en vivo"
        )
    }

    private var selectedCapabilityDescription: String {
        if applySafetyBlocked || mgr.rcSafetyLocked {
            return LaraL10n.text(
                en: "Share the report, then fully close and reopen Eagle. Apply and Restore remain blocked so no second private call can start.",
                es: "Comparte el informe y luego cierra y abre Eagle completamente. Aplicar y Restaurar permanecen bloqueados para que no se inicie una segunda llamada privada."
            )
        }
        if !mgr.dsready {
            return LaraL10n.text(
                en: "Prepare Eagle access below before using Apply or Restore. No Aura call will be sent until access is ready.",
                es: "Prepara el acceso de Eagle abajo antes de usar Aplicar o Restaurar. No se enviará ninguna llamada Aura hasta que el acceso esté listo."
            )
        }
        switch selectedTarget {
        case .island:
            if selectedMode == .tint {
                return LaraL10n.text(
                    en: "Experimental True Tint requires the native adaptive iOS 18 Island background. Eagle verifies it during Apply and preserves the current Island if that host is unavailable.",
                    es: "True Tint experimental requiere el fondo adaptativo nativo de Island en iOS 18. Eagle lo verifica al aplicar y conserva la Island actual si ese host no está disponible."
                )
            }
            return LaraL10n.text(
                en: "Hardware is recognized. Eagle checks the current compact or expanded SpringBoard host during Apply; Dock is never included in this call.",
                es: "El hardware fue reconocido. Eagle verifica el host compacto o expandido actual de SpringBoard al aplicar; el Dock nunca se incluye en esta llamada."
            )
        case .dock:
            return LaraL10n.text(
                en: "Use the Home Screen before Apply so SpringBoard can expose the live Dock. Dynamic Island is never included in this call.",
                es: "Pasa por la pantalla de Inicio antes de Aplicar para que SpringBoard exponga el Dock activo. Dynamic Island nunca se incluye en esta llamada."
            )
        }
    }

    private var previewLightColor: Color {
        previewLightColor(for: selectedTarget)
    }

    private var previewTintFillColor: Color {
        let red = sanitizedChannel(islandRed)
        let green = sanitizedChannel(islandGreen)
        let blue = sanitizedChannel(islandBlue)
        let brightest = max(red, max(green, blue))
        let scale = brightest > (112.0 / 255.0)
            ? (112.0 / 255.0) / brightest
            : 1.0
        return Color(
            red: red * scale,
            green: green * scale,
            blue: blue * scale
        )
    }

    private func previewRingStyle(for target: AuraStudioTarget) -> AnyShapeStyle {
        let mode = mode(for: target)
        if mode == .rainbow {
            return AnyShapeStyle(LinearGradient(
                colors: [.pink, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
        return AnyShapeStyle(color(for: target))
    }

    private func islandPreviewFillStyle(for mode: AuraStudioMode) -> AnyShapeStyle {
        switch mode {
        case .tint:
            return AnyShapeStyle(previewTintFillColor)
        case .rainbow:
            return AnyShapeStyle(LinearGradient(
                colors: [
                    Color.pink,
                    Color.orange,
                    Color.cyan,
                    Color.purple,
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        case .glow, .pulse, .orbit, .chase:
            return AnyShapeStyle(Color.black)
        }
    }

    private func previewSpectrumHue(for mode: AuraStudioMode) -> Double {
        switch mode {
        case .rainbow, .orbit:
            return auraSpectrumPhase(at: Date())
        case .chase:
            return 0.52
        case .glow, .pulse, .tint:
            return 0
        }
    }

    /// Wall-clock rainbow phase (0…1) for the live preview. Driven by a
    /// TimelineView instead of a repeating `withAnimation`, so the hue only
    /// moves while Rainbow is selected and can never leak onto Glow or Pulse.
    private func auraSpectrumPhase(at date: Date) -> Double {
        let cycles = date.timeIntervalSinceReferenceDate / 5.2
        return cycles - floor(cycles)
    }

    /// Smooth breathing level (0.58…1.0) for Pulse, from wall-clock time.
    private func auraPulseLevel(at date: Date) -> Double {
        let cycles = date.timeIntervalSinceReferenceDate / 2.3
        let phase = cycles - floor(cycles)
        let wave = 0.5 - (0.5 * cos(phase * 2 * Double.pi))
        return 0.58 + (0.42 * wave)
    }

    /// Full-spectrum ring that circles the loop seamlessly (red → red). Rotating
    /// its `angle` makes the neon travel around the island for Rainbow; other
    /// modes keep the steady solid surface colour.
    private func islandRingStyle(for mode: AuraStudioMode, angle: Double) -> AnyShapeStyle {
        switch mode {
        case .rainbow:
            return AnyShapeStyle(AngularGradient(
                colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                center: .center,
                angle: .degrees(angle)
            ))
        case .orbit:
            return AnyShapeStyle(AngularGradient(
                colors: [
                    Color(red: 0.11, green: 0.86, blue: 1.00),
                    Color(red: 0.15, green: 0.48, blue: 1.00),
                    Color(red: 0.47, green: 0.27, blue: 1.00),
                    Color(red: 1.00, green: 0.21, blue: 0.61),
                    Color(red: 1.00, green: 0.60, blue: 0.11),
                    Color(red: 0.11, green: 0.86, blue: 1.00),
                ],
                center: .center,
                angle: .degrees(angle)
            ))
        case .chase:
            return AnyShapeStyle(AngularGradient(
                colors: [
                    Color(red: 0.08, green: 0.88, blue: 1.00),
                    Color(red: 0.10, green: 0.56, blue: 1.00),
                    Color(red: 1.00, green: 0.59, blue: 0.14),
                    Color(red: 1.00, green: 0.30, blue: 0.28),
                    Color(red: 0.08, green: 0.88, blue: 1.00),
                ],
                center: .center,
                angle: .degrees(0)
            ))
        case .glow, .pulse, .tint:
            return AnyShapeStyle(color(for: .island))
        }
    }

    /// Interior fill: the same rotating spectrum for Rainbow so the aura turns
    /// as one piece; the existing black/tint fill for every other mode.
    private func islandFillStyle(for mode: AuraStudioMode, angle: Double) -> AnyShapeStyle {
        guard mode == .rainbow else {
            return islandPreviewFillStyle(for: mode)
        }
        return AnyShapeStyle(AngularGradient(
            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
            center: .center,
            angle: .degrees(angle)
        ))
    }

    private var selectedFlags: UInt32 {
        selectedTarget == .island ? Flag.island : Flag.dock
    }

    private var auraColorBinding: Binding<Color> {
        Binding(
            get: { auraColor },
            set: { color in
                if selectedMode.usesFixedPalette {
                    selectedMode = .glow
                }
                let resolved = UIColor(color)
                var nextRed: CGFloat = 0
                var nextGreen: CGFloat = 0
                var nextBlue: CGFloat = 0
                var alpha: CGFloat = 0
                guard resolved.getRed(
                    &nextRed,
                    green: &nextGreen,
                    blue: &nextBlue,
                    alpha: &alpha
                ) else { return }
                setSelectedRGB(
                    red: Double(nextRed),
                    green: Double(nextGreen),
                    blue: Double(nextBlue)
                )
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                systemIslandCard
                surfaceProfilesCard
                if editingIcons {
                    HomeIconNeonView(embedded: true)
                } else {
                    previewCard
                    appearanceCard
                }

                if !mgr.dsready {
                    LaraAccessView(compact: true)
                }

                if applySafetyBlocked || mgr.rcSafetyLocked {
                    diagnosticsCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Aura Studio")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isApplying)
        .alert(item: $notice) { notice in
            if notice.offersRespring {
                return Alert(
                    title: Text("Aura Studio"),
                    message: Text(notice.message),
                    primaryButton: .default(Text(LaraL10n.text(
                        en: "Respring now",
                        es: "Respring ahora"
                    ))) {
                        mgr.respring()
                    },
                    secondaryButton: .cancel(Text(LaraL10n.text(
                        en: "Later",
                        es: "Después"
                    )))
                )
            }
            return Alert(
                title: Text("Aura Studio"),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if isApplying {
                ZStack {
                    Color.black.opacity(0.14).ignoresSafeArea()
                VStack(spacing: 12) {
                    EagleRainbowSpinner(size: 28)
                        Text(applyStage.isEmpty
                             ? LaraL10n.text(
                                en: "Preparing a safe system update…",
                                es: "Preparando una actualización segura…"
                             )
                             : applyStage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    if operationStepCount > 0 {
                        Text(LaraL10n.text(
                            en: "Step \(min(operationStepIndex, operationStepCount)) of \(operationStepCount)",
                            es: "Paso \(min(operationStepIndex, operationStepCount)) de \(operationStepCount)"
                        ))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                }
                    .padding(22)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .onAppear {
            if !independentProfilesMigrated {
                let legacyMode = AuraStudioMode(rawValue: legacySelectedModeRaw) ?? .glow
                islandModeRaw = legacyMode.rawValue
                dockModeRaw = (legacyMode == .tint ? AuraStudioMode.glow : legacyMode).rawValue
                independentProfilesMigrated = true
            }
            normalizeDraftModesForPolicy()
            if !islandProfileAvailable,
               selectedTargetRaw == AuraStudioTarget.island.rawValue {
                selectedTargetRaw = AuraStudioTarget.dock.rawValue
            }
            reconcilePersistedActiveState()
            if mgr.sbxready {
                readSystemIslandSetting()
            }
            if mgr.rcSafetyLocked { applySafetyBlocked = true }
#if DEBUG
            if !AuraStudioNativeContract.invariantsHold {
                AuraStudioDiagnostics.log(
                    "contract.self-test",
                    "result=failed engine=\(auraEngineBuild)"
                )
            }
#endif
        }
        .onChange(of: releaseChannelRaw) { _ in
            guard !isApplying else { return }
            normalizeDraftModesForPolicy()
        }
        .onChange(of: mgr.sbxready) { ready in
            if ready {
                readSystemIslandSetting()
            } else {
                systemIslandSuppressed = false
            }
        }
    }

    private var systemIslandCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(LaraL10n.text(
                    en: "Hide system Island",
                    es: "Ocultar Island del sistema"
                ))
                .font(.subheadline.weight(.semibold))
                Text(mgr.sbxready
                     ? LaraL10n.text(en: "Requires respring", es: "Requiere respring")
                     : LaraL10n.text(en: "Prepare access first", es: "Prepara el acceso primero"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Toggle("", isOn: Binding(
                get: { systemIslandSuppressed },
                set: updateSystemIslandSuppression
            ))
            .labelsHidden()
            .disabled(!mgr.sbxready || isReadingSystemIslandSetting || isApplying)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func readSystemIslandSetting() {
        guard mgr.sbxready else {
            systemIslandSuppressed = false
            return
        }
        // Lara treats an absent SpringBoard preferences domain as the
        // setting's normal default (`false`). Some devices have never created
        // this plist, so opening Aura Studio must not show an error alert.
        guard FileManager.default.fileExists(
            atPath: springBoardPreferencesPath
        ) else {
            systemIslandSuppressed = false
            return
        }
        isReadingSystemIslandSetting = true
        defer { isReadingSystemIslandSetting = false }
        let result = mgr.getplistvalue(
            path: springBoardPreferencesPath,
            key: suppressSystemIslandKey
        )
        guard result.ok else {
            systemIslandSuppressed = false
            if !result.message.hasPrefix("key ") {
                notice = AuraStudioNotice(message: result.message)
            }
            return
        }
        guard let value = plistBoolean(result.value) else {
            systemIslandSuppressed = false
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Could not read \(suppressSystemIslandKey) as a Boolean value.",
                es: "No se pudo leer \(suppressSystemIslandKey) como un valor booleano."
            ))
            return
        }
        systemIslandSuppressed = value
    }

    private func updateSystemIslandSuppression(_ enabled: Bool) {
        guard mgr.sbxready else {
            systemIslandSuppressed = false
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Prepare Eagle access before changing the system Island setting.",
                es: "Prepara el acceso de Eagle antes de cambiar el ajuste de la Island del sistema."
            ))
            return
        }
        if !enabled,
           !FileManager.default.fileExists(atPath: springBoardPreferencesPath) {
            // Missing domain already means the original system behavior. Do
            // not create an empty protected plist merely to switch it off.
            systemIslandSuppressed = false
            return
        }
        let previousValue = systemIslandSuppressed
        systemIslandSuppressed = enabled
        let result = mgr.setplistvalue(
            path: springBoardPreferencesPath,
            key: (suppressSystemIslandKey, enabled ? true : nil),
            force: true
        )
        guard result.ok else {
            systemIslandSuppressed = previousValue
            notice = AuraStudioNotice(message: result.message)
            return
        }

        let verification = mgr.getplistvalue(
            path: springBoardPreferencesPath,
            key: suppressSystemIslandKey
        )
        let verified: Bool
        if verification.ok, let storedValue = plistBoolean(verification.value) {
            verified = storedValue == enabled
        } else {
            verified = !enabled &&
                (!FileManager.default.fileExists(atPath: springBoardPreferencesPath) ||
                 (verification.value == nil && verification.message.hasPrefix("key ")))
        }
        guard verified else {
            systemIslandSuppressed = previousValue
            notice = AuraStudioNotice(message: verification.ok
                ? LaraL10n.text(
                    en: "The system value did not match the requested setting.",
                    es: "El valor del sistema no coincidió con el ajuste solicitado."
                )
                : verification.message)
            return
        }

        notice = AuraStudioNotice(message: LaraL10n.text(
            en: enabled
                ? "The system Island will be hidden after a respring. To complete the change, manually restart your iPhone once more after the respring. Your Aura profile is unchanged."
                : "The system Island will return after a respring. To complete the change, manually restart your iPhone once more after the respring. Your Aura profile is unchanged.",
            es: enabled
                ? "La Island del sistema se ocultará después de un respring. Para completar el cambio, reinicia manualmente tu iPhone una vez más después del respring. Tu perfil Aura no cambió."
                : "La Island del sistema volverá después de un respring. Para completar el cambio, reinicia manualmente tu iPhone una vez más después del respring. Tu perfil Aura no cambió."
        ), offersRespring: true)
    }

    private func plistBoolean(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return nil
    }

    private var previewCard: some View {
        VStack(spacing: 11) {
            HStack(spacing: 8) {
                Image(systemName: selectedTarget == .island ? "capsule.fill" : "dock.rectangle")
                    .foregroundStyle(.primary)
                Text(selectedTarget.title)
                    .font(.headline)
                Spacer()
                Text(selectedMode.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.07), in: Capsule())
            }

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.035, green: 0.04, blue: 0.065),
                            Color(red: 0.012, green: 0.014, blue: 0.025),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(RadialGradient(
                        colors: [
                            previewLightColor.opacity(0.30),
                            previewLightColor.opacity(0.08),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 165
                    ))
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                TimelineView(.animation(
                    minimumInterval: 1.0 / 30.0,
                    paused: reduceMotion ||
                        ![.pulse, .rainbow, .orbit, .chase].contains(selectedMode)
                )) { context in
                    let now = context.date
                    if selectedTarget == .island {
                        let islandMode = mode(for: .island)
                        // Rainbow and Orbit rotate their spectrum; Chase moves
                        // rounded neon segments around the same capsule path.
                        let angle = islandMode == .rainbow || islandMode == .orbit
                            ? auraSpectrumPhase(at: now) * 360
                            : 0
                        let dashPhase: CGFloat = islandMode == .chase
                            ? CGFloat(-auraSpectrumPhase(at: now) * 36)
                            : 0
                        let level = islandMode == .pulse ? auraPulseLevel(at: now) : 1
                        let ring = islandRingStyle(for: islandMode, angle: angle)
                        let fill = islandFillStyle(for: islandMode, angle: angle)
                        let spatialStyle = StrokeStyle(
                            lineWidth: islandMode == .chase ? 5.2 : 5.8,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: islandMode == .chase ? [11, 7] : [],
                            dashPhase: dashPhase
                        )

                        ZStack {
                            Capsule()
                                .stroke(
                                    ring,
                                    style: islandMode == .orbit || islandMode == .chase
                                        ? StrokeStyle(
                                            lineWidth: 12,
                                            lineCap: .round,
                                            lineJoin: .round,
                                            dash: islandMode == .chase ? [11, 7] : [],
                                            dashPhase: dashPhase
                                        )
                                        : StrokeStyle(lineWidth: 12)
                                )
                                .blur(radius: 10)
                                .opacity(0.48)
                            Capsule()
                                .fill(fill)
                            Capsule()
                                .stroke(
                                    ring,
                                    style: islandMode == .orbit || islandMode == .chase
                                        ? spatialStyle
                                        : StrokeStyle(lineWidth: 4)
                                )
                            if islandMode.fillsIslandBackground {
                                HStack(spacing: 6) {
                                    Capsule()
                                        .fill(.black)
                                        .frame(width: 58, height: 17)
                                    Circle()
                                        .fill(.black)
                                        .frame(width: 17, height: 17)
                                }
                                .offset(x: 4)
                            }
                        }
                        .frame(width: 190, height: 55)
                        .shadow(
                            color: islandMode == .rainbow ? .clear : previewLightColor,
                            radius: 14
                        )
                        .opacity(level)
                    } else {
                        let dockMode = mode(for: .dock)
                        let hue = dockMode == .rainbow ? auraSpectrumPhase(at: now) : 0
                        let level = dockMode == .pulse ? auraPulseLevel(at: now) : 1

                        ZStack {
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .fill(Color.white.opacity(0.075))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                                        .fill(previewLightColor.opacity(0.09))
                                }
                            HStack(spacing: 13) {
                                ForEach(0..<4, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.82 - Double(index) * 0.08))
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }
                        .frame(width: 286, height: 78)
                        .overlay {
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .stroke(previewRingStyle(for: .dock), lineWidth: 3)
                        }
                        .shadow(color: previewLightColor.opacity(0.85), radius: 13)
                        .hueRotation(.degrees(hue * 360))
                        .opacity(level)
                    }
                }
            }
            .frame(height: 145)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
            .padding(8)
            .background(
                colorScheme == .dark
                    ? Color.black.opacity(0.28)
                    : Color(uiColor: .tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(EagleVisualTheme.surfaceBorder(for: colorScheme), lineWidth: 1)
            }
            .shadow(color: EagleVisualTheme.surfaceShadow(for: colorScheme), radius: 12, y: 5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LaraL10n.text(
                en: "\(selectedTarget.title) preview, \(selectedMode.title)",
                es: "Vista previa de \(selectedTarget.title), \(selectedMode.title)"
            ))
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if availableModes.count > 1 {
                Picker(
                    LaraL10n.text(en: "Light Style", es: "Estilo de luz"),
                    selection: Binding(get: { selectedMode }, set: { selectedMode = $0 })
                ) {
                    ForEach(availableModes) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                Label(AuraStudioMode.glow.title, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(previewLightColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .frame(height: 40)
                    .background(
                        previewLightColor.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                    )
            }

            Divider()

            HStack {
                Text(LaraL10n.text(en: "Color", es: "Color"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                ColorPicker(
                    LaraL10n.text(en: "Custom color", es: "Color personalizado"),
                    selection: auraColorBinding,
                    supportsOpacity: false
                )
                .labelsHidden()
            }

            HStack(spacing: 9) {
                ForEach(presets, id: \.name) { preset in
                    Button {
                        if selectedMode.usesFixedPalette {
                            selectedMode = .glow
                        }
                        setSelectedRGB(
                            red: preset.red,
                            green: preset.green,
                            blue: preset.blue
                        )
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(red: preset.red, green: preset.green, blue: preset.blue))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1)
                                    if presetIsSelected(preset) && !selectedMode.usesFixedPalette {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.75), radius: 2)
                                    }
                                }
                                .shadow(
                                    color: Color(red: preset.red, green: preset.green, blue: preset.blue).opacity(0.6),
                                    radius: 6
                                )
                        }
                        .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.name)
                    .accessibilityValue(
                        presetIsSelected(preset) && !selectedMode.usesFixedPalette
                            ? LaraL10n.text(en: "Selected", es: "Seleccionado")
                            : ""
                    )
                }

                if policyAllows(.rainbow, for: selectedTarget) {
                    Button {
                        selectedMode = .rainbow
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    AngularGradient(
                                        colors: [
                                            .red, .orange, .yellow, .green, .cyan,
                                            .blue, .purple, .pink, .red,
                                        ],
                                        center: .center
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Circle().strokeBorder(.white.opacity(0.72), lineWidth: 1.2)
                                    if selectedMode == .rainbow {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.75), radius: 2)
                                    }
                                }
                                .shadow(color: previewLightColor.opacity(0.9), radius: 8)
                        }
                        .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        LaraL10n.text(en: "Animated rainbow", es: "Arcoíris animado")
                    )
                    .accessibilityValue(
                        selectedMode == .rainbow
                            ? LaraL10n.text(en: "Selected", es: "Seleccionado")
                            : ""
                    )
                }

                Spacer()
            }

            applyButton
            restoreButton
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
        .disabled(isApplying)
    }

    private var surfaceProfilesCard: some View {
        HStack(spacing: 8) {
            ForEach(AuraStudioTarget.allCases) { target in
                profileButton(for: target)
            }
            homeIconCompactLink
        }
    }

    private func profileButton(for target: AuraStudioTarget) -> some View {
        let isSelected = !editingIcons && selectedTarget == target
        let isHardwareAvailable = target != .island || islandProfileAvailable

        return Button {
            editingIcons = false
            selectedTarget = target
        } label: {
            HStack(spacing: 7) {
                Image(systemName: target == .island ? "capsule.fill" : "dock.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text(target == .island ? "Island" : target.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Color.primary.opacity(0.08) : Color(uiColor: .tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary.opacity(0.35) : .clear, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isApplying || !isHardwareAvailable)
        .opacity(isHardwareAvailable ? 1 : 0.64)
        .accessibilityLabel(target.title)
        .accessibilityValue(mode(for: target).title)
        .accessibilityHint(LaraL10n.text(
            en: isHardwareAvailable
                ? "Edits only this surface."
                : "This model has no verified Dynamic Island. Dock remains available.",
            es: isHardwareAvailable
                ? "Edita únicamente esta superficie."
                : "Este modelo no tiene una Dynamic Island verificada. El Dock sigue disponible."
        ))
    }

    private var homeIconCompactLink: some View {
        Button {
            editingIcons = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "app.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(LaraL10n.text(en: "Icons", es: "Iconos"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(
                editingIcons
                    ? Color.primary.opacity(0.08)
                    : Color(uiColor: .tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(editingIcons ? Color.primary.opacity(0.35) : .clear, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
        .accessibilityLabel(LaraL10n.text(en: "Home Icon Neon", es: "Neón de iconos"))
    }

    private var adaptiveNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: applySafetyBlocked || mgr.rcSafetyLocked
                  ? "exclamationmark.shield.fill"
                  : (mgr.dsready ? "checkmark.shield.fill" : "lock.shield.fill"))
                .foregroundStyle(
                    applySafetyBlocked || mgr.rcSafetyLocked
                        ? Color.orange
                        : previewLightColor
                )
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCapabilityTitle)
                    .font(.subheadline.weight(.semibold))
                Text(selectedCapabilityDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(
                    "Aura Engine \(auraEngineBuild) · \(releaseChannel.title) · " +
                    (displayGeometry.isDisplayZoomed ? "Display Zoom" : "Standard")
                )
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var isApplyButtonDisabled: Bool {
        isApplying || !mgr.dsready || selectedFlags == 0 ||
            applySafetyBlocked || mgr.rcSafetyLocked
    }

    private var applyButtonForeground: Color {
        isApplyButtonDisabled
            ? (colorScheme == .dark ? Color.white.opacity(0.86) : Color.black.opacity(0.78))
            : .white
    }

    private var applyButtonBackground: Color {
        if !mgr.dsready {
            return Color.red.opacity(colorScheme == .dark ? 0.24 : 0.13)
        }
        if isApplyButtonDisabled {
            return Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.09)
        }
        return EagleVisualTheme.accent
    }

    private var applyButton: some View {
        Button {
            runAuraOperation(.apply(selectedMode), flags: selectedFlags)
        } label: {
            Label(
                mgr.dsready
                    ? LaraL10n.text(
                        en: "Apply \(selectedMode.title)",
                        es: "Aplicar \(selectedMode.title)"
                    )
                    : LaraL10n.text(
                        en: "System Access Required",
                        es: "Se requiere acceso al sistema"
                    ),
                systemImage: mgr.dsready ? "sparkles" : "lock.shield.fill"
            )
            .font(.headline)
            .foregroundStyle(applyButtonForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                applyButtonBackground,
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(
                        !mgr.dsready
                            ? Color.red.opacity(colorScheme == .dark ? 0.42 : 0.30)
                            : EagleVisualTheme.surfaceBorder(for: colorScheme),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isApplyButtonDisabled)
        .accessibilityHint(LaraL10n.text(
            en: "Changes only \(selectedTarget.title).",
            es: "Cambia únicamente \(selectedTarget.title)."
        ))
    }

    private var restoreButton: some View {
        Button {
            runAuraOperation(.remove, flags: selectedFlags)
        } label: {
            Label(
                LaraL10n.text(en: "Restore", es: "Restaurar"),
                systemImage: "arrow.counterclockwise"
            )
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(.bordered)
        .disabled(
            isApplying || !mgr.dsready || selectedFlags == 0 ||
            applySafetyBlocked || mgr.rcSafetyLocked
        )
        .opacity(!mgr.dsready || applySafetyBlocked || mgr.rcSafetyLocked ? 0.52 : 1)
        .accessibilityHint(LaraL10n.text(
            en: "Restores only \(selectedTarget.title) and keeps the other aura active.",
            es: "Restaura únicamente \(selectedTarget.title) y mantiene activa la otra aura."
        ))
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if applySafetyBlocked || mgr.rcSafetyLocked {
                Label(
                    LaraL10n.text(
                        en: "Safety lock active for this Eagle run",
                        es: "Bloqueo de seguridad activo durante esta ejecución de Eagle"
                    ),
                    systemImage: "exclamationmark.shield.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

                Text(LaraL10n.text(
                    en: "Aura Studio will not retry after an unverified call, timeout, SpringBoard restart, or main-thread error. Export the report, then fully close and reopen Eagle before another test.",
                    es: "Aura Studio no volverá a intentarlo después de una llamada no verificada, un tiempo agotado, un reinicio de SpringBoard o un error del hilo principal. Exporta el informe y luego cierra y abre Eagle completamente antes de otra prueba."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    diagnosticsURL = makeDiagnosticsReport(
                        summary: mgr.rcSafetyReason ?? "Manual Aura Studio export"
                    )
                } label: {
                    Label(
                        LaraL10n.text(en: "Build Report", es: "Crear informe"),
                        systemImage: "doc.text.magnifyingglass"
                    )
                }
                .buttonStyle(.bordered)

                if let diagnosticsURL {
                    ShareLink(item: diagnosticsURL) {
                        Label(
                            LaraL10n.text(en: "Share", es: "Compartir"),
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var presets: [(name: String, red: Double, green: Double, blue: Double)] {
        [
            (LaraL10n.text(en: "Electric Blue", es: "Azul eléctrico"), 0.10, 0.78, 1.00),
            (LaraL10n.text(en: "Ultra Violet", es: "Ultravioleta"), 0.62, 0.25, 1.00),
            (LaraL10n.text(en: "Hot Pink", es: "Rosa intenso"), 1.00, 0.16, 0.62),
            (LaraL10n.text(en: "Acid Green", es: "Verde ácido"), 0.42, 1.00, 0.24),
        ]
    }

    private func presetIsSelected(
        _ preset: (name: String, red: Double, green: Double, blue: Double)
    ) -> Bool {
        let selectedRGB = selectedTarget == .island
            ? (sanitizedChannel(islandRed), sanitizedChannel(islandGreen), sanitizedChannel(islandBlue))
            : (sanitizedChannel(dockRed), sanitizedChannel(dockGreen), sanitizedChannel(dockBlue))
        let tolerance = 0.002
        return abs(selectedRGB.0 - preset.red) < tolerance &&
            abs(selectedRGB.1 - preset.green) < tolerance &&
            abs(selectedRGB.2 - preset.blue) < tolerance
    }

    private func mode(for target: AuraStudioTarget) -> AuraStudioMode {
        let rawValue = target == .island ? islandModeRaw : dockModeRaw
        return normalizedMode(rawValue: rawValue, for: target)
    }

    private func color(for target: AuraStudioTarget) -> Color {
        switch target {
        case .island:
            return Color(
                red: sanitizedChannel(islandRed),
                green: sanitizedChannel(islandGreen),
                blue: sanitizedChannel(islandBlue)
            )
        case .dock:
            return Color(
                red: sanitizedChannel(dockRed),
                green: sanitizedChannel(dockGreen),
                blue: sanitizedChannel(dockBlue)
            )
        }
    }

    private func previewLightColor(for target: AuraStudioTarget) -> Color {
        let mode = mode(for: target)
        return mode.usesFixedPalette
            ? Color(
                hue: previewSpectrumHue(for: mode),
                saturation: 0.96,
                brightness: 1.0
            )
            : color(for: target)
    }

    private func setSelectedRGB(red: Double, green: Double, blue: Double) {
        let nextRed = sanitizedChannel(red)
        let nextGreen = sanitizedChannel(green)
        let nextBlue = sanitizedChannel(blue)
        if selectedTarget == .island {
            islandRed = nextRed
            islandGreen = nextGreen
            islandBlue = nextBlue
        } else {
            dockRed = nextRed
            dockGreen = nextGreen
            dockBlue = nextBlue
        }
    }

    private func activeColor(for flag: UInt32) -> Color {
        let rgb = flag == Flag.island
            ? (activeIslandRed, activeIslandGreen, activeIslandBlue)
            : (activeDockRed, activeDockGreen, activeDockBlue)
        return Color(
            red: Double(rgb.0) / 255.0,
            green: Double(rgb.1) / 255.0,
            blue: Double(rgb.2) / 255.0
        )
    }

    private func flag(for target: AuraStudioTarget) -> UInt32 {
        target == .island ? Flag.island : Flag.dock
    }

    private func isTargetActive(_ target: AuraStudioTarget) -> Bool {
        UInt32(max(activeFlagsRaw, 0)) & flag(for: target) != 0
    }

    private func activeMode(for target: AuraStudioTarget) -> AuraStudioMode? {
        let rawValue = target == .island ? activeIslandModeRaw : activeDockModeRaw
        return AuraStudioMode(rawValue: rawValue)
    }

    private func draftMatchesActive(_ target: AuraStudioTarget) -> Bool {
        guard isTargetActive(target), activeMode(for: target) == mode(for: target) else {
            return false
        }
        // Rainbow has no single active RGB value; its verified mode is enough
        // to distinguish the applied state from the editable draft.
        if mode(for: target).usesFixedPalette { return true }

        let draftRGB: (Int, Int, Int)
        let activeRGB: (Int, Int, Int)
        if target == .island {
            draftRGB = (
                Int((islandRed * 255).rounded()),
                Int((islandGreen * 255).rounded()),
                Int((islandBlue * 255).rounded())
            )
            activeRGB = (activeIslandRed, activeIslandGreen, activeIslandBlue)
        } else {
            draftRGB = (
                Int((dockRed * 255).rounded()),
                Int((dockGreen * 255).rounded()),
                Int((dockBlue * 255).rounded())
            )
            activeRGB = (activeDockRed, activeDockGreen, activeDockBlue)
        }
        return draftRGB == activeRGB
    }

    private func profileStatusText(for target: AuraStudioTarget) -> String {
        if target == .island && !islandProfileAvailable {
            return islandCompatibility.availability == .unknown
                ? LaraL10n.text(
                    en: "Unknown model · Island disabled safely",
                    es: "Modelo desconocido · Island desactivada de forma segura"
                )
                : LaraL10n.text(
                    en: "This iPhone has no Dynamic Island",
                    es: "Este iPhone no tiene Dynamic Island"
                )
        }
        guard let appliedMode = activeMode(for: target), isTargetActive(target) else {
            return LaraL10n.text(en: "Not active", es: "No activo")
        }
        if draftMatchesActive(target) {
            return LaraL10n.text(
                en: "Applied · \(appliedMode.title)",
                es: "Aplicado · \(appliedMode.title)"
            )
        }
        return LaraL10n.text(
            en: "Active: \(appliedMode.title) · selected changes not applied",
            es: "Activo: \(appliedMode.title) · cambios seleccionados sin aplicar"
        )
    }

    private func rgb255String(_ red: Double, _ green: Double, _ blue: Double) -> String {
        [red, green, blue]
            .map { String(channel255($0)) }
            .joined(separator: ",")
    }

    /// UserDefaults can contain stale or externally-written floating-point
    /// values. Never pass NaN/∞ (or an out-of-range channel) into Color or the
    /// native C bridge: converting NaN to Int would trap the Eagle process.
    private func sanitizedChannel(_ value: Double, fallback: Double = 0) -> Double {
        guard value.isFinite else { return fallback }
        return max(0, min(1, value))
    }

    private func channel255(_ value: Double) -> Int {
        Int((sanitizedChannel(value) * 255).rounded())
    }

    private var activeModuleCount: Int {
        (UInt32(max(activeFlagsRaw, 0)) & deviceSupportedFlags).nonzeroBitCount
    }

    private var verifiedSurfaceSummary: String {
        if activeModuleCount == 1 {
            return LaraL10n.text(
                en: "1 verified aura active in this SpringBoard session",
                es: "1 aura verificada activa en esta sesión de SpringBoard"
            )
        }
        return LaraL10n.text(
            en: "\(activeModuleCount) verified auras active in this SpringBoard session",
            es: "\(activeModuleCount) auras verificadas activas en esta sesión de SpringBoard"
        )
    }

    private func reconcilePersistedActiveState(currentPID providedPID: Int32? = nil) {
        let currentPID = providedPID ?? "SpringBoard".withCString {
            find_process_pid($0)
        }
        let rawSavedFlags = UInt32(max(activeFlagsRaw, 0)) & Flag.supported
        let savedFlags = rawSavedFlags & deviceSupportedFlags
        if rawSavedFlags != savedFlags {
            AuraStudioDiagnostics.log(
                "state.hardware-pruned",
                "before=0x\(String(rawSavedFlags, radix: 16)) " +
                "after=0x\(String(savedFlags, radix: 16)) " +
                "\(islandCompatibility.diagnosticsToken)"
            )
            activeFlagsRaw = Int(savedFlags)
            activeIslandModeRaw = 0
        }
        guard savedFlags != 0 else {
            activeFlagsRaw = 0
            activeModeRaw = 0
            activeIslandModeRaw = 0
            activeDockModeRaw = 0
            activeSpringBoardPID = 0
            return
        }

        // Auras live inside SpringBoard. A badge saved by an older build, or
        // by a SpringBoard PID that no longer exists, cannot be called active.
        guard activeSpringBoardPID > 0,
              currentPID == Int32(activeSpringBoardPID) else {
            AuraStudioDiagnostics.log(
                "state.expired",
                "savedPID=\(activeSpringBoardPID) currentPID=\(currentPID) " +
                "flags=0x\(String(savedFlags, radix: 16))"
            )
            activeFlagsRaw = 0
            activeModeRaw = 0
            activeIslandModeRaw = 0
            activeDockModeRaw = 0
            activeSpringBoardPID = 0
            return
        }

        // Mode/color metadata never outlives its surface flag. This matters
        // when one profile is restored while the other remains active.
        if savedFlags & Flag.island == 0 {
            activeModeRaw = 0
            activeIslandModeRaw = 0
        }
        if savedFlags & Flag.dock == 0 {
            activeDockModeRaw = 0
        }

        // One-time migration from the original shared style field.
        if savedFlags & Flag.island != 0, activeIslandModeRaw == 0 {
            activeIslandModeRaw = activeModeRaw
        }
        if savedFlags & Flag.dock != 0, activeDockModeRaw == 0 {
            activeDockModeRaw = activeModeRaw
        }
    }

    private func runAuraOperation(
        _ operation: AuraStudioOperation,
        flags: UInt32
    ) {
        // The visual objects live inside one SpringBoard process. Reconcile
        // again at the moment of the request (not only onAppear) so a respring
        // while this screen remains open cannot carry stale badges or modes
        // into a fresh process.
        let operationSpringBoardPID = "SpringBoard".withCString {
            find_process_pid($0)
        }
        reconcilePersistedActiveState(currentPID: operationSpringBoardPID)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let operationID = String(UUID().uuidString.prefix(8))
        let mode = operation.nativeMode
        let requestedProfileMode: AuraStudioMode
        switch operation {
        case .apply(let profileMode):
            requestedProfileMode = profileMode
        case .remove:
            requestedProfileMode = .glow
        }
        let requestedFlags = flags & Flag.supported
        let requestedTarget = AuraStudioNativeContract.target(
            for: requestedFlags,
            islandFlag: Flag.island,
            dockFlag: Flag.dock
        )
        let requestedTargetTitle = requestedTarget?.title ?? "Invalid selection"
        let display = displayGeometry
        let islandFrame = display.compactIslandFrame
        let dockFrame = display.dockAuraFrame
        AuraStudioDiagnostics.log(
            "request",
            "op=\(operationID) engine=\(auraEngineBuild) " +
            "action=\(operation.isRemoving ? "remove" : "apply") mode=\(mode) " +
            "target=\(requestedTargetTitle) flags=0x\(String(requestedFlags, radix: 16)) " +
            "device=\(devicemachine()) " +
            "islandHardware={\(islandCompatibility.diagnosticsToken)} " +
            "ios=\(version.majorVersion).\(version.minorVersion).\(version.patchVersion) " +
            "display=\(display.isDisplayZoomed ? "zoomed" : "standard") " +
            "factor=\(String(format: "%.4f", display.xFactor))," +
            "\(String(format: "%.4f", display.yFactor)) " +
            "island=\(String(format: "%.2f,%.2f,%.2f,%.2f", islandFrame.minX, islandFrame.minY, islandFrame.width, islandFrame.height)) " +
            "dock=\(String(format: "%.2f,%.2f,%.2f,%.2f", dockFrame.minX, dockFrame.minY, dockFrame.width, dockFrame.height))"
        )

        // The camera aperture is fixed hardware, while Display Zoom changes
        // SpringBoard's private window coordinate space between device
        // families and iOS builds. Do not send an Island mutation from that
        // ambiguous geometry. Removal remains available, and Dock is
        // independent of the physical aperture.
        if !operation.isRemoving,
           requestedTarget == .island,
           display.isDisplayZoomed {
            AuraStudioDiagnostics.log(
                "display-zoom.reject",
                "op=\(operationID) target=Island noMutation=1"
            )
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Dynamic Island requires Standard display size. Open Settings → Display & Brightness → Display Zoom, select Standard, then return to Eagle. Nothing was changed.",
                es: "Dynamic Island requiere el tamaño de pantalla Estándar. Abre Ajustes → Pantalla y brillo → Zoom de pantalla, selecciona Estándar y vuelve a Eagle. No se cambió nada."
            ))
            return
        }

        guard !applySafetyBlocked, !mgr.rcSafetyLocked else {
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Aura Studio is safety locked after the previous unverified attempt. Export the report, fully close Eagle, and reopen it before testing again.",
                es: "Aura Studio está bloqueado por seguridad después del intento anterior no verificado. Exporta el informe, cierra Eagle completamente y vuelve a abrirlo antes de probar otra vez."
            ))
            return
        }
        guard !isApplying, AuraStudioApplyGate.begin() else {
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Aura Studio is still finishing the previous system update.",
                es: "Aura Studio todavía está terminando la actualización anterior."
            ))
            return
        }
        if requestedTarget == .island,
           !islandCompatibility.canAttemptLiveIslandAura {
            finish(message: islandHardwareUnavailableMessage)
            return
        }
        guard !isdebugged() else {
            finish(message: LaraL10n.text(
                en: "Stop the Xcode run and open Eagle manually from the Home Screen before changing SpringBoard.",
                es: "Detén la ejecución en Xcode y abre Eagle manualmente desde Inicio antes de modificar SpringBoard."
            ))
            return
        }
        guard version.majorVersion == 17 || version.majorVersion == 18 else {
            finish(message: LaraL10n.text(
                en: "Aura Studio currently targets the verified iOS 17 and 18 SpringBoard surfaces.",
                es: "Aura Studio utiliza actualmente las superficies verificadas de SpringBoard en iOS 17 y 18."
            ))
            return
        }
        guard operation.isRemoving ||
                mode != AuraStudioMode.tint.rawValue ||
                version.majorVersion == 18 else {
            finish(message: message(for: -17))
            return
        }
        guard mgr.dsready, requestedFlags != 0 else {
            finish(message: LaraL10n.text(
                en: "Prepare Eagle access and select at least one verified surface before applying.",
                es: "Prepara el acceso de Eagle y selecciona al menos una superficie verificada antes de aplicar."
            ))
            return
        }
        guard requestedFlags.nonzeroBitCount == 1,
              let operationTarget = requestedTarget else {
            finish(message: LaraL10n.text(
                en: "Choose exactly one Aura surface. Island and Dock are applied independently.",
                es: "Elige exactamente una superficie Aura. Island y Dock se aplican de forma independiente."
            ))
            return
        }
        guard requestedFlags == flag(for: selectedTarget),
              operationTarget == selectedTarget else {
            let reason = "Aura target contract mismatch selected=\(selectedTarget.title) " +
                "flags=0x\(String(requestedFlags, radix: 16)) resolved=\(operationTarget.title)"
            AuraStudioDiagnostics.log("preflight.contract-failed", "op=\(operationID) \(reason)")
            finish(message: LaraL10n.text(
                en: "Aura Studio detected a stale surface selection and sent nothing to SpringBoard. Reopen Aura Studio and choose Dock again.",
                es: "Aura Studio detectó una selección de superficie obsoleta y no envió nada a SpringBoard. Vuelve a abrir Aura Studio y elige Dock otra vez."
            ))
            return
        }
        guard operation.isRemoving ||
                policyAllows(requestedProfileMode, for: operationTarget) else {
            finish(message: LaraL10n.text(
                en: "\(requestedProfileMode.title) is not available for \(operationTarget.title) in the \(releaseChannel.title) channel. Nothing was sent to SpringBoard.",
                es: "\(requestedProfileMode.title) no está disponible para \(operationTarget.title) en el canal \(releaseChannel.title). No se envió nada a SpringBoard."
            ))
            return
        }

        var steps: [AuraStudioOperationStep] = []
        if requestedFlags & Flag.island != 0 {
            steps.append(AuraStudioOperationStep(
                flag: Flag.island,
                englishName: "Dynamic Island",
                spanishName: "Dynamic Island"
            ))
        }
        if requestedFlags & Flag.dock != 0 {
            steps.append(AuraStudioOperationStep(
                flag: Flag.dock,
                englishName: "Dock",
                spanishName: "Dock"
            ))
        }

        let selectedRGB: (red: Double, green: Double, blue: Double) =
            operationTarget == .island
                ? (sanitizedChannel(islandRed), sanitizedChannel(islandGreen), sanitizedChannel(islandBlue))
                : (sanitizedChannel(dockRed), sanitizedChannel(dockGreen), sanitizedChannel(dockBlue))
        let redValue = Int32(channel255(selectedRGB.red))
        let greenValue = Int32(channel255(selectedRGB.green))
        let blueValue = Int32(channel255(selectedRGB.blue))
        AuraStudioDiagnostics.log(
            "preflight.contract",
            "op=\(operationID) target=\(operationTarget.title) " +
                "flags=0x\(String(requestedFlags, radix: 16)) " +
                "mode=\(requestedProfileMode.rawValue) " +
                "rgb=\(redValue),\(greenValue),\(blueValue)"
        )
        let previouslyVerified = UInt32(max(activeFlagsRaw, 0)) & deviceSupportedFlags
        var retainedVerified = previouslyVerified
        var newlyApplied: UInt32 = 0
        var removedFlags: UInt32 = 0
        var motionDegraded = false
        var firstUnavailableResult: Int32?
        var verifiedFallbackResult: Int32?

        isApplying = true
        operationIsRemoval = operation.isRemoving
        operationStepIndex = 0
        operationStepCount = steps.count
        activeOperationID = operationID
        applyStage = LaraL10n.text(
            en: "Preparing a fresh SpringBoard session…",
            es: "Preparando una sesión nueva de SpringBoard…"
        )

        func resetOperationUI() {
            isApplying = false
            applyStage = ""
            operationStepIndex = 0
            operationStepCount = 0
            operationIsRemoval = false
            activeOperationID = nil
        }

        func failBeforeNativeCall(_ reason: String) {
            AuraStudioDiagnostics.log(
                "sequence.preflight-failed",
                "op=\(operationID) reason=\(reason)"
            )
            diagnosticsURL = makeDiagnosticsReport(summary: reason)
            resetOperationUI()
            AuraStudioApplyGate.end()
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Aura Studio could not prepare a safe session for \(operationTarget.title). Nothing was sent, and the other aura was not touched. A technical report is ready if the problem repeats.",
                es: "Aura Studio no pudo preparar una sesión segura para \(operationTarget.title). No se envió nada y no se tocó la otra aura. Hay un informe técnico disponible si el problema se repite."
            ))
        }

        func failAfterNativeCall(
            _ reason: String,
            result: Int32? = nil,
            userDetail: String? = nil
        ) {
            let resultText = result.map { " result=\($0)" } ?? ""
            AuraStudioDiagnostics.log(
                "breaker.open",
                "op=\(operationID) applied=0x\(String(newlyApplied, radix: 16)) " +
                "removed=0x\(String(removedFlags, radix: 16))" +
                resultText + " reason=\(reason)"
            )
            activeFlagsRaw = Int(retainedVerified | newlyApplied)
            if activeFlagsRaw & Int(Flag.island) == 0 {
                activeModeRaw = 0
                activeIslandModeRaw = 0
            }
            if activeFlagsRaw & Int(Flag.dock) == 0 {
                activeDockModeRaw = 0
            }
            if activeFlagsRaw == 0 {
                activeSpringBoardPID = 0
            } else {
                activeSpringBoardPID = Int(
                    "SpringBoard".withCString { find_process_pid($0) }
                )
            }
            mgr.quarantineRemoteCall(reason: reason)
            applySafetyBlocked = true
            AuraStudioApplyGate.lock()
            diagnosticsURL = makeDiagnosticsReport(summary: reason)
            resetOperationUI()
            let baseMessage = LaraL10n.text(
                en: "Aura Studio stopped because \(operationTarget.title) could not be verified. The other aura was not changed and no automatic respring was attempted. Share the diagnostic report, then fully close and reopen Eagle before another test.",
                es: "Aura Studio se detuvo porque no pudo verificar \(operationTarget.title). No se cambió la otra aura ni se intentó un respring automático. Comparte el informe y luego cierra y abre Eagle completamente antes de otra prueba."
            )
            let detailSuffix = userDetail.map { "\n\n\($0)" } ?? ""
            notice = AuraStudioNotice(message: baseMessage + detailSuffix)
        }

        func finishVerifiedRollback(
            _ result: Int32,
            step: AuraStudioOperationStep,
            reason: String
        ) {
            // -12 is a native, fail-closed Island contract: the candidate
            // could not be read back, so native code synchronously removes it
            // (or restores the previously committed Island) before returning.
            // Reaching this path also means PID and RemoteCall health were
            // already revalidated above. Keep the error visible, preserve the
            // previously verified state, and permit a fresh manual retry.
            retainedVerified |= previouslyVerified & step.flag
            let finalFlags = retainedVerified | newlyApplied
            activeFlagsRaw = Int(finalFlags)
            activeSpringBoardPID = finalFlags == 0
                ? 0
                : Int(operationSpringBoardPID)
            AuraStudioDiagnostics.log(
                "step.rollback-verified",
                "op=\(operationID) module=\(step.englishName) " +
                "result=\(result) previous=0x\(String(previouslyVerified, radix: 16)) " +
                "retained=0x\(String(finalFlags, radix: 16)) retry=fresh-session"
            )
            diagnosticsURL = makeDiagnosticsReport(summary: reason)
            resetOperationUI()
            AuraStudioApplyGate.end()
            notice = AuraStudioNotice(
                message: message(for: result) + " " + LaraL10n.text(
                    en: "SpringBoard and the protected call session remained healthy. No restart is required; you may retry this profile, and the other aura was not changed.",
                    es: "SpringBoard y la sesión protegida permanecieron en buen estado. No necesitas reiniciar; puedes volver a intentar este perfil y no se cambió la otra aura."
                )
            )
        }

        func completeSuccess(deadlineWarning: Bool = false) {
            let finalFlags = retainedVerified | newlyApplied
            activeFlagsRaw = Int(finalFlags)
            activeModeRaw = activeIslandModeRaw
            if finalFlags == 0 {
                activeSpringBoardPID = 0
                activeModeRaw = 0
                activeIslandModeRaw = 0
                activeDockModeRaw = 0
            } else {
                activeSpringBoardPID = Int(operationSpringBoardPID)
            }
            let sequenceStage = !operation.isRemoving &&
                newlyApplied == 0 && firstUnavailableResult != nil
                ? "sequence.unavailable"
                : "sequence.success"
            AuraStudioDiagnostics.log(
                sequenceStage,
                "op=\(operationID) applied=0x\(String(newlyApplied, radix: 16)) " +
                "removed=0x\(String(removedFlags, radix: 16)) " +
                "degraded=\(motionDegraded) deadlineWarning=\(deadlineWarning)"
            )
            let diagnosticsSummary: String
            if operation.isRemoving {
                diagnosticsSummary = "Scoped removal completed and verified"
            } else if newlyApplied == 0, let firstUnavailableResult {
                diagnosticsSummary =
                    "No mutation; selected host unavailable (result \(firstUnavailableResult))"
            } else if verifiedFallbackResult != nil {
                diagnosticsSummary = "Requested style unavailable; verified Glow fallback retained"
            } else {
                diagnosticsSummary = "Scoped apply completed and verified"
            }
            diagnosticsURL = makeDiagnosticsReport(summary: diagnosticsSummary)
            resetOperationUI()
            if !deadlineWarning {
                AuraStudioApplyGate.end()
            }
            let baseResultMessage: String
            if let verifiedFallbackResult {
                baseResultMessage = message(for: verifiedFallbackResult)
            } else if !operation.isRemoving,
                      newlyApplied == 0,
                      let firstUnavailableResult {
                baseResultMessage = message(for: firstUnavailableResult)
            } else {
                baseResultMessage = successMessage(
                    appliedFlags: operation.isRemoving
                        ? removedFlags
                        : newlyApplied,
                    requestedFlags: requestedFlags,
                    restoring: operation.isRemoving,
                    motionDegraded: motionDegraded,
                    appliedMode: operation.isRemoving
                        ? nil
                        : AuraStudioMode(rawValue: mode)
                )
            }
            let resultMessage: String
            if deadlineWarning {
                resultMessage = baseResultMessage + " " + LaraL10n.text(
                    en: "Verification exceeded the safety deadline, so Eagle will not retry this surface. Fully close and reopen Eagle before another Aura Studio operation.",
                    es: "La verificación superó el límite de seguridad, por lo que Eagle no volverá a intentar esta superficie. Cierra Eagle completamente y vuelve a abrirlo antes de otra operación de Aura Studio."
                )
            } else {
                resultMessage = baseResultMessage
            }
            notice = AuraStudioNotice(message: resultMessage)
        }

        func runStep(_ index: Int) {
            guard activeOperationID == operationID, isApplying else { return }
            guard index < steps.count else {
                completeSuccess()
                return
            }
            let step = steps[index]
            operationStepIndex = index + 1
            applyStage = LaraL10n.text(
                en: "Preparing \(step.englishName) safely…",
                es: "Preparando \(step.spanishName) de forma segura…"
            )
            AuraStudioDiagnostics.log(
                "step.session.begin",
                "op=\(operationID) index=\(index) module=\(step.englishName) " +
                "flag=0x\(String(step.flag, radix: 16))"
            )
            mgr.prepareFreshRemoteCall(
                process: "SpringBoard",
                timeout: 20
            ) { process, sessionError in
                guard activeOperationID == operationID, isApplying else { return }
                guard let process else {
                    let reason = sessionError ?? "Fresh SpringBoard session was unavailable"
                    let isReadOnlyPreflight =
                        reason.localizedCaseInsensitiveContains("access is not ready") ||
                        reason.localizedCaseInsensitiveContains("still running") ||
                        reason.localizedCaseInsensitiveContains("safety locked")
                    if isReadOnlyPreflight {
                        failBeforeNativeCall(reason)
                    } else {
                        // RemoteCall initialization can already install target
                        // exception ports and create a helper thread. Any
                        // failure after that point is a transport event, not a
                        // harmless host miss, so this run must fail closed.
                        retainedVerified &= ~step.flag
                        failAfterNativeCall(reason)
                    }
                    return
                }

                let targetPID = process.pid
                let currentPID = "SpringBoard".withCString { find_process_pid($0) }
                guard targetPID > 0,
                      process.creatingExtraThread else {
                    failBeforeNativeCall(
                        "Fresh session identity check failed " +
                        "(target \(targetPID), current \(currentPID), " +
                        "isolated \(process.creatingExtraThread))"
                    )
                    return
                }
                guard currentPID == targetPID,
                      targetPID == operationSpringBoardPID else {
                    retainedVerified = 0
                    newlyApplied = 0
                    activeFlagsRaw = 0
                    activeModeRaw = 0
                    activeIslandModeRaw = 0
                    activeDockModeRaw = 0
                    activeSpringBoardPID = 0
                    failAfterNativeCall(
                        "SpringBoard changed while preparing \(step.englishName) " +
                        "(operation \(operationSpringBoardPID), target \(targetPID), " +
                        "current \(currentPID))"
                    )
                    return
                }
                guard mgr.beginExclusiveRemoteCall(
                    label: "Aura \(step.englishName) \(operationID)"
                ) else {
                    failBeforeNativeCall(
                        "Could not acquire the serialized \(step.englishName) session"
                    )
                    return
                }

                applyStage = LaraL10n.text(
                    en: operation.isRemoving
                        ? "Removing \(step.englishName) only…"
                        : "Applying \(step.englishName) only…",
                    es: operation.isRemoving
                        ? "Eliminando solo \(step.spanishName)…"
                        : "Aplicando solo \(step.spanishName)…"
                )
                AuraStudioDiagnostics.log(
                    "step.native.begin",
                    "op=\(operationID) module=\(step.englishName) " +
                    "action=\(operation.isRemoving ? "remove" : "apply") " +
                    "pid=\(targetPID) flag=0x\(String(step.flag, radix: 16))"
                )
                let started = Date()
                var nativeFinished = false
                var hardDeadlineExceeded = false
                let softProgressWork = DispatchWorkItem {
                    guard activeOperationID == operationID,
                          isApplying,
                          !nativeFinished else { return }
                    applyStage = LaraL10n.text(
                        en: "\(step.englishName) is responding · verifying the live result…",
                        es: "\(step.spanishName) está respondiendo · verificando el resultado en vivo…"
                    )
                    AuraStudioDiagnostics.log(
                        "step.native.progress",
                        "op=\(operationID) module=\(step.englishName) elapsed=10"
                    )
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 10,
                    execute: softProgressWork
                )

                // Device evidence on iOS 18.6.2 shows a healthy, verified
                // Island call can take ~17 seconds. The hard deadline is a
                // circuit breaker, not a false failure: the in-flight result
                // is still consumed, but an automatic retry can never start.
                let hardDeadlineWork = DispatchWorkItem {
                    guard activeOperationID == operationID,
                          isApplying,
                          !nativeFinished else { return }
                    hardDeadlineExceeded = true
                    let reason = "\(step.englishName) exceeded the 60-second safety deadline"
                    AuraStudioDiagnostics.log(
                        "step.native.deadline",
                        "op=\(operationID) module=\(step.englishName) elapsed=60"
                    )
                    applyStage = LaraL10n.text(
                        en: "Still waiting safely for \(step.englishName) · no automatic retry will start…",
                        es: "Aún esperando de forma segura a \(step.spanishName) · no se iniciará otro intento automático…"
                    )
                    mgr.quarantineRemoteCall(reason: reason)
                    applySafetyBlocked = true
                    AuraStudioApplyGate.lock()
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 60,
                    execute: hardDeadlineWork
                )

                DispatchQueue.global(qos: .userInitiated).async {
                    let result = autoreleasepool {
                        eagle_set_aura_studio(
                            process,
                            redValue,
                            greenValue,
                            blueValue,
                            Int32(operation.nativeMode),
                            step.flag
                        )
                    }
                    let elapsed = Date().timeIntervalSince(started)
                    let processError = process.lastError
                    let springBoardPID = "SpringBoard".withCString {
                        find_process_pid($0)
                    }
                    AuraStudioDiagnostics.log(
                        "step.native.end",
                        "op=\(operationID) module=\(step.englishName) result=\(result) " +
                        "elapsed=\(String(format: "%.3f", elapsed)) target=\(targetPID) " +
                        "current=\(springBoardPID) error=\(processError ?? "none")"
                    )
                    DispatchQueue.main.async {
                        let liveSpringBoardPID = "SpringBoard".withCString {
                            find_process_pid($0)
                        }
                        guard activeOperationID == operationID,
                              isApplying,
                              !nativeFinished else {
                            AuraStudioDiagnostics.log(
                                "step.native.late",
                                "op=\(operationID) module=\(step.englishName) result=\(result)"
                            )
                            if springBoardPID != targetPID ||
                                liveSpringBoardPID != targetPID {
                                activeFlagsRaw = 0
                                activeModeRaw = 0
                                activeIslandModeRaw = 0
                                activeDockModeRaw = 0
                                activeSpringBoardPID = 0
                            }
                            mgr.endExclusiveRemoteCall(
                                label: "Aura \(step.englishName) \(operationID)"
                            )
                            return
                        }
                        nativeFinished = true
                        softProgressWork.cancel()
                        hardDeadlineWork.cancel()
                        mgr.endExclusiveRemoteCall(
                            label: "Aura \(step.englishName) \(operationID)"
                        )

                        if springBoardPID != targetPID ||
                            liveSpringBoardPID != targetPID ||
                            targetPID != operationSpringBoardPID {
                            activeFlagsRaw = 0
                            activeModeRaw = 0
                            activeIslandModeRaw = 0
                            activeDockModeRaw = 0
                            activeSpringBoardPID = 0
                            retainedVerified = 0
                            newlyApplied = 0
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "SpringBoard restarted during \(step.englishName) " +
                                "(PID \(targetPID) → \(liveSpringBoardPID))",
                                result: result
                            )
                            return
                        }
                        if !process.isHealthy ||
                            process.lastCallTimedOut ||
                            (processError?.isEmpty == false) {
                            let transportReason = processError ??
                                (process.lastCallTimedOut
                                    ? "RemoteCall transport timed out"
                                    : "RemoteCall session became unhealthy")
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "\(step.englishName) RemoteCall error: \(transportReason)",
                                result: result,
                                userDetail: LaraL10n.text(
                                    en: "The protected call channel became unhealthy while \(step.englishName) was being checked. Eagle did not mark this surface as active.",
                                    es: "El canal protegido de llamadas dejó de estar disponible mientras se verificaba \(step.spanishName). Eagle no marcó esta superficie como activa."
                                )
                            )
                            return
                        }
                        if operation.isRemoving {
                            guard result == 0 else {
                                retainedVerified &= ~step.flag
                                failAfterNativeCall(
                                    "\(step.englishName) removal could not be verified",
                                    result: result,
                                    userDetail: message(for: result)
                                )
                                return
                            }
                            retainedVerified &= ~step.flag
                            removedFlags |= step.flag
                            if step.flag == Flag.island {
                                activeIslandModeRaw = 0
                                activeModeRaw = 0
                            } else if step.flag == Flag.dock {
                                activeDockModeRaw = 0
                            }
                            activeFlagsRaw = Int(retainedVerified | newlyApplied)
                            activeSpringBoardPID = activeFlagsRaw == 0
                                ? 0
                                : Int(springBoardPID)
                            AuraStudioDiagnostics.log(
                                "step.remove.success",
                                "op=\(operationID) module=\(step.englishName) " +
                                "removed=0x\(String(removedFlags, radix: 16))"
                            )
                            if hardDeadlineExceeded {
                                completeSuccess(deadlineWarning: true)
                            } else {
                                runStep(index + 1)
                            }
                            return
                        }
                        if let fallbackMode =
                            AuraStudioNativeContract.verifiedFallbackMode(
                                result: result,
                                target: operationTarget,
                                requestedMode: requestedProfileMode
                            ) {
                            // These results explicitly guarantee that the
                            // static black Glow core was restored and verified.
                            // Keep that truthful state without opening the
                            // circuit breaker or attempting to reapply Tint.
                            newlyApplied |= Flag.island
                            retainedVerified &= ~Flag.island
                            activeFlagsRaw = Int(retainedVerified | newlyApplied)
                            activeSpringBoardPID = Int(springBoardPID)
                            activeModeRaw = fallbackMode.rawValue
                            activeIslandModeRaw = fallbackMode.rawValue
                            activeIslandRed = Int(redValue)
                            activeIslandGreen = Int(greenValue)
                            activeIslandBlue = Int(blueValue)
                            verifiedFallbackResult = result
                            AuraStudioDiagnostics.log(
                                "step.fallback",
                                "op=\(operationID) module=\(step.englishName) result=\(result) verified=glow"
                            )
                            if hardDeadlineExceeded {
                                completeSuccess(deadlineWarning: true)
                            } else {
                                runStep(index + 1)
                            }
                            return
                        }
                        if result == -15 || result == -16 {
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "Native fallback did not match the requested \(step.englishName) profile",
                                result: result,
                                userDetail: LaraL10n.text(
                                    en: "Eagle rejected a fallback intended for a different surface or style. No profile was reported as applied.",
                                    es: "Eagle rechazó un fallback destinado a otra superficie o estilo. Ningún perfil se marcó como aplicado."
                                )
                            )
                            return
                        }
                        if AuraStudioNativeContract.isScopedUnavailable(
                            result: result,
                            target: operationTarget,
                            mode: requestedProfileMode,
                            isRemoval: operation.isRemoving
                        ) {
                            // The native contract defines these as read-only
                            // host/preflight misses. They are safe to report as
                            // unavailable while preserving the other profile's
                            // independently verified state.
                            if firstUnavailableResult == nil {
                                firstUnavailableResult = result
                            }
                            retainedVerified |= previouslyVerified & step.flag
                            activeFlagsRaw = Int(retainedVerified | newlyApplied)
                            if activeFlagsRaw & Int(Flag.island) == 0 {
                                activeModeRaw = 0
                            }
                            AuraStudioDiagnostics.log(
                                "step.unavailable",
                                "op=\(operationID) module=\(step.englishName) result=\(result) mutation=none"
                            )
                            if hardDeadlineExceeded {
                                completeSuccess(deadlineWarning: true)
                            } else {
                                runStep(index + 1)
                            }
                            return
                        }
                        if result == -2 || result == -17 || result == -20 {
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "Native capability result did not match \(step.englishName)",
                                result: result,
                                userDetail: LaraL10n.text(
                                    en: "SpringBoard returned a capability code for another surface or style. Eagle did not update either profile.",
                                    es: "SpringBoard devolvió un código de capacidad para otra superficie o estilo. Eagle no actualizó ningún perfil."
                                )
                            )
                            return
                        }
                        if AuraStudioNativeContract.isScopedVerifiedRollback(
                            result: result,
                            target: operationTarget,
                            isRemoval: operation.isRemoving
                        ) && !hardDeadlineExceeded {
                            finishVerifiedRollback(
                                result,
                                step: step,
                                reason: "\(step.englishName) rejected candidate and verified native rollback (result -12)"
                            )
                            return
                        }
                        if result == -12 {
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "Native rollback result did not match \(step.englishName) or exceeded its deadline",
                                result: result
                            )
                            return
                        }
                        guard result >= 0 else {
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "\(step.englishName) returned unverified native error \(result)",
                                result: result,
                                userDetail: message(for: result)
                            )
                            return
                        }
                        let rawResult = UInt32(bitPattern: result)
                        guard AuraStudioNativeContract.hasExactAppliedSurface(
                            result: result,
                            requestedFlag: step.flag,
                            supportedFlags: Flag.supported
                        ) else {
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "\(step.englishName) returned a missing or cross-surface verification mask",
                                result: result,
                                userDetail: LaraL10n.text(
                                    en: "SpringBoard returned without confirming the requested \(step.englishName) surface, so Eagle cleared only that surface's verified badge.",
                                    es: "SpringBoard terminó sin confirmar la superficie \(step.spanishName) solicitada, por lo que Eagle borró solo el indicador verificado de esa superficie."
                                )
                            )
                            return
                        }

                        newlyApplied |= step.flag
                        retainedVerified &= ~step.flag
                        motionDegraded = motionDegraded ||
                            rawResult & Flag.motionDegraded != 0
                        activeFlagsRaw = Int(retainedVerified | newlyApplied)
                        activeSpringBoardPID = Int(springBoardPID)
                        if step.flag == Flag.island {
                            activeModeRaw = mode
                            activeIslandModeRaw = mode
                            activeIslandRed = Int(redValue)
                            activeIslandGreen = Int(greenValue)
                            activeIslandBlue = Int(blueValue)
                        } else if step.flag == Flag.dock {
                            activeDockModeRaw = mode
                            activeDockRed = Int(redValue)
                            activeDockGreen = Int(greenValue)
                            activeDockBlue = Int(blueValue)
                        }
                        AuraStudioDiagnostics.log(
                            "step.success",
                            "op=\(operationID) module=\(step.englishName) applied=0x\(String(newlyApplied, radix: 16))"
                        )
                        if hardDeadlineExceeded {
                            completeSuccess(deadlineWarning: true)
                        } else {
                            runStep(index + 1)
                        }
                    }
                }
            }
        }

        runStep(0)
    }

    private func makeDiagnosticsReport(summary: String) -> URL? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let relevantFragments = [
            "eagle.aura",
            "eagle.island",
            "eagle.dock",
            "(rc)",
            "remote call",
            "RemoteCall",
        ]
        let lines = globallogger.logs
            .flatMap { $0.components(separatedBy: .newlines) }
            .filter { line in
                relevantFragments.contains { fragment in
                    line.localizedCaseInsensitiveContains(fragment)
                }
            }
            .suffix(600)
        let header = [
            "Eagle Aura Studio diagnostics",
            "timestamp=\(timestamp)",
            "engine=\(auraEngineBuild)",
            "operation=\(activeOperationID ?? "none")",
            "operationKind=\(operationIsRemoval ? "remove" : "apply")",
            "operationStep=\(operationStepIndex)/\(operationStepCount)",
            "summary=\(summary)",
            "device=\(devicemachine())",
            "islandHardware=\(islandCompatibility.diagnosticsToken)",
            "ios=\(ProcessInfo.processInfo.operatingSystemVersionString)",
            "dsready=\(mgr.dsready)",
            "rcrunning=\(mgr.rcrunning)",
            "rcready=\(mgr.rcready)",
            "rcSafetyLocked=\(mgr.rcSafetyLocked)",
            "rcError=\(mgr.rcLastError ?? "none")",
            "selectedTarget=\(selectedTarget.title)",
            "islandDraft=mode:\(islandModeRaw) rgb:\(rgb255String(islandRed, islandGreen, islandBlue))",
            "dockDraft=mode:\(dockModeRaw) rgb:\(rgb255String(dockRed, dockGreen, dockBlue))",
            "selectedFlags=0x\(String(selectedFlags, radix: 16))",
            "activeFlags=0x\(String(UInt32(max(activeFlagsRaw, 0)) & deviceSupportedFlags, radix: 16))",
            "activeIsland=mode:\(activeIslandModeRaw) rgb:\(activeIslandRed),\(activeIslandGreen),\(activeIslandBlue)",
            "activeDock=mode:\(activeDockModeRaw) rgb:\(activeDockRed),\(activeDockGreen),\(activeDockBlue)",
            "activeSpringBoardPID=\(activeSpringBoardPID)",
            "currentSpringBoardPID=\("SpringBoard".withCString { find_process_pid($0) })",
            "displayZoomed=\(displayGeometry.isDisplayZoomed)",
            "displayFactor=\(String(format: "%.4f,%.4f", displayGeometry.xFactor, displayGeometry.yFactor))",
            "--- filtered log ---",
        ]
        let report = (header + Array(lines)).joined(separator: "\n") + "\n"
        let filename = "Eagle-Aura-Diagnostics-" +
            timestamp.replacingOccurrences(of: ":", with: "-") + ".txt"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        do {
            try report.write(to: url, atomically: true, encoding: .utf8)
            AuraStudioDiagnostics.log(
                "diagnostics.ready",
                "path=\(url.lastPathComponent) lines=\(lines.count)"
            )
            return url
        } catch {
            AuraStudioDiagnostics.log(
                "diagnostics.failed",
                "error=\(error.localizedDescription)"
            )
            return nil
        }
    }

    private func finish(message: String) {
        AuraStudioDiagnostics.log("finish", "error=true")
        DispatchQueue.main.async {
            AuraStudioApplyGate.end()
            self.activeOperationID = nil
            self.isApplying = false
            self.applyStage = ""
            self.operationStepIndex = 0
            self.operationStepCount = 0
            self.operationIsRemoval = false
            self.notice = AuraStudioNotice(message: message)
        }
    }

    private func successMessage(
        appliedFlags: UInt32,
        requestedFlags: UInt32,
        restoring: Bool,
        motionDegraded: Bool,
        appliedMode: AuraStudioMode?
    ) -> String {
        if restoring {
            let removed = names(for: appliedFlags)
            let missing = names(for: requestedFlags & ~appliedFlags)
            let removedText = removed.isEmpty
                ? LaraL10n.text(en: "No aura", es: "Ningún aura")
                : removed.joined(separator: ", ")
            if !missing.isEmpty {
                return LaraL10n.text(
                    en: "Removed and verified: \(removedText). Not verified: \(missing.joined(separator: ", ")).",
                    es: "Eliminado y verificado: \(removedText). Sin verificar: \(missing.joined(separator: ", "))."
                )
            }
            return LaraL10n.text(
                en: "Removed and verified: \(removedText). The original system appearance is restored.",
                es: "Eliminado y verificado: \(removedText). Se restauró la apariencia original del sistema."
            )
        }
        let applied = names(for: appliedFlags)
        let missing = names(for: requestedFlags & ~appliedFlags)
        if motionDegraded {
            let unavailable = missing.isEmpty
                ? ""
                : LaraL10n.text(
                    en: " Unavailable: \(missing.joined(separator: ", ")).",
                    es: " No disponible: \(missing.joined(separator: ", "))."
                )
            return LaraL10n.text(
                en: "Applied and verified: \(applied.joined(separator: ", ")). The neon cores are active, but SpringBoard did not retain every moving color phase; no valid light was removed.",
                es: "Aplicado y verificado: \(applied.joined(separator: ", ")). Los núcleos de neón están activos, pero SpringBoard no conservó todas las fases móviles de color; no se eliminó ninguna luz válida."
            ) + unavailable
        }
        if missing.isEmpty {
            let style: String
            if appliedFlags != 0, let appliedMode {
                style = " · \(appliedMode.title)"
            } else {
                style = ""
            }
            return LaraL10n.text(
                en: "Applied and verified: \(applied.joined(separator: ", "))\(style).",
                es: "Aplicado y verificado: \(applied.joined(separator: ", "))\(style)."
            )
        }
        return LaraL10n.text(
            en: "Applied: \(applied.joined(separator: ", ")). Unavailable on the current SpringBoard state: \(missing.joined(separator: ", ")). No unavailable surface was reported as active.",
            es: "Aplicado: \(applied.joined(separator: ", ")). No disponible en el estado actual de SpringBoard: \(missing.joined(separator: ", ")). Ninguna superficie ausente se marcó como activa."
        )
    }

    private func message(for result: Int32) -> String {
        switch result {
        case -2:
            return LaraL10n.text(
                en: "SpringBoard did not expose a safe, visible Dynamic Island host in its current state. Nothing was changed; unlock the iPhone, visit the Home or Lock Screen once, and try again.",
                es: "SpringBoard no expuso un host seguro y visible de Dynamic Island en su estado actual. No se cambió nada; desbloquea el iPhone, visita una vez la pantalla de Inicio o Bloqueo y vuelve a intentarlo."
            )
        case -3:
            return LaraL10n.text(en: "The selected aura style is invalid.", es: "El estilo de aura seleccionado no es válido.")
        case -4:
            return LaraL10n.text(
                en: "The SpringBoard session did not provide an isolated call thread.",
                es: "La sesión de SpringBoard no proporcionó un hilo aislado de llamadas."
            )
        case -5:
            return LaraL10n.text(
                en: "This iOS version is outside Aura Studio's verified range.",
                es: "Esta versión de iOS está fuera del rango verificado de Aura Studio."
            )
        case -6:
            return LaraL10n.text(
                en: "SpringBoard could not create the selected aura color.",
                es: "SpringBoard no pudo crear el color de aura seleccionado."
            )
        case -7:
            return LaraL10n.text(
                en: "Aura Studio caught a system exception and stopped without reporting success.",
                es: "Aura Studio detectó una excepción del sistema y se detuvo sin mostrar un éxito falso."
            )
        case -8:
            return LaraL10n.text(
                en: "Eagle could not resolve the safe Dynamic Island window.",
                es: "Eagle no pudo resolver la ventana segura de Dynamic Island."
            )
        case -9:
            return LaraL10n.text(
                en: "SpringBoard did not provide the UIKit classes required for Island Aura.",
                es: "SpringBoard no proporcionó las clases de UIKit necesarias para Island Aura."
            )
        case -10:
            return LaraL10n.text(
                en: "SpringBoard could not create or position the Island Aura view.",
                es: "SpringBoard no pudo crear o posicionar la vista de Island Aura."
            )
        case -11:
            return LaraL10n.text(
                en: "SpringBoard created the Island host but rejected its light layer.",
                es: "SpringBoard creó el host de Island, pero rechazó su capa luminosa."
            )
        case -12:
            return LaraL10n.text(
                en: "The new Island candidate could not be read back safely, so Eagle rejected and removed it instead of reporting a partial effect as applied. Any previously verified Island was preserved.",
                es: "El nuevo candidato de Island no pudo verificarse de forma segura, por lo que Eagle lo rechazó y eliminó en vez de marcar un efecto parcial como aplicado. Se conservó cualquier Island verificada anteriormente."
            )
        case -13:
            return LaraL10n.text(
                en: "The SpringBoard session is missing its isolated call thread.",
                es: "La sesión de SpringBoard no tiene su hilo aislado de llamadas."
            )
        case -14:
            return LaraL10n.text(
                en: "Island Aura caught a SpringBoard exception. The resulting system state could not be verified, so Eagle cleared the verified badge.",
                es: "Island Aura detectó una excepción de SpringBoard. No se pudo verificar el estado resultante del sistema, por lo que Eagle eliminó el indicador de verificación."
            )
        case -15:
            return LaraL10n.text(
                en: "The thick Island glow is active, but SpringBoard did not retain the moving Rainbow animation. The static core was preserved; choose Glow if you want the verified style.",
                es: "El brillo grueso de Island está activo, pero SpringBoard no conservó la animación Rainbow. El núcleo estático se mantuvo; elige Brillo para usar el estilo verificado."
            )
        case -16:
            return LaraL10n.text(
                en: "SpringBoard did not retain the native Tint background or its gain-map change. Eagle restored and verified the black Glow center; no color layer was left over.",
                es: "SpringBoard no conservó el fondo nativo de Color o el cambio de su mapa de ganancia. Eagle restauró y verificó el centro negro de Brillo; no quedó ninguna capa de color."
            )
        case -17:
            return LaraL10n.text(
                en: "True Tint needs the native adaptive Island background available on this iOS 18 SpringBoard state. Eagle preserved the current aura instead of placing color over music or timer controls.",
                es: "Color real necesita el fondo adaptativo nativo de Island disponible en este estado de SpringBoard de iOS 18. Eagle conservó el aura actual en vez de poner color sobre los controles de música o temporizador."
            )
        case -18:
            return LaraL10n.text(
                en: "Eagle could not verify the complete return to the black system center. The verified badge was cleared. Reopen Eagle on the Home Screen and choose Glow or Remove again.",
                es: "Eagle no pudo verificar el regreso completo al centro negro del sistema. Se eliminó el indicador de verificación. Abre Eagle de nuevo desde Inicio y elige Brillo o Eliminar otra vez."
            )
        case -19:
            return LaraL10n.text(
                en: "SpringBoard did not expose the Home Screen Dock for a verified removal. The Dock badge was cleared and Island was not touched. Return to the Home Screen, reopen Eagle, and choose Remove Dock again.",
                es: "SpringBoard no mostró el Dock de Inicio para verificar su eliminación. Se borró el indicador del Dock y no se modificó Island. Vuelve a Inicio, abre Eagle y elige Eliminar Dock nuevamente."
            )
        case -20:
            return LaraL10n.text(
                en: "SpringBoard did not expose the live Home Screen Dock. Island was not reported as the Dock. Return to the Home Screen once, reopen Aura Studio, and try Dock again.",
                es: "SpringBoard no mostró el Dock activo de Inicio. Island no se marcó como Dock. Vuelve una vez a Inicio, abre Aura Studio y prueba el Dock nuevamente."
            )
        case -21:
            return LaraL10n.text(
                en: "The live Dock was found, but its neon core could not be read back safely. Eagle removed only the unverified Dock layer.",
                es: "Se encontró el Dock activo, pero su núcleo de neón no pudo verificarse de forma segura. Eagle eliminó únicamente la capa del Dock no verificada."
            )
        case -22:
            return LaraL10n.text(
                en: "Aura Studio refused a combined Island and Dock request before changing SpringBoard. Select one profile and apply it separately.",
                es: "Aura Studio rechazó una solicitud combinada de Island y Dock antes de cambiar SpringBoard. Selecciona un perfil y aplícalo por separado."
            )
        case -23:
            return LaraL10n.text(
                en: "The protected SpringBoard session became unavailable before this surface could be changed. Nothing was reported as applied. Export the report, fully close Eagle, and reopen it before retrying.",
                es: "La sesión protegida de SpringBoard dejó de estar disponible antes de cambiar esta superficie. No se indicó nada como aplicado. Exporta el informe, cierra Eagle completamente y vuelve a abrirlo antes de intentarlo de nuevo."
            )
        case -24:
            return LaraL10n.text(
                en: "Island rejected the new candidate, but SpringBoard did not provide enough read-back to verify the previous appearance. Eagle stopped and safety locked this run; export the report, then fully close and reopen Eagle.",
                es: "Island rechazó el nuevo candidato, pero SpringBoard no proporcionó suficiente lectura para verificar la apariencia anterior. Eagle se detuvo y bloqueó esta ejecución por seguridad; exporta el informe y luego cierra y vuelve a abrir Eagle."
            )
        default:
            return LaraL10n.text(
                en: "SpringBoard rejected the Aura Studio update.",
                es: "SpringBoard rechazó la actualización de Aura Studio."
            )
        }
    }

    private func names(for flags: UInt32) -> [String] {
        var names: [String] = []
        if flags & Flag.island != 0 {
            names.append(LaraL10n.text(en: "Island", es: "Isla"))
        }
        if flags & Flag.screen != 0 {
            names.append(LaraL10n.text(en: "Screen", es: "Pantalla"))
        }
        if flags & Flag.battery != 0 {
            names.append(LaraL10n.text(en: "Battery Halo", es: "Halo de batería"))
        }
        if flags & Flag.dock != 0 { names.append("Dock") }
        if flags & Flag.lock != 0 {
            names.append(LaraL10n.text(en: "Lock", es: "Bloqueo"))
        }
        return names
    }
}
