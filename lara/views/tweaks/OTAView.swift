import SwiftUI

struct OTAView: View {
    @ObservedObject var mgr: laramgr
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("eagle.ota.lastVerifiedDisabled")
    private var lastVerifiedDisabled = false
    @AppStorage("eagle.ota.hasVerifiedConfiguration")
    private var hasVerifiedConfiguration = false

    @State private var configuration: EagleLaunchdConfigurationState = .checking
    @State private var isWorking = false
    @State private var actionTargetDisabled: Bool?
    @State private var lastResult: String?
    @State private var refreshGeneration = 0

    private let daemonLabels = [
        "com.apple.mobile.softwareupdated",
        "com.apple.OTATaskingAgent",
        "com.apple.softwareupdateservicesd",
        "com.apple.mobile.NRDUpdated",
    ]

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Text(LaraL10n.text(en: "launchd configuration", es: "Configuración launchd"))
                    Spacer()
                    if configuration.isChecking {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(configurationTitle)
                        .foregroundStyle(configurationColor)
                        .monospaced()
                        .multilineTextAlignment(.trailing)
                }
                .accessibilityElement(children: .combine)

                if case .unavailable(let lastVerifiedDisabled) = configuration {
                    Text(unavailableMessage(lastVerifiedDisabled: lastVerifiedDisabled))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                HeaderLabel(
                    text: LaraL10n.text(en: "Status", es: "Estado"),
                    icon: "antenna.radiowaves.left.and.right"
                )
            } footer: {
                Text(LaraL10n.text(
                    en: "This verifies the saved launchd configuration. A reboot is required before changes become effective.",
                    es: "Esto verifica la configuración guardada de launchd. Se requiere reiniciar para que los cambios sean efectivos."
                ))
            }

            Section {
                Button {
                    apply(disabled: true)
                } label: {
                    if isWorking && actionTargetDisabled == true {
                        progressLabel(LaraL10n.text(en: "Disabling…", es: "Desactivando…"))
                    } else {
                        Text(LaraL10n.text(en: "Disable OTA Updates", es: "Desactivar actualizaciones OTA"))
                    }
                }
                .disabled(
                    isWorking ||
                    configuration.isChecking ||
                    configuration.isConfiguredDisabled
                )

                Button {
                    apply(disabled: false)
                } label: {
                    if isWorking && actionTargetDisabled == false {
                        progressLabel(LaraL10n.text(en: "Enabling…", es: "Activando…"))
                    } else {
                        Text(LaraL10n.text(en: "Enable OTA Updates", es: "Activar actualizaciones OTA"))
                    }
                }
                .disabled(
                    isWorking ||
                    configuration.isChecking ||
                    configuration.isConfiguredEnabled
                )
            } header: {
                HeaderLabel(
                    text: LaraL10n.text(en: "Actions", es: "Acciones"),
                    icon: "wrench.and.screwdriver"
                )
            } footer: {
                Text(LaraL10n.text(
                    en: "Changes launchd's disabled.plist through the existing system operation. Eagle verifies the resulting configuration afterward.",
                    es: "Modifica disabled.plist de launchd mediante la operación existente del sistema. Eagle verifica después la configuración resultante."
                ))
            }
        }
        .navigationTitle(LaraL10n.text(en: "OTA Updates", es: "Actualizaciones OTA"))
        .onAppear(perform: refreshConfiguration)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refreshConfiguration()
            }
        }
        .alert(
            LaraL10n.text(en: "Result", es: "Resultado"),
            isPresented: .constant(lastResult != nil)
        ) {
            Button("OK") { lastResult = nil }
        } message: {
            Text(lastResult ?? "")
        }
    }

    private var configurationTitle: String {
        switch configuration {
        case .checking:
            return LaraL10n.text(en: "Checking…", es: "Verificando…")
        case .configuredEnabled:
            return LaraL10n.text(en: "Enabled", es: "Activada")
        case .configuredDisabled:
            return LaraL10n.text(en: "Disabled", es: "Desactivada")
        case .partial(let disabled, let total):
            return LaraL10n.text(
                en: "Partial \(disabled)/\(total)",
                es: "Parcial \(disabled)/\(total)"
            )
        case .unavailable:
            return LaraL10n.text(en: "Not verified", es: "No verificada")
        }
    }

    private var configurationColor: Color {
        switch configuration {
        case .configuredEnabled: return .green
        case .configuredDisabled: return .red
        case .partial: return .orange
        case .checking, .unavailable: return .secondary
        }
    }

    private func progressLabel(_ title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            ProgressView()
        }
    }

    private func unavailableMessage(lastVerifiedDisabled: Bool?) -> String {
        guard let lastVerifiedDisabled else {
            return LaraL10n.text(
                en: "Could not verify the plist. No verified configuration is available yet.",
                es: "No se pudo verificar el plist. Todavía no hay una configuración verificada."
            )
        }
        return lastVerifiedDisabled
            ? LaraL10n.text(
                en: "Could not verify the plist. Last verified configuration: disabled.",
                es: "No se pudo verificar el plist. Última configuración verificada: desactivada."
            )
            : LaraL10n.text(
                en: "Could not verify the plist. Last verified configuration: enabled.",
                es: "No se pudo verificar el plist. Última configuración verificada: activada."
            )
    }

    private func refreshConfiguration() {
        guard !isWorking else { return }
        refreshGeneration += 1
        let generation = refreshGeneration
        let cachedValue = hasVerifiedConfiguration ? lastVerifiedDisabled : nil
        let labels = daemonLabels
        configuration = .checking

        DispatchQueue.global(qos: .userInitiated).async {
            let readback = EagleLaunchdConfigurationReader.read(labels: labels)
            DispatchQueue.main.async {
                guard generation == refreshGeneration else { return }
                if let readback {
                    configuration = readback
                    if readback.isConfiguredDisabled {
                        lastVerifiedDisabled = true
                        hasVerifiedConfiguration = true
                    } else if readback.isConfiguredEnabled {
                        lastVerifiedDisabled = false
                        hasVerifiedConfiguration = true
                    }
                } else {
                    configuration = .unavailable(lastKnownDisabled: cachedValue)
                }
            }
        }
    }

    private func apply(disabled: Bool) {
        refreshGeneration += 1
        isWorking = true
        actionTargetDisabled = disabled
        DispatchQueue.global(qos: .userInitiated).async {
            let succeeded = ota_set_disabled(disabled)
            DispatchQueue.main.async {
                isWorking = false
                actionTargetDisabled = nil
                lastResult = succeeded
                    ? LaraL10n.text(
                        en: "The request completed. Eagle is verifying the saved configuration. Reboot to apply it.",
                        es: "La solicitud terminó. Eagle está verificando la configuración guardada. Reinicia para aplicarla."
                    )
                    : LaraL10n.text(
                        en: "The operation reported a failure. Eagle will still check for partial changes.",
                        es: "La operación informó un fallo. Eagle comprobará si hubo cambios parciales."
                    )
                refreshConfiguration()
            }
        }
    }
}
