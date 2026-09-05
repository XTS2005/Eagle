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
struct DoubleTapLockView: View {
    @ObservedObject var mgr: laramgr
    @AppStorage("doubleTapToLock") private var doubleTapToLock: Bool = false
    @State private var busy: Bool = false

    var body: some View {
        List {
            Section {
                Toggle(
                    LaraL10n.text(en: "Double-Tap to Lock", es: "Bloquear con doble toque"),
                    isOn: Binding(
                        get: { doubleTapToLock },
                        set: { newValue in
                            guard newValue != doubleTapToLock, !busy else { return }
                            doubleTapToLock = newValue
                            applyDoubleTapToLock(newValue)
                        }
                    )
                )
                .disabled(!mgr.rcready || busy || mgr.rcrunning)
            } header: {
                HeaderLabel(
                    text: LaraL10n.text(en: "Gesture", es: "Gesto"),
                    icon: "hand.tap.fill"
                )
            } footer: {
                Text(LaraL10n.text(
                    en: "Double-tap an empty area of the Home Screen or Lock Screen background to lock the device. Icons, the dock and the passcode screen never trigger it.",
                    es: "Toca dos veces un área vacía de la pantalla de inicio o de bloqueo para bloquear el dispositivo. Los iconos, el dock y la pantalla de código no lo activan."
                ))
            }

            Section {
                if mgr.rcready {
                    Label(
                        LaraL10n.text(
                            en: "SpringBoard RemoteCall session is ready",
                            es: "La sesión RemoteCall de SpringBoard está lista"
                        ),
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                } else {
                    Label(
                        LaraL10n.text(
                            en: "RemoteCall is not initialized — run Prepare first",
                            es: "RemoteCall no está inicializado — ejecuta Prepare primero"
                        ),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
                Text(LaraL10n.text(
                    en: "The gesture survives SpringBoard until it restarts; toggle off and on again after a respring to reinstall it.",
                    es: "El gesto dura hasta que SpringBoard se reinicie; desactívalo y actívalo de nuevo tras un respring para reinstalarlo."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            } header: {
                HeaderLabel(
                    text: LaraL10n.text(en: "Status", es: "Estado"),
                    icon: "info.circle"
                )
            }
        }
        .navigationTitle(LaraL10n.text(
            en: "Double-Tap to Lock",
            es: "Bloqueo con doble toque"
        ))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func applyDoubleTapToLock(_ enabled: Bool) {
        guard mgr.rcready, let proc = mgr.sbProc else {
            doubleTapToLock = !enabled
            Alertinator.shared.alert(
                title: "RemoteCall Not Ready",
                body: "Initialize the SpringBoard RemoteCall session before enabling Double-Tap to Lock."
            )
            return
        }
        busy = true
        mgr.logmsg("(rc) double-tap to lock: \(enabled ? "enabling" : "disabling")...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = enabled
                ? enable_double_tap_to_lock(proc)
                : disable_double_tap_to_lock(proc)
            DispatchQueue.main.async {
                guard let self else { return }
                self.busy = false
                if result == 0 {
                    self.mgr.logmsg("(rc) double-tap to lock: \(enabled ? "enabled" : "disabled")")
                } else {
                    self.doubleTapToLock = !enabled
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
