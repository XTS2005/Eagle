import SwiftUI

enum LaraAccessState: Equatable {
    case idle
    case preparing(String, Double?)
#if EAGLE_A18_PREPARE_LAB
    case kernelStageReady(String)
#endif
    case ready
    case failed(String)
}

struct LaraAccessView: View {
    @ObservedObject private var mgr = laramgr.shared
    @State private var state: LaraAccessState = .idle
#if EAGLE_A18_PREPARE_LAB
    @State private var labAttemptLocked = false
#endif

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
        .onChange(of: mgr.dsprogress) { progress in
            if mgr.dsrunning {
                state = .preparing(LaraL10n.text(
                    en: "Preparing device",
                    es: "Preparando el dispositivo"
                ), progress)
            }
        }
#if EAGLE_A18_PREPARE_LAB
        .onAppear(perform: refreshA18LabAttemptLock)
#endif
    }

    private var readyView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
            Text(LaraL10n.text(en: "Eagle is ready", es: "Eagle está lista"))
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(compact ? 16 : 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
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
                        en: "Uses Eagle's access engine only on allowed device and iOS combinations. If the iPhone restarts, do not retry; reopen Eagle and share a Prepare report.",
                        es: "Usa el motor de acceso de Eagle solo en combinaciones permitidas de dispositivo e iOS. Si el iPhone se reinicia, no lo intentes otra vez; abre Eagle y comparte un reporte de Preparar."
                    ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            switch state {
            case .preparing(let message, let progress):
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(message)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        EagleRainbowSpinner()
                    }
                    if let progress {
                        EagleRainbowProgressBar(value: progress)
                    }
                }

            case .failed(let message):
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)

