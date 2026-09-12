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
/// Passcode-style interaction: fixed "Apply" / "Disable" buttons (labels never
/// flip), the shared Prepare card while access is not ready yet, and feedback
/// via alerts plus the status card. Disabling needs no respring.
struct DoubleTapLockView: View {
    @ObservedObject var mgr: laramgr
    @Environment(\.colorScheme) private var colorScheme
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
                statusCard
                if !mgr.sbxready {
                    // Reuse the exact same Prepare card as the Access tab so
                    // the exploit entry looks and behaves identically.
                    LaraAccessView(compact: true)
                }
                actions
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

    // MARK: - Status card

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 14) {
            statusIconPlate

            VStack(alignment: .leading, spacing: 5) {
                Text(statusTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(statusSubtitle)
                    .font(.footnote)
                    .foregroundStyle(EagleVisualTheme.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
                statusBadge
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(EagleVisualTheme.surfaceBorder(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: EagleVisualTheme.surfaceShadow(for: colorScheme), radius: 10, y: 4)
    }

    private var statusIconPlate: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: doubleTapToLock
                            ? [Color(red: 0.20, green: 0.78, blue: 0.45),
                               Color(red: 0.10, green: 0.62, blue: 0.60)]
                            : [EagleVisualTheme.accent,
                               EagleVisualTheme.accent.opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: doubleTapToLock ? "hand.tap.fill" : "hand.tap")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 46, height: 46)
        .shadow(
            color: (doubleTapToLock ? Color.green : EagleVisualTheme.accent).opacity(0.28),
            radius: 8,
            y: 3
        )
        .accessibilityHidden(true)
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
            : LaraL10n.text(en: "Disabled", es: "Desactivado")
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

    private var statusBadgeColor: Color {
        if !mgr.dsready { return .red }
        if !sessionReady { return .orange }
        return doubleTapToLock ? .green : Color.secondary
    }

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusBadgeColor)
                .frame(width: 6, height: 6)
            Text(statusTitle.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.4)
                .foregroundStyle(statusBadgeColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(statusBadgeColor.opacity(0.12), in: Capsule())
        .accessibilityHidden(true)
    }

    // MARK: - Action buttons

    // Fixed buttons, Passcode-style: "Apply" installs the gesture and "Disable"
    // removes it right away (no respring needed). The labels never flip;
    // feedback comes from the alert after the remote call completes and from
    // the status card.

    private var actions: some View {
        VStack(spacing: 12) {
            applyButton
            disableButton
        }
    }

    private var applyButton: some View {
        Button {
            applyDoubleTapToLock(true)
        } label: {
            HStack(spacing: 9) {
                if busy {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "hand.tap.fill")
                        .font(.subheadline.weight(.semibold))
                }
                Text(LaraL10n.text(en: "Apply", es: "Aplicar"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
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

    private var disableButton: some View {
        Button(role: .destructive) {
            applyDoubleTapToLock(false)
        } label: {
            HStack(spacing: 9) {
                if busy {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "power")
                        .font(.subheadline.weight(.semibold))
                }
                Text(LaraL10n.text(en: "Disable", es: "Desactivar"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
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
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(LaraL10n.text(en: "How it works", es: "Cómo funciona"))
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(EagleVisualTheme.accent)
            }

            infoRow(
                icon: "hand.tap",
                text: LaraL10n.text(
                    en: "Double-tap an empty Home Screen or Lock Screen area to lock. Icons, the dock and the passcode screen never trigger it.",
                    es: "Toca dos veces un área vacía de Inicio o de bloqueo para bloquear. Los iconos, el dock y la pantalla de código no lo activan."
                )
            )

            Divider().opacity(0.4)

            infoRow(
                icon: "wand.and.stars",
                text: LaraL10n.text(
                    en: "Prepare runs the exploit once; Apply then starts the SpringBoard session and installs the gesture automatically.",
                    es: "Prepare ejecuta el exploit una vez; Aplicar inicia la sesión de SpringBoard e instala el gesto automáticamente."
                )
            )

            Divider().opacity(0.4)

            infoRow(
                icon: "power",
                text: LaraL10n.text(
                    en: "Disable removes the gesture instantly — no respring and no restart needed. Tap Apply again afterwards to reinstall it.",
                    es: "Desactivar elimina el gesto al instante — sin respring ni reinicio. Toca Aplicar de nuevo después para reinstalarlo."
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(EagleVisualTheme.surfaceBorder(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: EagleVisualTheme.surfaceShadow(for: colorScheme), radius: 10, y: 4)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(EagleVisualTheme.accent)
                .frame(width: 18)
            Text(text)
                .font(.footnote)
                .foregroundStyle(EagleVisualTheme.secondaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
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
                            : LaraL10n.text(en: "Double-Tap to Lock Disabled", es: "Bloqueo con doble toque desactivado"),
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
