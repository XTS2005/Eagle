import SwiftUI
import UIKit

enum IslandGalleryStyle: Int, CaseIterable, Identifiable {
    case starlight = 9
    case inferno = 10
    case horizon = 11
    case vortex = 12
    case bubblegum = 13
    case traffic = 14

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .starlight: return LaraL10n.text(en: "Starlight", es: "Luz estelar")
        case .inferno: return LaraL10n.text(en: "Inferno", es: "Inferno")
        case .horizon: return LaraL10n.text(en: "Horizon", es: "Horizonte")
        case .vortex: return LaraL10n.text(en: "Vortex", es: "Vórtice")
        case .bubblegum: return LaraL10n.text(en: "Bubblegum", es: "Chicle")
        case .traffic: return LaraL10n.text(en: "Traffic", es: "Tráfico")
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
/// Gallery styles differ only by their native mode/asset and fixed halo color;
/// every style is installed and read back through the shared Island verifier.
@MainActor
final class IslandGalleryExecutor {
    static let shared = IslandGalleryExecutor()

    private let manager = laramgr.shared
    private let islandFlag: UInt32 = 1
    private let supportedFlags: UInt32 = 1 | (1 << 5)

    private init() {}

    func apply(_ style: IslandGalleryStyle) async -> IslandGalleryApplyResult {
        await run(style: style, restoring: false)
    }

    func restore() async -> IslandGalleryApplyResult {
        await run(style: nil, restoring: true)
    }

