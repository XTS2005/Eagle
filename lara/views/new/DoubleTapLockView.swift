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
/// Passcode-style interaction: fixed "Apply" / "Turn Off" buttons (labels never
/// flip), the shared Prepare card while access is not ready yet, and feedback
/// via alerts plus the status banner. Turning the gesture off needs no respring.
struct DoubleTapLockView: View {
    @ObservedObject var mgr: laramgr
    @AppStorage("doubleTapToLock") private var doubleTapToLock: Bool = false
    @State private var busy: Bool = false

    private var sessionReady: Bool {
        mgr.rcready && mgr.sbProc != nil
    }

    private var controlsDisabled: Bool {
        !mgr.dsready || busy || mgr.rcrunning
            || mgr.dsrunning || mgr.vfsrunning || mgr.sbxrunning
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusBanner
                if !mgr.sbxready {
                    // Reuse the exact same Prepare card as the Access tab so
                    // the exploit entry looks and behaves identically.
                    LaraAccessView(compact: true)
                }
                applyButton
                turnOffButton
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
            ? LaraL10n.text(en: "Applied", es: "Aplicado")
            : LaraL10n.text(en: "Not applied", es: "No aplicado")
    }

    private var statusSubtitle: String {
        if !mgr.dsready {
            return LaraL10n.text(
                en: "Run Prepare below — the buttons unlock once the exploit succeeds.",
                es: "Ejecuta Prepare abajo — los botones se desbloquean tras el exploit."
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

    // Fixed buttons, Passcode-style: "Apply" installs the gesture and "Turn
    // Off" removes it right away (no respring needed). The labels never flip;
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
        .disabled(controlsDisabled)
        .accessibilityHint(LaraL10n.text(
            en: "Installs the double-tap gesture into SpringBoard.",
            es: "Instala el gesto de doble toque en SpringBoard."
        ))
    }

    private var turnOffButton: some View {
        Button(role: .destructive) {
            applyDoubleTapToLock(false)
        } label: {
            HStack(spacing: 10) {
                if busy {
                    ProgressView()
                        .tint(.white)
                }
                Text(LaraL10n.text(en: "Turn Off", es: "Apagar"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(controlsDisabled)
        .accessibilityHint(LaraL10n.text(
            en: "Removes the double-tap gesture from SpringBoard without respringing.",
            es: "Elimina el gesto de doble toque de SpringBoard sin reiniciar."
        ))
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
                en: "Prepare runs the exploit once; Apply then starts the SpringBoard RemoteCall session automatically and installs the gesture.",
                es: "Prepare ejecuta el exploit una vez; Aplicar inicia entonces la sesión RemoteCall de SpringBoard automáticamente e instala el gesto."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(LaraL10n.text(
                en: "Turn Off removes the gesture right away — no respring and no restart needed. Tap Apply again afterwards to reinstall it.",
                es: "Apagar elimina el gesto al instante — sin respring ni reinicio. Toca Aplicar de nuevo después para reinstalarlo."
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
                    body: "\(error)\n\n"
                        + "Kernel read/write looks unavailable. Run Prepare again "
                        + "(Access tab) to refresh it, then tap Apply.",
                    actionLabel: LaraL10n.text(en: "Try Again", es: "Reintentar"),
                    action: { self.performWithSession(action) }
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
                            : LaraL10n.text(en: "Double-Tap to Lock Turned Off", es: "Bloqueo con doble toque apagado"),
                        body: enabled
                            ? LaraL10n.text(en: "Double-tap an empty area of the Home Screen or Lock Screen to lock the device.", es: "Toca dos veces un área vacía de Inicio o de bloqueo para bloquear el dispositivo.")
                            : LaraL10n.text(en: "The double-tap gesture was removed from SpringBoard.", es: "El gesto de doble toque se eliminó de SpringBoard.")
                    )
                } else {
                    self.mgr.logmsg("(rc) double-tap to lock failed: \(result)")
                    let detail = proc.lastError ?? ""
                    let message = detail.isEmpty
                        ? "SpringBoard reported failure (\(result))."
                        : "SpringBoard reported failure (\(result)). \(detail)"
                    Alertinator.shared.alert(
                        title: "Double-Tap to Lock Failed",
                        body: message
                    )
                }
            }
        }
    }
}
