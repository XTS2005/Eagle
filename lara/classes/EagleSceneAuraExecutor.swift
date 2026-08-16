import Foundation

enum EagleSceneAuraTarget: String, Codable, Hashable {
    case island
    case dock

    var component: EagleSceneComponent {
        self == .island ? .islandAura : .dockAura
    }

    var nativeFlag: UInt32 {
        self == .island ? 1 : (1 << 5)
    }

    var displayName: String {
        self == .island ? "Dynamic Island" : "Dock"
    }
}

private final class EagleSceneRemoteCallBox: @unchecked Sendable {
    let value: RemoteCall

    init(_ value: RemoteCall) {
        self.value = value
    }
}

private struct EagleSceneAuraNativeResponse: @unchecked Sendable {
    let result: Int32
    let targetPID: Int32
    let springBoardPID: Int32
    let healthy: Bool
    let timedOut: Bool
    let error: String?
}

/// Executes exactly one Aura surface per native transaction. Scene automation
/// intentionally uses the same one-bit native contract as Aura Studio and
/// never resprings or submits Island and Dock together.
@MainActor
final class EagleSceneAuraExecutor {
    static let shared = EagleSceneAuraExecutor()

    private let manager = laramgr.shared
    private let supportedNativeFlags = EagleSceneAuraTarget.island.nativeFlag |
        EagleSceneAuraTarget.dock.nativeFlag

    private init() {}