#if EAGLE_A18_PREPARE_LAB
            case .kernelStageReady(let message):
                Label(message, systemImage: "checkmark.shield.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.green)
#endif

            default:
                EmptyView()
            }

            Button(action: prepare) {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
#if EAGLE_A18_PREPARE_LAB
            .disabled(isBusy || isKernelStageReady || labAttemptLocked || isunsupported() || isdebugged())
#else
            .disabled(isBusy || isunsupported() || isdebugged())
#endif

            if isunsupported() {
                Text(eagleSupportAssessment().message(
                    spanish: LaraL10n.language == .spanish
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
#if EAGLE_A18_PREPARE_LAB
            if !isunsupported(), !isdebugged(), isA18KernelStageLabRuntime {
                Label {
                    Text(labAttemptLocked
                        ? LaraL10n.text(
                            en: "A kernel-stage attempt is already recorded for this iPhone and build. This private lab will not run it again.",
                            es: "Ya existe un intento de la etapa del kernel para este iPhone y esta compilación. Este laboratorio privado no lo ejecutará otra vez."
                        )
                        : LaraL10n.text(
                            en: "Private one-shot lab: it tests only the kernel stage and does not continue to compatibility data, sandbox access, or Aura.",
                            es: "Laboratorio privado de un solo intento: prueba solo la etapa del kernel y no continúa con datos de compatibilidad, acceso al sandbox ni Aura."
                        ))
                } icon: {
                    Image(systemName: "exclamationmark.shield.fill")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.orange)
            }
#endif
        }
        .padding(compact ? 16 : 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var isBusy: Bool {
        if case .preparing = state { return true }
        return mgr.dsrunning || mgr.sbxrunning
    }

#if EAGLE_A18_PREPARE_LAB
    private var isKernelStageReady: Bool {
        if case .kernelStageReady = state { return true }
        return false
    }
#endif

    private var buttonTitle: String {
        if isBusy { return LaraL10n.text(en: "Preparing…", es: "Preparando…") }
        if isdebugged() { return LaraL10n.text(en: "Disconnect Xcode", es: "Desconecta Xcode") }
#if EAGLE_A18_PREPARE_LAB
        if isA18KernelStageLabRuntime {
            if labAttemptLocked {
                return LaraL10n.text(en: "Lab attempt recorded", es: "Intento de laboratorio registrado")
            }
            return LaraL10n.text(en: "Test kernel stage once", es: "Probar etapa del kernel una vez")
        }
        if isKernelStageReady {
            return LaraL10n.text(en: "Kernel stage verified", es: "Etapa del kernel verificada")
        }
#endif
        if case .failed = state { return LaraL10n.text(en: "Try again", es: "Intentar otra vez") }
        return LaraL10n.text(en: "Prepare iPhone", es: "Preparar iPhone")
    }

    private func prepare() {
        guard !isBusy, !isunsupported(), !isdebugged() else { return }
#if EAGLE_A18_PREPARE_LAB
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let machine = devicemachine()
        let systemBuild = eagleSystemBuild()?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let route = eaglePrepareExecutionRoute(
            version: version,
            machine: machine,
            systemBuild: systemBuild
        )
        if route == .a18KernelStageLab {
            guard let systemBuild else {
                state = .failed(LaraL10n.text(
                    en: "The verified system build could not be read, so the private lab did not run.",
                    es: "No se pudo leer la compilación verificada del sistema, por lo que el laboratorio privado no se ejecutó."
                ))
                return
            }
            prepareA18KernelStageLab(
                route: route,
                machine: machine,
                systemBuild: systemBuild
            )
            return
        }
        if route == .blockedFieldRestart {
            state = .failed(EagleSupportAssessment(
                status: .unsupported,
                reason: .iphone16IOS185FieldRestart
            ).message(spanish: LaraL10n.language == .spanish))
            return
        }
#endif
        state = .preparing(LaraL10n.text(
            en: "Checking compatibility",
            es: "Comprobando compatibilidad"
        ), nil)
        offsets_init()

        if mgr.dsready {
            resolveOffsetsAndOpenSandbox()
            return
        }

        mgr.run { success in
            guard success else {
                state = .failed(LaraL10n.text(
                    en: "The device could not be prepared. You can try again.",
                    es: "No se pudo preparar el dispositivo. Puedes intentarlo de nuevo."
                ))
                return
            }
            resolveOffsetsAndOpenSandbox()
        }
    }

#if EAGLE_A18_PREPARE_LAB
    private func prepareA18KernelStageLab(
        route: EaglePrepareExecutionRoute,
        machine: String,
        systemBuild: String
    ) {
        guard !labAttemptLocked else {
            state = .failed(LaraL10n.text(
                en: "This private lab already recorded an attempt for this iPhone and build.",
                es: "Este laboratorio privado ya registró un intento para este iPhone y esta compilación."
            ))
            return
        }
        guard !UserDefaults.standard.bool(forKey: "stashKRW") else {
            state = .failed(LaraL10n.text(
                en: "Turn off Stash KRW primitives in Settings and restart Eagle before this isolated test. Nothing was run.",
                es: "Desactiva Guardar primitivas KRW en Ajustes y reinicia Eagle antes de esta prueba aislada. No se ejecutó nada."
            ))
            return
        }
        let beginResult = EaglePrepareAttemptJournal.begin(
            route: route.rawValue,
            machine: machine,
            systemBuild: systemBuild
        )
        let attemptID: String
        switch beginResult {
        case .started(let identifier):
            attemptID = identifier
        case .alreadyRecorded:
            labAttemptLocked = true
            state = .failed(LaraL10n.text(
                en: "This private lab already recorded an attempt for this iPhone and build.",
                es: "Este laboratorio privado ya registró un intento para este iPhone y esta compilación."
            ))
            return
        case .unavailable:
            state = .failed(LaraL10n.text(
                en: "Eagle could not create the durable test record, so the kernel stage was not started.",
                es: "Eagle no pudo crear el registro duradero de la prueba, por lo que no inició la etapa del kernel."
            ))
            return
        }
        labAttemptLocked = true
        state = .preparing(LaraL10n.text(
            en: "Testing the isolated kernel stage",
            es: "Probando la etapa aislada del kernel"
        ), nil)
        offsets_init()
        EaglePrepareAttemptJournal.mark(attemptID, stage: .offsetsInitialized)

        if mgr.dsready {
            guard hasVerifiedA18LabPrimitive else {
                EaglePrepareAttemptJournal.finish(
                    attemptID,
                    succeeded: false,
                    detail: "ready flag was set without complete proc/task/kernel-base references"
                )
                state = .failed(LaraL10n.text(
                    en: "The kernel stage was incomplete. Do not retry; share a Prepare report.",
                    es: "La etapa del kernel quedó incompleta. No lo repitas; comparte un reporte de Preparar."
                ))
                mgr.quarantineRemoteCall(
                    reason: "A18 lab rejected incomplete kernel primitive references"
                )
                return
            }
            EaglePrepareAttemptJournal.finish(
                attemptID,
                succeeded: true,
                detail: "reused verified primitive; sandbox was not started"
            )
            state = .kernelStageReady(LaraL10n.text(
                en: "Kernel access was already ready. Sandbox was not started in this lab.",
                es: "El acceso al kernel ya estaba listo. El laboratorio no abrió el sandbox."
            ))
            mgr.quarantineRemoteCall(
                reason: "A18 kernel-stage lab stops before RemoteCall and sandbox"
            )
            return
        }

        EaglePrepareAttemptJournal.mark(attemptID, stage: .darkSwordRunning)
        mgr.run { success in
            guard success, hasVerifiedA18LabPrimitive else {
                EaglePrepareAttemptJournal.finish(
                    attemptID,
                    succeeded: false,
                    detail: success
                        ? "DarkSword ready flag lacked complete proc/task/kernel-base references"
                        : "DarkSword returned without a verified primitive"
                )
                state = .failed(LaraL10n.text(
                    en: "The isolated kernel stage failed. Do not retry; share a Prepare report.",
                    es: "Falló la etapa aislada del kernel. No lo repitas; comparte un reporte de Preparar."
                ))
                if success {
                    mgr.quarantineRemoteCall(
                        reason: "A18 lab rejected incomplete kernel primitive references"
                    )
                }
                return
            }

            EaglePrepareAttemptJournal.finish(
                attemptID,
                succeeded: true,
                detail: "kernel primitive verified; compatibility data and sandbox were intentionally skipped"
            )
            state = .kernelStageReady(LaraL10n.text(
                en: "Kernel stage verified. This lab intentionally skipped compatibility data and sandbox access.",
                es: "Etapa del kernel verificada. Este laboratorio omitió intencionalmente los datos de compatibilidad y el acceso al sandbox."
            ))
            mgr.quarantineRemoteCall(
                reason: "A18 kernel-stage lab stops before RemoteCall and sandbox"
            )
        }
    }

    private var hasVerifiedA18LabPrimitive: Bool {
        ds_get_our_proc() != 0 &&
            ds_get_our_task() != 0 &&
            ds_get_kernel_base() != 0
    }

    private var isA18KernelStageLabRuntime: Bool {
        eaglePrepareExecutionRoute(
            version: ProcessInfo.processInfo.operatingSystemVersion,
            machine: devicemachine(),
            systemBuild: eagleSystemBuild()
        ) == .a18KernelStageLab
    }

    private func refreshA18LabAttemptLock() {
        guard isA18KernelStageLabRuntime,
              let build = eagleSystemBuild()?.trimmingCharacters(
                  in: .whitespacesAndNewlines
              ),
              !build.isEmpty else {
            labAttemptLocked = false
            return
        }
        labAttemptLocked = EaglePrepareAttemptJournal.hasRecordedAttempt(
            route: EaglePrepareExecutionRoute.a18KernelStageLab.rawValue,
            machine: devicemachine(),
            systemBuild: build
        )
    }
#endif

    private func resolveOffsetsAndOpenSandbox() {
        if mgr.hasOffsets {
            openSandbox()
            return
        }

        state = .preparing(LaraL10n.text(
            en: "Getting compatibility data for your iPhone",
            es: "Obteniendo compatibilidad para tu iPhone"
        ), nil)
        DispatchQueue.global(qos: .userInitiated).async {
            let fetched = fetchkcache()
            let loaded = fetched && dlkcache()
            DispatchQueue.main.async {
                mgr.hasOffsets = loaded
                if loaded {
                    openSandbox()
                } else {
                    state = .failed(LaraL10n.text(
                        en: "Compatibility data could not be prepared.",
                        es: "No fue posible preparar los datos de compatibilidad."
                    ))
                }
            }
        }
    }

    private func openSandbox() {
        state = .preparing(LaraL10n.text(
            en: "Opening temporary access",
            es: "Abriendo acceso temporal"
        ), nil)
        mgr.sbxescape { success in
            if success {
                state = .ready
                onReady?()
            } else {
                state = .failed(LaraL10n.text(
                    en: "Temporary access could not be started.",
                    es: "El acceso temporal no pudo iniciarse."
                ))
            }
        }
    }
}
