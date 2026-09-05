//
//  DoubleTapLockView.swift
//  lara
//
//  Created by ruter on 26.04.26.
//

import SwiftUI

/// Double-Tap to Lock — ported from Cyanide's darksword_tweaks.m.
/// Double-tapping an empty area of the Home Screen or Lock Screen background
/// locks the device. Icons, the dock and the passcode screen never trigger it.
/// Passcode-style interaction: a status banner plus a single Enable/Disable
/// action button (no toggle), and a manual Respring button.
struct DoubleTapLockView: View {
    @ObservedObject var mgr: laramgr
    @AppStorage("doubleTapToLock") private var doubleTapToLock: Bool = false
    @State private var busy: Bool = false

    private var sessionReady: Bool {
        mgr.rcready && mgr.sbProc != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusBanner
                applyButton
                respringButton
                infoCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(LaraL10n.text(
            en: "Double-Tap to Lock",
            es: "Bloqueo con doble toque"
        ))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status banner

    private var statusBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: doubleTapToLock ? "hand.tap.fill" : "hand.tap")
                .font(.title3.weight(.semibold))
                .foregroundStyle(doubleTapToLock ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                .frame(width: 44, height: 44)
                .background(
                    (doubleTapToLock ? Color.green : Color.secondary).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(statusTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(statusSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var statusTitle: String {
        if !mgr.dsready {
            return LaraL10n.text(en: "Prepare required", es: "Se requiere Prepare")
        }
        if !sessionReady {
            return LaraL10n.text(
                en: "Session not started",
                es: "Sesión no iniciada"
            )
        }
        return doubleTapToLock
            ? LaraL10n.text(en: "Enabled", es: "Activado")
            : LaraL10n.text(en: "Disabled", es: "Desactivado")
    }

    private var statusSubtitle: String {
        if !mgr.dsready {
            return LaraL10n.text(
                en: "Run Prepare first — the buttons unlock after the exploit succeeds.",
                es: "Ejecuta Prepare primero — los botones se desbloquean tras el exploit."
            )
        }
        if !sessionReady {
            return LaraL10n.text(
                en: "The SpringBoard session starts automatically when you tap Apply.",
                es: "La sesión de SpringBoard se inicia automáticamente al tocar Aplicar."
            )
        }
        return doubleTapToLock
            ? LaraL10n.text(
                en: "Double-tap an empty Home Screen or Lock Screen area to lock.",
                es: "Toca dos veces un área vacía de Inicio o de bloqueo para bloquear."
            )
            : LaraL10n.text(
                en: "The gesture is not installed.",
                es: "El gesto no está instalado."
            )
    }

    private var indicatorColor: Color {
        if !mgr.dsready { return .red }
        if !sessionReady { return .orange }
        return doubleTapToLock ? .green : Color.secondary.opacity(0.4)
    }

    // MARK: - Action buttons

    // Passcode-style fixed buttons: "Apply" always installs the gesture and
    // "Respring" restarts SpringBoard (clearing it). The labels never flip;
    // feedback comes from the alert after the remote call completes and from
    // the status banner.

    private var applyButton: some View {
        Button {
            applyDoubleTapToLock(true)
        } label: {
            HStack(spacing: 10) {
                if busy {
                    ProgressView()
                        .tint(.white)
                }
                Text(LaraL10n.text(en: "Apply", es: "Aplicar"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Color(red: 0.88, green: 0.60, blue: 0.12))
        .disabled(!mgr.dsready || busy || mgr.rcrunning)
        .accessibilityHint(LaraL10n.text(
            en: "Installs the double-tap gesture into SpringBoard.",
            es: "Instala el gesto de doble toque en SpringBoard."
        ))
    }

    private var respringButton: some View {
        Button {
            respringNow()
        } label: {
            Label(
                LaraL10n.text(en: "Respring", es: "Reiniciar SpringBoard"),
                systemImage: "arrow.clockwise"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.secondary)
        .disabled(!mgr.dsready || busy || mgr.rcrunning)
    }

    // MARK: - Info

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                LaraL10n.text(
                    en: "How it works",
                    es: "Cómo funciona"
                ),
                systemImage: "info.circle.fill"
            )
            .font(.subheadline.weight(.semibold))

            Text(LaraL10n.text(
                en: "Double-tap an empty area of the Home Screen or Lock Screen background to lock the device. Icons, the dock and the passcode screen never trigger it.",
                es: "Toca dos veces un área vacía de la pantalla de inicio o de bloqueo para bloquear el dispositivo. Los iconos, el dock y la pantalla de código no lo activan."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(LaraL10n.text(
                en: "Apply starts the SpringBoard RemoteCall session automatically after Prepare, then installs the gesture.",
                es: "Aplicar inicia la sesión RemoteCall de SpringBoard automáticamente tras Prepare y luego instala el gesto."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(LaraL10n.text(
                en: "The gesture lives in SpringBoard until it restarts. Tap Respring to restart and clear it; tap Apply again afterwards to reinstall.",
                es: "El gesto vive en SpringBoard hasta que se reinicie. Toca Reiniciar para reiniciarlo y eliminarlo; después toca Aplicar de nuevo para reinstalarlo."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Actions

    private func respringNow() {
        // Same approach as RemoteView's "Respring" tool: terminate SpringBoard
        // through the live RemoteCall session and let launchd bring it back.
        // A SpringBoard restart clears the injected gesture, so mirror that in
        // the persisted flag.
        performWithSession { _ in
            self.doubleTapToLock = false
            _ = self.mgr.rccall(name: "exit", args: [0], timeout: 100)
            self.mgr.logmsg("(rc) respring requested")
        }
    }

    // Runs an action against the SpringBoard RemoteCall session, initializing
    // the session on demand when the exploit succeeded but no session exists
    // yet — so the buttons stay tappable right after Prepare.
    private func performWithSession(_ action: @escaping (RemoteCall) -> Void) {
        if let proc = mgr.sbProc, mgr.rcready {
            action(proc)
            return
        }
        mgr.logmsg("(rc) initializing SpringBoard RemoteCall session on demand...")
        mgr.rcinit(process: "SpringBoard") { ok in
            guard ok, let proc = self.mgr.sbProc, self.mgr.rcready else {
                let error = self.mgr.rcLastError ?? "RemoteCall initialization failed"
                self.mgr.logmsg("(rc) session init failed: \(error)")
                Alertinator.shared.alert(
                    title: "SpringBoard Session Failed",
                    body: error
                )
                return
            }
            action(proc)
        }
    }

    private func applyDoubleTapToLock(_ enabled: Bool) {
        performWithSession { proc in
            self.runDoubleTapToLock(enabled, proc)
        }
    }

    private func runDoubleTapToLock(_ enabled: Bool, _ proc: RemoteCall) {
        busy = true
        mgr.logmsg("(rc) double-tap to lock: \(enabled ? "enabling" : "disabling")...")
        // DoubleTapLockView is a struct (SwiftUI View), so [weak self] is not
        // allowed; capturing the value is safe here because @AppStorage and
        // @State share reference storage with the live view.
        DispatchQueue.global(qos: .userInitiated).async {
            let result = enabled
                ? enable_double_tap_to_lock(proc)
                : disable_double_tap_to_lock(proc)
            DispatchQueue.main.async {
                self.busy = false
                if result == 0 {
                    self.doubleTapToLock = enabled
                    self.mgr.logmsg("(rc) double-tap to lock: \(enabled ? "enabled" : "disabled")")
                    Alertinator.shared.alert(
                        title: enabled
                            ? LaraL10n.text(en: "Double-Tap to Lock Applied", es: "Bloqueo con doble toque aplicado")
                            : LaraL10n.text(en: "Double-Tap to Lock Removed", es: "Bloqueo con doble toque eliminado"),
                        body: enabled
                            ? LaraL10n.text(en: "Double-tap an empty area of the Home Screen or Lock Screen to lock the device.", es: "Toca dos veces un área vacía de Inicio o de bloqueo para bloquear el dispositivo.")
                            : LaraL10n.text(en: "The double-tap gesture was removed from SpringBoard.", es: "El gesto de doble toque se eliminó de SpringBoard.")
                    )
                } else {
                    self.mgr.logmsg("(rc) double-tap to lock failed: \(result)")
                    Alertinator.shared.alert(
                        title: "Double-Tap to Lock Failed",
                        body: "SpringBoard reported failure (\(result))."
                    )
                }
            }
        }
    }
}
