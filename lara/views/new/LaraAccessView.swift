import Combine
import SwiftUI

enum LaraAccessState: Equatable {
    case idle
    case preparing(String, Double?)
    case ready
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

    private init() {
        recoverPersistedState()
    }

    var isBusy: Bool {
        activeID != nil
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

        guard activeID == nil else { return }
        guard !mgr.dsrunning, !mgr.sbxrunning else {
            state = .failed(LaraL10n.text(
                en: "Another access operation is still finishing. Do not tap Prepare again yet.",
                es: "Otra operación de acceso todavía está terminando. No vuelvas a pulsar Preparar todavía."
            ))
            return
        }
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
                    en: "Protected access could not be prepared. You can try again whenever you choose.",
                    es: "No se pudo preparar el acceso protegido. Puedes volver a intentarlo cuando quieras."
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
                        en: "Compatibility data could not be prepared. You can try again whenever you choose.",
                        es: "No se pudieron preparar los datos de compatibilidad. Puedes volver a intentarlo cuando quieras."
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
                    en: "Temporary access could not be opened. You can try again whenever you choose.",
                    es: "No se pudo abrir el acceso temporal. Puedes volver a intentarlo cuando quieras."
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
        closeAttempt(id, stage: failedStage, outcome: "failed", failure: message)
        state = .failed(message)
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
        // Clear pause values left by older builds. Reports remain available,
        // but they no longer delay or gate another user-initiated attempt.
        defaults.removeObject(forKey: "eagle.prepare.cooldown-until")
        defaults.removeObject(forKey: "eagle.prepare.consecutive-failures")

        if let interruptedID = defaults.string(forKey: DefaultsKey.activeID) {
            let interruptedStage = defaults.string(forKey: DefaultsKey.activeStage) ?? EagleAccessStage.checking.rawValue
            let message = LaraL10n.text(
                en: "The previous preparation ended before Eagle received a result. A crash report is available on Eagle Home.",
                es: "La preparación anterior terminó antes de que Eagle recibiera un resultado. Hay un reporte disponible en el inicio de Eagle."
            )
            defaults.set(interruptedID, forKey: DefaultsKey.lastID)
            defaults.set(interruptedStage, forKey: DefaultsKey.lastStage)
            defaults.set("interrupted", forKey: DefaultsKey.lastOutcome)
            defaults.set(now.timeIntervalSince1970, forKey: DefaultsKey.lastEndedAt)
            defaults.set(message, forKey: DefaultsKey.lastFailure)
            defaults.removeObject(forKey: DefaultsKey.activeID)
            defaults.removeObject(forKey: DefaultsKey.activeStage)
            defaults.removeObject(forKey: DefaultsKey.activeStartedAt)
            defaults.synchronize()
            state = .failed(message)
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

    private func isCurrent(_ id: UUID, stage: EagleAccessStage? = nil) -> Bool {
        guard activeID == id else { return false }
        if let stage, activeStage != stage { return false }
        return true
    }
}

struct LaraAccessView: View {
    @ObservedObject private var mgr = laramgr.shared
    @ObservedObject private var access = EagleAccessCoordinator.shared
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

            case .failed(let message):
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)

            default:
                EmptyView()
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
                isBusy || isunsupported() || isdebugged()
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
                    en: "Keep Eagle open while it works. Simultaneous attempts are blocked. If the iPhone restarts, Eagle keeps a crash report you can share, without delaying your next attempt.",
                    es: "Mantén Eagle abierta durante el proceso. Los intentos simultáneos están bloqueados. Si el iPhone se reinicia, Eagle conserva un reporte que puedes compartir sin retrasar el siguiente intento."
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
        if isdebugged() { return LaraL10n.text(en: "Disconnect Xcode", es: "Desconecta Xcode") }
        if case .failed = access.state { return LaraL10n.text(en: "Try once more", es: "Intentar una vez más") }
        return LaraL10n.text(en: "Prepare iPhone", es: "Preparar iPhone")
    }

    private var buttonAccessibilityHint: String {
        return LaraL10n.text(
            en: "Opens a confirmation for a protected access attempt. You can retry whenever no other attempt is running.",
            es: "Abre una confirmación para un intento de acceso protegido. Puedes reintentar cuando no haya otro intento ejecutándose."
        )
    }

    private var buttonAccessibilityValue: String {
        if isBusy {
            return LaraL10n.text(en: "In progress", es: "En progreso")
        }
        return LaraL10n.text(en: "Ready to start", es: "Listo para iniciar")
    }

    private func prepare() {
        guard
            !isBusy,
            !isunsupported(),
            !isdebugged()
        else { return }
        access.prepare(onReady: onReady)
    }
}
