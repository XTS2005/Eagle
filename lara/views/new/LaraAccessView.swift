import Combine
import SwiftUI

enum LaraAccessState: Equatable {
    case idle
    case preparing(String, Double?)
    case ready
    case cooldown(String, Date)
    case failed(String)
}

private enum EagleAccessStage: String {
    case idle
    case checking
    case kernelAccess
    case compatibility
    case sandbox
    case ready
    case failed
}

/// Owns the single Prepare Access transaction for the entire app. Several feature
/// screens can present `LaraAccessView` at once, so the attempt must not live in a
/// view's local `@State` or each copy can start the native engine independently.
private final class EagleAccessCoordinator: ObservableObject {
    static let shared = EagleAccessCoordinator()

    @Published private(set) var state: LaraAccessState = .idle

    private enum DefaultsKey {
        static let activeID = "eagle.prepare.active-id"
        static let activeStage = "eagle.prepare.active-stage"
        static let activeStartedAt = "eagle.prepare.active-started-at"
        static let cooldownUntil = "eagle.prepare.cooldown-until"
        static let consecutiveFailures = "eagle.prepare.consecutive-failures"
        static let lastID = "eagle.prepare.last-id"
        static let lastStage = "eagle.prepare.last-stage"
        static let lastOutcome = "eagle.prepare.last-outcome"
        static let lastEndedAt = "eagle.prepare.last-ended-at"
        static let lastFailure = "eagle.prepare.last-failure"
    }

    private let mgr = laramgr.shared
    private let defaults = UserDefaults.standard
    private var activeID: UUID?
    private var activeStage: EagleAccessStage = .idle
    private var completion: (() -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    private var cooldownWorkItem: DispatchWorkItem?

    private init() {
        recoverPersistedState()
    }

    var isBusy: Bool {
        activeID != nil
    }

    var isCoolingDown: Bool {
        if case .cooldown(_, let until) = state {
            return until > Date()
        }
        return false
    }

    func prepare(onReady: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.prepare(onReady: onReady)
            }
            return
        }

        if mgr.sbxready {
            state = .ready
            onReady?()
            return
        }

        // An interrupted-attempt report is fail-closed. Another view, an app
        // relaunch, or a repeated tap must never silently clear this gate. The
        // diagnostics card owns the user's explicit acknowledgement action.
        if EaglePrepareDiagnostics.shared.requiresPrepareAcknowledgement {
            state = .failed(LaraL10n.text(
                en: "Eagle detected that the previous preparation was interrupted. Share the crash report, then acknowledge it before trying again.",
                es: "Eagle detectó que la preparación anterior fue interrumpida. Comparte el reporte del fallo y después confírmalo antes de volver a intentarlo."
            ))
            return
        }

        guard activeID == nil else { return }
        guard !mgr.dsrunning, !mgr.sbxrunning else {
            state = .failed(LaraL10n.text(
                en: "Another access operation is still finishing. Do not tap Prepare again yet.",
                es: "Otra operación de acceso todavía está terminando. No vuelvas a pulsar Preparar todavía."
            ))
            return
        }
        guard !isCoolingDown else { return }

        let id = UUID()
        activeID = id
        completion = onReady
        persistStart(id)
        EaglePrepareDiagnostics.shared.beginPipelineAttempt(stage: "pipeline.checking")
        scheduleAttemptTimeout(id)

        transition(id, to: .checking, message: LaraL10n.text(
            en: "Checking compatibility",
            es: "Comprobando compatibilidad"
        ))