    private func run(
        style: IslandGalleryStyle?,
        restoring: Bool
    ) async -> IslandGalleryApplyResult {
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

        let operationID = String(UUID().uuidString.prefix(8))
        log(
            "begin",
            "op=\(operationID) action=\(restoring ? "restore" : "apply") " +
                "mode=\(style?.rawValue ?? 0) device=\(compatibility.modelIdentifier) " +
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

        let label = "Island Gallery \(operationID)"
        guard manager.beginExclusiveRemoteCall(label: label) else {
            return failure(
                en: "Another protected SpringBoard operation is still active.",
                es: "Otra operación protegida de SpringBoard sigue activa."
            )
        }

        let processBox = IslandGalleryRemoteCallBox(process)
        let mode = Int32(style?.rawValue ?? 0)
        let rgb = style?.rgb ?? (red: 0, green: 0, blue: 0)
        let requestedFlag = islandFlag
        let response: IslandGalleryNativeResponse = await withCheckedContinuation { continuation in
            let workItem = DispatchWorkItem {
                let nativeResult = autoreleasepool {
                    eagle_set_aura_studio(
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
        manager.endExclusiveRemoteCall(label: label)
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
        persistVerified(style: style, springBoardPID: response.springBoardPID)
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
        springBoardPID: Int32
    ) {
        let defaults = UserDefaults.standard
        let savedPID = defaults.integer(forKey: "eagle.auraStudio.activeSpringBoardPID")
        var flags = savedPID == Int(springBoardPID)
            ? UInt32(max(defaults.integer(forKey: "eagle.auraStudio.activeFlags"), 0)) & supportedFlags
            : 0
        flags |= islandFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(Int(springBoardPID), forKey: "eagle.auraStudio.activeSpringBoardPID")
        defaults.set(style.rawValue, forKey: "eagle.auraStudio.island.mode")
        defaults.set(style.rawValue, forKey: "eagle.auraStudio.activeMode")
        defaults.set(style.rawValue, forKey: "eagle.auraStudio.activeIslandMode")
        defaults.set(style.rawValue, forKey: "eagle.islandGallery.selectedStyle")
        defaults.set(Int(style.rgb.red), forKey: "eagle.auraStudio.activeIslandRed")
        defaults.set(Int(style.rgb.green), forKey: "eagle.auraStudio.activeIslandGreen")
        defaults.set(Int(style.rgb.blue), forKey: "eagle.auraStudio.activeIslandBlue")
    }

    private func clearVerifiedIsland(springBoardPID: Int32? = nil) {
        let defaults = UserDefaults.standard
        var flags = UInt32(max(defaults.integer(forKey: "eagle.auraStudio.activeFlags"), 0)) & supportedFlags
        flags &= ~islandFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(0, forKey: "eagle.auraStudio.activeIslandMode")
        defaults.set(0, forKey: "eagle.auraStudio.activeMode")
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

struct IslandGalleryView: View {
    @ObservedObject private var manager = laramgr.shared
    @AppStorage("eagle.islandGallery.selectedStyle")
    private var selectedRaw = IslandGalleryStyle.starlight.rawValue
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0
    @AppStorage("eagle.auraStudio.activeIslandMode") private var activeIslandModeRaw = 0
    @State private var isApplying = false
    @State private var notice: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var selectedStyle: IslandGalleryStyle {
        IslandGalleryStyle(rawValue: selectedRaw) ?? .starlight
    }

    private var hasVerifiedIsland: Bool {
        UInt32(max(activeFlagsRaw, 0)) & 1 != 0
    }

    /// Slow breathing level (0.70…1.0) for a card's colour halo.
    private func breatheLevel(at date: Date, offset: Double) -> Double {
        let cycles = date.timeIntervalSinceReferenceDate / 5.6 + offset
        let phase = cycles - floor(cycles)
        return 0.70 + 0.30 * (0.5 - 0.5 * cos(phase * 2 * Double.pi))
    }

    /// Angle (0…360) for the slow colour sheen that circles behind the art.
    private func sheenAngle(at date: Date, offset: Double) -> Double {
        let cycles = date.timeIntervalSinceReferenceDate / 9.0 + offset
        return (cycles - floor(cycles)) * 360
    }

    private func cardPhaseOffset(for style: IslandGalleryStyle) -> Double {
        Double(IslandGalleryStyle.allCases.firstIndex(of: style) ?? 0) * 0.17
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                intro

                if !manager.dsready {
                    LaraAccessView(compact: true)
                }

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(IslandGalleryStyle.allCases) { style in
                        styleCard(style)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(LaraL10n.text(en: "Island Gallery", es: "Galería Island"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            LaraL10n.text(en: "Island Gallery", es: "Galería Island"),
            isPresented: Binding(
                get: { notice != nil },
                set: { if !$0 { notice = nil } }
            )
        ) {
            Button(LaraL10n.text(en: "OK", es: "Aceptar"), role: .cancel) {
                notice = nil
            }
        } message: {
            Text(notice ?? "")
        }
        .onAppear {
            if IslandGalleryStyle(rawValue: selectedRaw) == nil {
                selectedRaw = IslandGalleryStyle.starlight.rawValue
            }
            if let active = IslandGalleryStyle(rawValue: activeIslandModeRaw),
               hasVerifiedIsland {
                selectedRaw = active.rawValue
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(LaraL10n.text(
                en: "Choose an Island made from art",
                es: "Elige una Island hecha con arte"
            ))
                .font(.title2.weight(.bold))
            Text(LaraL10n.text(
                en: "Every design uses the same verified size and position. Its strongest color becomes an intense fixed halo.",
                es: "Cada diseño usa el mismo tamaño y la misma posición verificada. Su color más fuerte se convierte en un halo fijo intenso."
            ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func styleCard(_ style: IslandGalleryStyle) -> some View {
        let active = hasVerifiedIsland && style.rawValue == activeIslandModeRaw
        return VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black)

                TimelineView(.animation(paused: reduceMotion)) { context in
                    let offset = cardPhaseOffset(for: style)
                    let breathe = reduceMotion
                        ? 0.85
                        : breatheLevel(at: context.date, offset: offset)
                    let angle = reduceMotion
                        ? 0
                        : sheenAngle(at: context.date, offset: offset)

                    ZStack {
                        AngularGradient(
                            colors: [
                                style.accent.opacity(0),
                                style.accent.opacity(0.55),
                                style.accent.opacity(0),
                                style.accent.opacity(0.55),
                                style.accent.opacity(0),
                            ],
                            center: .center,
                            angle: .degrees(angle)
                        )
                        .blur(radius: 26)
                        .opacity(0.6)

                        RadialGradient(
                            colors: [style.accent.opacity(0.42 * breathe), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 105
                        )
                    }
                    .allowsHitTesting(false)
                }

                Image(style.assetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(.horizontal, 4)
                    .shadow(color: style.accent.opacity(0.85), radius: 16)
            }
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(style.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                if active {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(style.accent)
                }
            }

            cardActionButton(style, active: active)
        }
        .padding(12)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 21, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .strokeBorder(
                    active ? style.accent : Color.primary.opacity(0.07),
                    lineWidth: active ? 2 : 1
                )
        }
        .shadow(
            color: active ? style.accent.opacity(0.28) : Color.black.opacity(0.05),
            radius: active ? 12 : 5,
            y: active ? 5 : 2
        )
        .animation(.easeOut(duration: 0.18), value: active)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(style.title)
        .accessibilityValue(active
            ? LaraL10n.text(en: "Active", es: "Activo")
            : style.subtitle)
    }

    @ViewBuilder
    private func cardActionButton(_ style: IslandGalleryStyle, active: Bool) -> some View {
        if active {
            // Applied style: this same card offers to remove it, in red.
            Button(role: .destructive) {
                restore()
            } label: {
                Label(
                    LaraL10n.text(en: "Remove", es: "Quitar"),
                    systemImage: "arrow.counterclockwise"
                )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isApplying)
        } else {
            Button {
                selectedRaw = style.rawValue
                applySelectedStyle()
            } label: {
                HStack(spacing: 6) {
                    if isApplying && style == selectedStyle {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(LaraL10n.text(en: "Apply", es: "Aplicar"))
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isApplying || !manager.dsready)
        }
    }

    private func applySelectedStyle() {
        guard !isApplying else { return }
        isApplying = true
        let style = selectedStyle
        Task { @MainActor in
            let result = await IslandGalleryExecutor.shared.apply(style)
            isApplying = false
            if result.succeeded {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            notice = result.message
        }
    }

    private func restore() {
        guard !isApplying else { return }
        isApplying = true
        Task { @MainActor in
            let result = await IslandGalleryExecutor.shared.restore()
            isApplying = false
            if result.succeeded {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            notice = result.message
        }
    }
}