    func apply(
        _ profile: EagleSceneAuraProfile,
        to target: EagleSceneAuraTarget
    ) async -> EagleSceneComponentResult {
        let component = target.component
        let version = ProcessInfo.processInfo.operatingSystemVersion

        guard manager.dsready else {
            return result(
                component,
                .pending,
                en: "Waiting for Prepare access.",
                es: "Esperando que prepares el acceso."
            )
        }
        guard version.majorVersion == 17 || version.majorVersion == 18 else {
            return result(
                component,
                .skipped,
                en: "Live Aura is currently verified only on iOS 17 and iOS 18.",
                es: "Aura en vivo está verificada actualmente solo en iOS 17 y iOS 18."
            )
        }
        guard EagleFeaturePolicy.allowsSceneAura(
            profile.mode,
            target: target,
            operatingSystemVersion: version
        ) else {
            return result(
                component,
                .skipped,
                en: "\(profile.mode.localizedName) is not available for \(target.displayName) in the current feature channel and iOS version. Nothing was sent.",
                es: "\(profile.mode.localizedName) no está disponible para \(target.displayName) en el canal y la versión de iOS actuales. No se envió nada."
            )
        }
        if target == .island {
            guard EagleDynamicIslandCompatibility.current.canAttemptLiveIslandAura else {
                return result(
                    component,
                    .skipped,
                    en: "This physical iPhone does not expose a verified Dynamic Island host.",
                    es: "Este iPhone físico no expone un host verificado de Dynamic Island."
                )
            }
        }
        guard target != .dock || profile.mode != .tint else {
            return result(
                component,
                .skipped,
                en: "Tint is not available for Dock Aura; the saved Dock profile was not sent.",
                es: "Color no está disponible para Dock Aura; el perfil guardado no fue enviado."
            )
        }

        let operationID = String(UUID().uuidString.prefix(8))
        log("begin", operationID, target, "mode=\(profile.mode.rawValue) \(profile.rgbSummary)")

        let preparation: (RemoteCall?, String?) = await withCheckedContinuation { continuation in
            manager.prepareFreshRemoteCall(process: "SpringBoard", timeout: 20) { process, error in
                continuation.resume(returning: (process, error))
            }
        }
        guard let process = preparation.0 else {
            log("session.failed", operationID, target, preparation.1 ?? "unknown")
            return result(
                component,
                .failed,
                en: "A fresh SpringBoard session could not be prepared. Nothing was reported as applied.",
                es: "No se pudo preparar una sesión nueva de SpringBoard. Nada se marcó como aplicado."
            )
        }

        let targetPID = process.pid
        let currentPID = springBoardPID()
        guard targetPID > 0,
              targetPID == currentPID,
              process.creatingExtraThread else {
            log("identity.failed", operationID, target, "target=\(targetPID) current=\(currentPID)")
            return result(
                component,
                .failed,
                en: "The SpringBoard session identity changed before Apply. Nothing was sent.",
                es: "La identidad de la sesión de SpringBoard cambió antes de Aplicar. No se envió nada."
            )
        }

        let label = "Scene Aura \(target.displayName) \(operationID)"
        guard manager.beginExclusiveRemoteCall(label: label) else {
            return result(
                component,
                .failed,
                en: "Another protected SpringBoard operation is still active.",
                es: "Otra operación protegida de SpringBoard sigue activa."
            )
        }

        let processBox = EagleSceneRemoteCallBox(process)
        let response: EagleSceneAuraNativeResponse = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let nativeResult = autoreleasepool {
                    eagle_set_aura_studio(
                        processBox.value,
                        Int32(profile.red),
                        Int32(profile.green),
                        Int32(profile.blue),
                        Int32(profile.mode.rawValue),
                        target.nativeFlag
                    )
                }
                continuation.resume(returning: EagleSceneAuraNativeResponse(
                    result: nativeResult,
                    targetPID: targetPID,
                    springBoardPID: Self.readSpringBoardPID(),
                    healthy: processBox.value.isHealthy,
                    timedOut: processBox.value.lastCallTimedOut,
                    error: processBox.value.lastError
                ))
            }
        }
        manager.endExclusiveRemoteCall(label: label)
        log(
            "native.end",
            operationID,
            target,
            "result=\(response.result) target=\(response.targetPID) current=\(response.springBoardPID) " +
                "healthy=\(response.healthy) timeout=\(response.timedOut) error=\(response.error ?? "none")"
        )

        guard response.targetPID == response.springBoardPID else {
            clearVerifiedBadge(for: target)
            manager.quarantineRemoteCall(reason: "SpringBoard restarted during Scene \(target.displayName) Aura")
            return result(
                component,
                .failed,
                en: "SpringBoard restarted during verification. The Aura was not reported as applied.",
                es: "SpringBoard se reinició durante la verificación. El Aura no se marcó como aplicado."
            )
        }
        guard response.healthy,
              !response.timedOut,
              response.error?.isEmpty != false else {
            clearVerifiedBadge(for: target)
            manager.quarantineRemoteCall(
                reason: response.error ?? "Scene \(target.displayName) Aura transport became unhealthy"
            )
            return result(
                component,
                .failed,
                en: "The protected call channel became unhealthy. Close and reopen Eagle before another Aura attempt.",
                es: "El canal protegido dejó de estar disponible. Cierra y abre Eagle antes de otro intento de Aura."
            )
        }

        let verifiedIslandFallback = target == .island &&
            ((response.result == -15 && profile.mode == .rainbow) ||
             (response.result == -16 && profile.mode == .tint))
        if verifiedIslandFallback {
            persistVerified(profile: .init(
                mode: .glow,
                red: profile.red,
                green: profile.green,
                blue: profile.blue
            ), target: target, springBoardPID: response.springBoardPID)
            return result(
                component,
                .applied,
                en: "The requested effect was unavailable; native verification preserved a static Glow.",
                es: "El efecto solicitado no estaba disponible; la verificación nativa conservó un Brillo estático."
            )
        }
        if [-2, -17, -20].contains(response.result) {
            return result(
                component,
                .skipped,
                en: "SpringBoard did not expose this live surface; no mutation was reported.",
                es: "SpringBoard no expuso esta superficie en vivo; no se reportó ninguna modificación."
            )
        }
        if response.result == -12 {
            return result(
                component,
                .failed,
                en: "The candidate failed verification and native rollback was confirmed.",
                es: "El candidato falló la verificación y se confirmó la reversión nativa."
            )
        }
        guard response.result >= 0 else {
            clearVerifiedBadge(for: target)
            manager.quarantineRemoteCall(
                reason: "Scene \(target.displayName) Aura returned unverified result \(response.result)"
            )
            return result(
                component,
                .failed,
                en: "Native Apply returned unverified result \(response.result). Close and reopen Eagle before retrying.",
                es: "Aplicar devolvió el resultado no verificado \(response.result). Cierra y abre Eagle antes de reintentar."
            )
        }

        let flags = UInt32(bitPattern: response.result)
        guard flags & supportedNativeFlags == target.nativeFlag else {
            clearVerifiedBadge(for: target)
            manager.quarantineRemoteCall(
                reason: "Scene \(target.displayName) Aura did not verify its requested host"
            )
            return result(
                component,
                .failed,
                en: "SpringBoard returned without verifying the requested Aura surface.",
                es: "SpringBoard terminó sin verificar la superficie Aura solicitada."
            )
        }

        persistVerified(
            profile: profile,
            target: target,
            springBoardPID: response.springBoardPID
        )
        return result(
            component,
            .applied,
            en: "\(target.displayName) \(profile.mode.localizedName) was applied and verified independently.",
            es: "\(profile.mode.localizedName) de \(target.displayName) se aplicó y verificó de forma independiente."
        )
    }

    private func persistVerified(
        profile: EagleSceneAuraProfile,
        target: EagleSceneAuraTarget,
        springBoardPID: Int32
    ) {
        let defaults = UserDefaults.standard
        let savedPID = defaults.integer(forKey: "eagle.auraStudio.activeSpringBoardPID")
        var flags = savedPID == Int(springBoardPID)
            ? UInt32(max(defaults.integer(forKey: "eagle.auraStudio.activeFlags"), 0)) &
                supportedNativeFlags
            : 0
        flags |= target.nativeFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(Int(springBoardPID), forKey: "eagle.auraStudio.activeSpringBoardPID")

        switch target {
        case .island:
            defaults.set(Double(profile.red) / 255, forKey: "eagle.islandAura.red")
            defaults.set(Double(profile.green) / 255, forKey: "eagle.islandAura.green")
            defaults.set(Double(profile.blue) / 255, forKey: "eagle.islandAura.blue")
            defaults.set(profile.mode.rawValue, forKey: "eagle.auraStudio.island.mode")
            defaults.set(profile.mode.rawValue, forKey: "eagle.auraStudio.activeMode")
            defaults.set(profile.mode.rawValue, forKey: "eagle.auraStudio.activeIslandMode")
            defaults.set(profile.red, forKey: "eagle.auraStudio.activeIslandRed")
            defaults.set(profile.green, forKey: "eagle.auraStudio.activeIslandGreen")
            defaults.set(profile.blue, forKey: "eagle.auraStudio.activeIslandBlue")
        case .dock:
            defaults.set(Double(profile.red) / 255, forKey: "eagle.dockAura.red")
            defaults.set(Double(profile.green) / 255, forKey: "eagle.dockAura.green")
            defaults.set(Double(profile.blue) / 255, forKey: "eagle.dockAura.blue")
            defaults.set(profile.mode.rawValue, forKey: "eagle.auraStudio.dock.mode")
            defaults.set(profile.mode.rawValue, forKey: "eagle.auraStudio.activeDockMode")
            defaults.set(profile.red, forKey: "eagle.auraStudio.activeDockRed")
            defaults.set(profile.green, forKey: "eagle.auraStudio.activeDockGreen")
            defaults.set(profile.blue, forKey: "eagle.auraStudio.activeDockBlue")
        }
    }

    private func clearVerifiedBadge(for target: EagleSceneAuraTarget) {
        let defaults = UserDefaults.standard
        var flags = UInt32(max(defaults.integer(forKey: "eagle.auraStudio.activeFlags"), 0)) &
            supportedNativeFlags
        flags &= ~target.nativeFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        if target == .island {
            defaults.set(0, forKey: "eagle.auraStudio.activeIslandMode")
            defaults.set(0, forKey: "eagle.auraStudio.activeMode")
        } else {
            defaults.set(0, forKey: "eagle.auraStudio.activeDockMode")
        }
        if flags == 0 {
            defaults.set(0, forKey: "eagle.auraStudio.activeSpringBoardPID")
        }
    }

    private func result(
        _ component: EagleSceneComponent,
        _ state: EagleSceneResultState,
        en: String,
        es: String
    ) -> EagleSceneComponentResult {
        EagleSceneComponentResult(
            component: component,
            state: state,
            detail: LaraL10n.text(en: en, es: es)
        )
    }

    private func springBoardPID() -> Int32 {
        Self.readSpringBoardPID()
    }

    nonisolated private static func readSpringBoardPID() -> Int32 {
        "SpringBoard".withCString { find_process_pid($0) }
    }

    private func log(
        _ stage: String,
        _ operationID: String,
        _ target: EagleSceneAuraTarget,
        _ detail: String
    ) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        globallogger.log(
            "[\(formatter.string(from: Date()))] (eagle.scene.aura) " +
                "stage=\(stage) op=\(operationID) target=\(target.rawValue) \(detail)"
        )
    }
}