        offsets_init()
        if mgr.dsready {
            resolveOffsets(id)
        } else {
            runKernelAccess(id)
        }
    }

    func updateExploitProgress(_ progress: Double) {
        guard activeID != nil, activeStage == .kernelAccess, mgr.dsrunning else { return }
        state = .preparing(LaraL10n.text(
            en: "Preparing protected access",
            es: "Preparando el acceso protegido"
        ), min(max(progress, 0), 1))
    }

    func reconcileReadyState(_ ready: Bool) {
        guard ready else { return }
        if let id = activeID {
            finishReady(id)
        } else {
            state = .ready
        }
    }

    private func runKernelAccess(_ id: UUID) {
        guard transition(id, to: .kernelAccess, message: LaraL10n.text(
            en: "Preparing protected access",
            es: "Preparando el acceso protegido"
        ), progress: 0) else { return }

        mgr.run { [weak self] success in
            guard let self, self.isCurrent(id, stage: .kernelAccess) else { return }
            guard success, self.mgr.dsready else {
                self.fail(id, message: LaraL10n.text(
                    en: "Protected access could not be prepared. Eagle paused retries to protect this iPhone.",
                    es: "No se pudo preparar el acceso protegido. Eagle pausó los reintentos para proteger este iPhone."
                ))
                return
            }
            self.resolveOffsets(id)
        }
    }

    private func resolveOffsets(_ id: UUID) {
        guard isCurrent(id) else { return }
        if mgr.hasOffsets {
            openSandbox(id)
            return
        }

        guard transition(id, to: .compatibility, message: LaraL10n.text(
            en: "Getting compatibility data for your iPhone",
            es: "Obteniendo compatibilidad para tu iPhone"
        )) else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetched = fetchkcache()
            let loaded = fetched && dlkcache()
            DispatchQueue.main.async {
                guard let self, self.isCurrent(id, stage: .compatibility) else { return }
                self.mgr.hasOffsets = loaded
                guard loaded else {
                    self.fail(id, message: LaraL10n.text(
                        en: "Compatibility data could not be prepared. Eagle paused retries before opening system access.",
                        es: "No se pudieron preparar los datos de compatibilidad. Eagle pausó los reintentos antes de abrir el acceso al sistema."
                    ))
                    return
                }
                self.openSandbox(id)
            }
        }
    }

    private func openSandbox(_ id: UUID) {
        guard isCurrent(id) else { return }
        if mgr.sbxready {
            finishReady(id)
            return
        }
        guard !mgr.sbxrunning else {
            fail(id, message: LaraL10n.text(
                en: "Temporary access was already running from another request. Eagle stopped this duplicate attempt.",
                es: "El acceso temporal ya se estaba ejecutando desde otra solicitud. Eagle detuvo este intento duplicado."
            ))
            return
        }
        guard transition(id, to: .sandbox, message: LaraL10n.text(
            en: "Opening temporary access",
            es: "Abriendo acceso temporal"
        )) else { return }

        mgr.sbxescape { [weak self] success in
            guard let self, self.isCurrent(id, stage: .sandbox) else { return }
            if success, self.mgr.sbxready {
                self.finishReady(id)
            } else {
                self.fail(id, message: LaraL10n.text(
                    en: "Temporary access could not be opened. Eagle paused retries to avoid repeating an unsafe operation.",
                    es: "No se pudo abrir el acceso temporal. Eagle pausó los reintentos para evitar repetir una operación insegura."
                ))
            }
        }
    }

    @discardableResult
    private func transition(
        _ id: UUID,
        to next: EagleAccessStage,
        message: String,
        progress: Double? = nil
    ) -> Bool {
        guard isCurrent(id) else { return false }
        activeStage = next
        defaults.set(next.rawValue, forKey: DefaultsKey.activeStage)
        defaults.synchronize()
        EaglePrepareDiagnostics.shared.markStage(
            "pipeline.\(next.rawValue)",
            progress: progress
        )
        mgr.logmsg("(prepare) attempt=\(id.uuidString) stage=\(next.rawValue)")
        state = .preparing(message, progress)
        return true
    }

    private func finishReady(_ id: UUID) {
        guard isCurrent(id) else { return }
        let callback = completion
        EaglePrepareDiagnostics.shared.finishAttemptFromPipeline(
            success: true,
            stage: "pipeline.ready"
        )
        closeAttempt(id, stage: .ready, outcome: "ready", failure: nil)
        defaults.set(0, forKey: DefaultsKey.consecutiveFailures)
        defaults.removeObject(forKey: DefaultsKey.cooldownUntil)
        state = .ready
        callback?()
    }

    private func fail(_ id: UUID, message: String) {
        guard isCurrent(id) else { return }
        let failedStage = activeStage
        EaglePrepareDiagnostics.shared.finishAttemptFromPipeline(
            success: false,
            stage: "pipeline.\(failedStage.rawValue).failed"
        )
        let failures = min(defaults.integer(forKey: DefaultsKey.consecutiveFailures) + 1, 10)
        defaults.set(failures, forKey: DefaultsKey.consecutiveFailures)
        let cooldown: TimeInterval
        switch failures {
        case 1: cooldown = 60
        case 2: cooldown = 180
        default: cooldown = 300
        }
        let until = Date().addingTimeInterval(cooldown)
        defaults.set(until.timeIntervalSince1970, forKey: DefaultsKey.cooldownUntil)
        closeAttempt(id, stage: failedStage, outcome: "failed", failure: message)
        state = .cooldown(message, until)
        scheduleCooldownEnd(until, message: message)
    }

    private func closeAttempt(
        _ id: UUID,
        stage: EagleAccessStage,
        outcome: String,
        failure: String?
    ) {
        guard activeID == id else { return }
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        completion = nil
        activeID = nil
        activeStage = outcome == "ready" ? .ready : .failed

        defaults.set(id.uuidString, forKey: DefaultsKey.lastID)
        defaults.set(stage.rawValue, forKey: DefaultsKey.lastStage)
        defaults.set(outcome, forKey: DefaultsKey.lastOutcome)
        defaults.set(Date().timeIntervalSince1970, forKey: DefaultsKey.lastEndedAt)
        if let failure {
            defaults.set(failure, forKey: DefaultsKey.lastFailure)
        } else {
            defaults.removeObject(forKey: DefaultsKey.lastFailure)
        }
        defaults.removeObject(forKey: DefaultsKey.activeID)
        defaults.removeObject(forKey: DefaultsKey.activeStage)
        defaults.removeObject(forKey: DefaultsKey.activeStartedAt)
        defaults.synchronize()
        mgr.logmsg("(prepare) attempt=\(id.uuidString) outcome=\(outcome) lastStage=\(stage.rawValue)")
    }

    private func persistStart(_ id: UUID) {
        activeStage = .checking
        defaults.set(id.uuidString, forKey: DefaultsKey.activeID)
        defaults.set(EagleAccessStage.checking.rawValue, forKey: DefaultsKey.activeStage)
        defaults.set(Date().timeIntervalSince1970, forKey: DefaultsKey.activeStartedAt)
        defaults.synchronize()
    }

    private func recoverPersistedState() {
        let now = Date()
        let existingCooldown = Date(timeIntervalSince1970: defaults.double(forKey: DefaultsKey.cooldownUntil))

        if let interruptedID = defaults.string(forKey: DefaultsKey.activeID) {
            let interruptedStage = defaults.string(forKey: DefaultsKey.activeStage) ?? EagleAccessStage.checking.rawValue
            let message = LaraL10n.text(
                en: "The previous preparation ended before Eagle received a result. Share the crash report before another attempt.",
                es: "La preparación anterior terminó antes de que Eagle recibiera un resultado. Comparte el reporte del fallo antes de realizar otro intento."
            )
            let until = max(existingCooldown, now.addingTimeInterval(300))
            defaults.set(interruptedID, forKey: DefaultsKey.lastID)
            defaults.set(interruptedStage, forKey: DefaultsKey.lastStage)
            defaults.set("interrupted", forKey: DefaultsKey.lastOutcome)
            defaults.set(now.timeIntervalSince1970, forKey: DefaultsKey.lastEndedAt)
            defaults.set(message, forKey: DefaultsKey.lastFailure)
            defaults.set(until.timeIntervalSince1970, forKey: DefaultsKey.cooldownUntil)
            defaults.set(min(defaults.integer(forKey: DefaultsKey.consecutiveFailures) + 1, 10), forKey: DefaultsKey.consecutiveFailures)
            defaults.removeObject(forKey: DefaultsKey.activeID)
            defaults.removeObject(forKey: DefaultsKey.activeStage)
            defaults.removeObject(forKey: DefaultsKey.activeStartedAt)
            defaults.synchronize()
            state = .cooldown(message, until)
            scheduleCooldownEnd(until, message: message)
            return
        }

        if existingCooldown > now {
            let message = defaults.string(forKey: DefaultsKey.lastFailure) ?? LaraL10n.text(
                en: "Eagle paused preparation after the previous failure.",
                es: "Eagle pausó la preparación después del fallo anterior."
            )
            state = .cooldown(message, existingCooldown)
            scheduleCooldownEnd(existingCooldown, message: message)
        }
    }

    private func scheduleAttemptTimeout(_ id: UUID) {
        timeoutWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.isCurrent(id) else { return }
            self.fail(id, message: LaraL10n.text(
                en: "Preparation did not return a result in time. The protected operation cannot be cancelled safely, so Eagle blocked another attempt while it finishes.",
                es: "La preparación no devolvió un resultado a tiempo. La operación protegida no se puede cancelar con seguridad, por eso Eagle bloqueó otro intento mientras termina."
            ))
        }
        timeoutWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 180, execute: item)
    }

    private func scheduleCooldownEnd(_ until: Date, message: String) {
        cooldownWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard case .cooldown(_, let currentUntil) = self.state, currentUntil == until else { return }
            self.state = .failed(message + " " + LaraL10n.text(
                en: "You may try once more now.",
                es: "Ahora puedes realizar un solo intento más."
            ))
        }
        cooldownWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, until.timeIntervalSinceNow), execute: item)
    }

    private func isCurrent(_ id: UUID, stage: EagleAccessStage? = nil) -> Bool {
        guard activeID == id else { return false }
        if let stage, activeStage != stage { return false }
        return true
    }
}

