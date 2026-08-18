import SwiftUI

struct ScreenTimeView: View {
    @ObservedObject var mgr: laramgr
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("eagle.screentime.lastVerifiedDisabled")
    private var lastVerifiedDisabled = false
    @AppStorage("eagle.screentime.hasVerifiedConfiguration")
    private var hasVerifiedConfiguration = false

    @State private var killScreenTimeAgent = true
    @State private var killUsageTrackingAgent = true
    @State private var killHomed = false
    @State private var killFamilycircled = false
    @State private var configuration: EagleLaunchdConfigurationState = .checking
    @State private var backupState: EagleFileExistenceState = .checking
    @State private var isWorking = false
    @State private var actionTargetDisabled: Bool?
    @State private var lastResult: String?
    @State private var refreshGeneration = 0

    private let primaryDaemonLabels = [
        "com.apple.ScreenTimeAgent",
        "com.apple.UsageTrackingAgent",
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

                HStack {
                    Text(LaraL10n.text(en: "Preferences backup", es: "Copia de preferencias"))
                    Spacer()
                    if backupState == .checking {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(backupTitle)
                        .foregroundStyle(backupState == .found ? Color.green : Color.secondary)
                        .monospaced()
                }

                if case .unavailable(let lastVerifiedDisabled) = configuration {
                    Text(unavailableMessage(lastVerifiedDisabled: lastVerifiedDisabled))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                HeaderLabel(
                    text: LaraL10n.text(en: "Status", es: "Estado"),
                    icon: "hourglass"
                )
            } footer: {
                Text(LaraL10n.text(
                    en: "This verifies the two primary launchd entries. A reboot is required before changes become effective.",
                    es: "Esto verifica las dos entradas principales de launchd. Se requiere reiniciar para que los cambios sean efectivos."
                ))
            }

            Section {
                Toggle("ScreenTimeAgent", isOn: $killScreenTimeAgent)
                    .disabled(isWorking || configuration.isConfiguredDisabled)
                Toggle("UsageTrackingAgent", isOn: $killUsageTrackingAgent)
                    .disabled(isWorking || configuration.isConfiguredDisabled)
                Toggle("Homed", isOn: $killHomed)
                    .disabled(isWorking || configuration.isConfiguredDisabled)
                Toggle("Familycircled", isOn: $killFamilycircled)
                    .disabled(isWorking || configuration.isConfiguredDisabled)
            } header: {
                HeaderLabel(
                    text: LaraL10n.text(en: "Daemons", es: "Procesos del sistema"),
                    icon: "gearshape.2"
                )
            } footer: {
                Text(LaraL10n.text(
                    en: "ScreenTimeAgent and UsageTrackingAgent are both required to disable Screen Time. Homed and Familycircled are optional.",
                    es: "ScreenTimeAgent y UsageTrackingAgent son necesarios para desactivar Tiempo en Pantalla. Homed y Familycircled son opcionales."
                ))
            }

            Section {
                Button {
                    applyDisable()
                } label: {
                    if isWorking && actionTargetDisabled == true {
                        progressLabel(LaraL10n.text(en: "Disabling…", es: "Desactivando…"))
                    } else {
                        Text(LaraL10n.text(en: "Disable Screen Time", es: "Desactivar Tiempo en Pantalla"))
                    }
                }
                .disabled(
                    isWorking ||
                    configuration.isChecking ||
                    configuration.isConfiguredDisabled
                )

                Button {
                    applyEnable()
                } label: {
                    if isWorking && actionTargetDisabled == false {
                        progressLabel(LaraL10n.text(en: "Enabling…", es: "Activando…"))
                    } else {
                        Text(LaraL10n.text(en: "Enable Screen Time", es: "Activar Tiempo en Pantalla"))
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
                    en: "Uses the existing Screen Time operation, then verifies the resulting launchd configuration.",
                    es: "Usa la operación existente de Tiempo en Pantalla y después verifica la configuración resultante de launchd."
                ))
            }
        }
        .navigationTitle(LaraL10n.text(en: "Screen Time", es: "Tiempo en Pantalla"))
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

    private var backupTitle: String {
        switch backupState {
        case .checking:
            return LaraL10n.text(en: "Checking…", es: "Verificando…")
        case .found:
            return LaraL10n.text(en: "Found", es: "Encontrada")
        case .notFound:
            return LaraL10n.text(en: "Not found", es: "No encontrada")
        case .unavailable:
            return LaraL10n.text(en: "Not verified", es: "No verificada")
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
        let labels = primaryDaemonLabels
        configuration = .checking
        backupState = .checking

        DispatchQueue.global(qos: .userInitiated).async {
            let readback = EagleLaunchdConfigurationReader.read(labels: labels)
            let backup = EagleLaunchdConfigurationReader.fileExistence(
                atPath: "/var/mobile/Library/Preferences/com.apple.ScreenTimeAgent.plist.bak"
            )
            DispatchQueue.main.async {
                guard generation == refreshGeneration else { return }
                backupState = backup
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

    private func applyDisable() {
        refreshGeneration += 1
        isWorking = true
        actionTargetDisabled = true
        let agent = killScreenTimeAgent
        let usage = killUsageTrackingAgent
        let homed = killHomed
        let family = killFamilycircled

        DispatchQueue.global(qos: .userInitiated).async {
            let succeeded = screentime_disable(agent, usage, homed, family)
            DispatchQueue.main.async {
                finishOperation(succeeded: succeeded)
            }
        }
    }

    private func applyEnable() {
        refreshGeneration += 1
        isWorking = true
        actionTargetDisabled = false
        DispatchQueue.global(qos: .userInitiated).async {
            let succeeded = screentime_enable()
            DispatchQueue.main.async {
                finishOperation(succeeded: succeeded)
            }
        }
    }

    private func finishOperation(succeeded: Bool) {
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