struct LaraAccessView: View {
    @ObservedObject private var mgr = laramgr.shared
    @ObservedObject private var access = EagleAccessCoordinator.shared
    @ObservedObject private var diagnostics = EaglePrepareDiagnostics.shared
    @State private var showingPrepareConfirmation = false

    let compact: Bool
    let onReady: (() -> Void)?

    init(compact: Bool = false, onReady: (() -> Void)? = nil) {
        self.compact = compact
        self.onReady = onReady
    }

    var body: some View {
        Group {
            if mgr.sbxready {
                readyView
            } else {
                preparationView
            }
        }
        .onAppear {
            access.reconcileReadyState(mgr.sbxready)
        }
        .onChange(of: mgr.sbxready) { ready in
            access.reconcileReadyState(ready)
        }
        .onChange(of: mgr.dsprogress) { progress in
            access.updateExploitProgress(progress)
        }
    }

    private var readyView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
            Text(LaraL10n.text(en: "Eagle is ready", es: "Eagle está lista"))
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(compact ? 12 : 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LaraL10n.text(
            en: "Eagle access is ready",
            es: "El acceso de Eagle está preparado"
        ))
    }

    private var preparationView: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LaraL10n.text(en: "Prepare access", es: "Preparar acceso"))
                        .font(.headline)
                    Text(LaraL10n.text(
                        en: "Eagle needs temporary access to make this change. Nothing is applied without your confirmation.",
                        es: "Eagle necesita acceso temporal para realizar este cambio. Nada se aplica sin tu confirmación."
                    ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if diagnostics.requiresPrepareAcknowledgement {
                Label {
                    Text(LaraL10n.text(
                        en: "Go to Eagle Home, save or review the crash report, then unlock one controlled retry.",
                        es: "Ve al inicio de Eagle, guarda o revisa el reporte del fallo y después desbloquea un único reintento controlado."
                    ))
                } icon: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.orange)
            } else {
                switch access.state {
                case .preparing(let message, let progress):
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(message)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            ProgressView()
                                .accessibilityHidden(true)
                        }
                        if let progress {
                            ProgressView(value: progress)
                                .accessibilityLabel(message)
                                .accessibilityValue("\(Int(progress * 100))%")
                        }
                    }

                case .cooldown(let message, let until):
                    VStack(alignment: .leading, spacing: 5) {
                        Label(message, systemImage: "hand.raised.fill")
                        Text(cooldownText(until))
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                    .foregroundStyle(.orange)

                case .failed(let message):
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)

                default:
                    EmptyView()
                }
            }

            Button {
                showingPrepareConfirmation = true
            } label: {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel(buttonTitle)
            .accessibilityHint(buttonAccessibilityHint)
            .accessibilityValue(buttonAccessibilityValue)
            .disabled(
                isBusy || access.isCoolingDown ||
                diagnostics.requiresPrepareAcknowledgement ||
                isunsupported() || isdebugged()
            )
            .confirmationDialog(
                LaraL10n.text(en: "Prepare this iPhone?", es: "¿Preparar este iPhone?"),
                isPresented: $showingPrepareConfirmation,
                titleVisibility: .visible
            ) {
                Button(LaraL10n.text(
                    en: "Start One Prepare Attempt",
                    es: "Iniciar un intento de preparación"
                )) {
                    prepare()
                }
                Button(LaraL10n.text(en: "Cancel", es: "Cancelar"), role: .cancel) {}
            } message: {
                Text(LaraL10n.text(
                    en: "Keep Eagle open while it works. Repeated taps are blocked. If the iPhone restarts, reopen Eagle and share the saved crash report before retrying.",
                    es: "Mantén Eagle abierta durante el proceso. Los toques repetidos están bloqueados. Si el iPhone se reinicia, vuelve a abrir Eagle y comparte el reporte guardado antes de reintentar."
                ))
            }

            if isunsupported() {
                Text(LaraL10n.text(
                    en: "This device or iOS version is not compatible with Eagle's current engine.",
                    es: "Este dispositivo o esta versión de iOS no es compatible con el motor actual de Eagle."
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if isdebugged() {
                Label {
                    Text(LaraL10n.text(
                        en: "Do not prepare access while Xcode is attached. Press Stop in Xcode, then open Eagle manually from the Home Screen.",
                        es: "No prepares el acceso mientras Xcode esté conectado. Pulsa Stop en Xcode y después abre Eagle manualmente desde la pantalla de inicio."
                    ))
                } icon: {
                    Image(systemName: "cable.connector.slash")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.orange)
            }
        }
        .padding(compact ? 16 : 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var isBusy: Bool {
        access.isBusy || mgr.dsrunning || mgr.sbxrunning
    }

    private var buttonTitle: String {
        if isBusy { return LaraL10n.text(en: "Preparing…", es: "Preparando…") }
        if diagnostics.requiresPrepareAcknowledgement {
            return LaraL10n.text(en: "Prepare locked", es: "Preparación bloqueada")
        }
        if access.isCoolingDown { return LaraL10n.text(en: "Retry paused", es: "Reintento pausado") }
        if isdebugged() { return LaraL10n.text(en: "Disconnect Xcode", es: "Desconecta Xcode") }
        if case .failed = access.state { return LaraL10n.text(en: "Try once more", es: "Intentar una vez más") }
        return LaraL10n.text(en: "Prepare iPhone", es: "Preparar iPhone")
    }

    private var buttonAccessibilityHint: String {
        if diagnostics.requiresPrepareAcknowledgement {
            return LaraL10n.text(
                en: "Review the saved report from Eagle Home before another attempt.",
                es: "Revisa el reporte guardado desde el inicio de Eagle antes de realizar otro intento."
            )
        }
        if access.isCoolingDown {
            return LaraL10n.text(
                en: "Eagle is waiting before another protected access attempt.",
                es: "Eagle está esperando antes de realizar otro intento de acceso protegido."
            )
        }
        return LaraL10n.text(
            en: "Opens a confirmation before one protected access attempt. Repeated taps are ignored.",
            es: "Abre una confirmación antes de un único intento de acceso protegido. Los toques repetidos se ignoran."
        )
    }

    private var buttonAccessibilityValue: String {
        if diagnostics.requiresPrepareAcknowledgement {
            return LaraL10n.text(en: "Locked after interruption", es: "Bloqueado después de una interrupción")
        }
        if isBusy {
            return LaraL10n.text(en: "In progress", es: "En progreso")
        }
        if access.isCoolingDown {
            return LaraL10n.text(en: "Cooling down", es: "En pausa de seguridad")
        }
        return LaraL10n.text(en: "Ready to start", es: "Listo para iniciar")
    }

    private func cooldownText(_ until: Date) -> String {
        let seconds = max(1, Int(ceil(until.timeIntervalSinceNow)))
        let minutes = max(1, Int(ceil(Double(seconds) / 60)))
        return LaraL10n.text(
            en: "Retry available in about \(minutes) min.",
            es: "Reintento disponible en aproximadamente \(minutes) min."
        )
    }

    private func prepare() {
        guard
            !isBusy,
            !access.isCoolingDown,
            !diagnostics.requiresPrepareAcknowledgement,
            !isunsupported(),
            !isdebugged()
        else { return }
        access.prepare(onReady: onReady)
    }
}
