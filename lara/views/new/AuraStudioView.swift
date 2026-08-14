import SwiftUI
import UIKit

private struct AuraStudioNotice: Identifiable {
    let id = UUID()
    let message: String
}

private enum AuraStudioDiagnostics {
    static func log(_ stage: String, _ detail: String = "") {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let suffix = detail.isEmpty ? "" : " \(detail)"
        globallogger.log("[\(formatter.string(from: Date()))] (eagle.aura.apply) stage=\(stage)\(suffix)")
    }
}

@MainActor
private enum AuraStudioApplyGate {
    private static var operationInFlight = false

    static func begin() -> Bool {
        guard !operationInFlight else { return false }
        operationInFlight = true
        return true
    }

    static func end() {
        operationInFlight = false
    }
}

private enum AuraStudioMode: Int, CaseIterable, Identifiable {
    case glow = 1
    case pulse = 2
    case tint = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .glow: return LaraL10n.text(en: "Glow", es: "Brillo")
        case .pulse: return LaraL10n.text(en: "Pulse", es: "Pulso")
        case .tint: return LaraL10n.text(en: "Tint", es: "Color")
        }
    }

    var summary: String {
        switch self {
        case .glow:
            return LaraL10n.text(
                en: "A crisp outline with a focused outer light.",
                es: "Un contorno definido con una luz exterior concentrada."
            )
        case .pulse:
            return LaraL10n.text(
                en: "The selected surfaces breathe gently.",
                es: "Las superficies seleccionadas respiran suavemente."
            )
        case .tint:
            return LaraL10n.text(
                en: "Adds a subtle color wash inside compact surfaces.",
                es: "Añade un tono sutil dentro de las superficies compactas."
            )
        }
    }
}

private struct AuraStudioModule: Identifiable {
    let id: UInt32
    let title: String
    let subtitle: String
    let symbol: String
}

struct AuraStudioView: View {
    private enum Flag {
        static let island: UInt32 = 1 << 0
        static let screen: UInt32 = 1 << 1
        static let battery: UInt32 = 1 << 2
        static let volume: UInt32 = 1 << 3
        static let notification: UInt32 = 1 << 4
        static let dock: UInt32 = 1 << 5
        static let lock: UInt32 = 1 << 6
    }

    @ObservedObject private var mgr = laramgr.shared

    @AppStorage("eagle.islandAura.red") private var red = 0.10
    @AppStorage("eagle.islandAura.green") private var green = 0.78
    @AppStorage("eagle.islandAura.blue") private var blue = 1.0
    @AppStorage("eagle.auraStudio.mode") private var selectedModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0

    @AppStorage("eagle.auraStudio.island") private var islandEnabled = true
    @AppStorage("eagle.auraStudio.screen") private var screenEnabled = true
    @AppStorage("eagle.auraStudio.battery") private var batteryEnabled = true
    @AppStorage("eagle.auraStudio.volume") private var volumeEnabled = false
    @AppStorage("eagle.auraStudio.notification") private var notificationEnabled = false
    @AppStorage("eagle.auraStudio.dock") private var dockEnabled = false
    @AppStorage("eagle.auraStudio.lock") private var lockEnabled = false

    @State private var isApplying = false
    @State private var previewPulse = false
    @State private var notice: AuraStudioNotice?

    private var selectedMode: AuraStudioMode {
        get { AuraStudioMode(rawValue: selectedModeRaw) ?? .glow }
        nonmutating set { selectedModeRaw = newValue.rawValue }
    }

    private var auraColor: Color {
        Color(red: red, green: green, blue: blue)
    }

    private var selectedFlags: UInt32 {
        var flags: UInt32 = 0
        if islandEnabled { flags |= Flag.island }
        if screenEnabled { flags |= Flag.screen }
        if batteryEnabled { flags |= Flag.battery }
        if volumeEnabled { flags |= Flag.volume }
        if notificationEnabled { flags |= Flag.notification }
        if dockEnabled { flags |= Flag.dock }
        if lockEnabled { flags |= Flag.lock }
        return flags
    }

    private var auraColorBinding: Binding<Color> {
        Binding(
            get: { auraColor },
            set: { color in
                let resolved = UIColor(color)
                var nextRed: CGFloat = 0
                var nextGreen: CGFloat = 0
                var nextBlue: CGFloat = 0
                var alpha: CGFloat = 0
                guard resolved.getRed(
                    &nextRed,
                    green: &nextGreen,
                    blue: &nextBlue,
                    alpha: &alpha
                ) else { return }
                red = Double(nextRed)
                green = Double(nextGreen)
                blue = Double(nextBlue)
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                previewCard
                appearanceCard
                alwaysOnCard
                systemMomentsCard
                adaptiveNote

                if !mgr.dsready {
                    LaraAccessView(compact: true)
                }

                applyButton
                restoreButton
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Aura Studio")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $notice) { notice in
            Alert(
                title: Text("Aura Studio"),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if isApplying {
                ZStack {
                    Color.black.opacity(0.14).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(LaraL10n.text(
                            en: "Building your system aura…",
                            es: "Creando tu aura del sistema…"
                        ))
                        .font(.headline)
                    }
                    .padding(22)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                previewPulse = true
            }
        }
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 5) {
                Text(LaraL10n.text(en: "One color. One Apply.", es: "Un color. Un solo Apply."))
                    .font(.title2.bold())
                Text(LaraL10n.text(
                    en: "Choose where the light appears without filling Eagle with separate tools.",
                    es: "Elige dónde aparece la luz sin llenar Eagle de herramientas separadas."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.025, green: 0.035, blue: 0.07),
                        auraColor.opacity(0.18),
                        Color(red: 0.018, green: 0.02, blue: 0.04),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if screenEnabled {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(auraColor, lineWidth: 2.2)
                        .padding(5)
                        .shadow(color: auraColor.opacity(0.9), radius: 9)
                }

                VStack {
                    HStack {
                        Text("9:41")
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "cellularbars")
                            Image(systemName: "wifi")
                            Image(systemName: "battery.75percent")
                                .padding(.horizontal, batteryEnabled ? 4 : 0)
                                .padding(.vertical, batteryEnabled ? 3 : 0)
                                .overlay {
                                    if batteryEnabled {
                                        Capsule()
                                            .stroke(auraColor, lineWidth: 1.5)
                                            .shadow(color: auraColor, radius: 5)
                                    }
                                }
                        }
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    if notificationEnabled {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(auraColor.gradient)
                                .frame(width: 30, height: 30)
                            VStack(alignment: .leading, spacing: 4) {
                                Capsule().fill(.white.opacity(0.75)).frame(width: 82, height: 5)
                                Capsule().fill(.white.opacity(0.34)).frame(width: 118, height: 4)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(.black.opacity(0.62))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(auraColor, lineWidth: 1.6)
                        }
                        .shadow(color: auraColor.opacity(0.8), radius: 8)
                    }

                    Spacer()

                    if dockEnabled {
                        HStack(spacing: 9) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill([Color.blue, .green, .purple, .orange][index].gradient)
                                    .frame(width: 31, height: 31)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(auraColor, lineWidth: 1.5)
                        }
                        .shadow(color: auraColor.opacity(0.7), radius: 7)
                    }
                }
                .padding(14)

                if islandEnabled {
                    Capsule()
                        .fill(selectedMode == .tint ? auraColor.opacity(0.28) : .black)
                        .frame(width: 94, height: 28)
                        .overlay { Capsule().stroke(auraColor, lineWidth: 1.8) }
                        .shadow(color: auraColor, radius: 8)
                        .opacity(selectedMode == .pulse ? (previewPulse ? 1 : 0.55) : 1)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 7)
                }
            }
            .frame(height: 238)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            HStack(spacing: 7) {
                Circle()
                    .fill(activeFlagsRaw == 0 ? Color.secondary.opacity(0.5) : Color.green)
                    .frame(width: 8, height: 8)
                Text(activeFlagsRaw == 0
                     ? LaraL10n.text(en: "No active verified aura", es: "Sin aura activa verificada")
                     : LaraL10n.text(en: "Last Apply installed \(activeModuleCount) surfaces", es: "El último Apply instaló \(activeModuleCount) superficies"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(LaraL10n.text(en: "Light Style", es: "Estilo de luz"))
                .font(.headline)

            Picker(
                LaraL10n.text(en: "Light Style", es: "Estilo de luz"),
                selection: Binding(get: { selectedMode }, set: { selectedMode = $0 })
            ) {
                ForEach(AuraStudioMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedMode.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            ColorPicker(
                LaraL10n.text(en: "Aura color", es: "Color del aura"),
                selection: auraColorBinding,
                supportsOpacity: false
            )
            .font(.subheadline.weight(.semibold))

            HStack(spacing: 11) {
                ForEach(presets, id: \.name) { preset in
                    Button {
                        red = preset.red
                        green = preset.green
                        blue = preset.blue
                    } label: {
                        Circle()
                            .fill(Color(red: preset.red, green: preset.green, blue: preset.blue))
                            .frame(width: 32, height: 32)
                            .overlay { Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1) }
                            .shadow(
                                color: Color(red: preset.red, green: preset.green, blue: preset.blue).opacity(0.6),
                                radius: 6
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.name)
                }
                Spacer()
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var alwaysOnCard: some View {
        moduleCard(
            title: LaraL10n.text(en: "Core Aura", es: "Aura principal"),
            modules: [
                AuraStudioModule(
                    id: Flag.island,
                    title: "Island Aura",
                    subtitle: LaraL10n.text(en: "Adaptive Dynamic Island outline", es: "Contorno adaptable de Dynamic Island"),
                    symbol: "capsule.fill"
                ),
                AuraStudioModule(
                    id: Flag.screen,
                    title: "Screen Aura",
                    subtitle: LaraL10n.text(en: "A non-interactive edge around the display", es: "Un borde que no bloquea toques"),
                    symbol: "rectangle.inset.filled"
                ),
                AuraStudioModule(
                    id: Flag.battery,
                    title: "Battery Halo",
                    subtitle: LaraL10n.text(en: "A global halo around the battery area", es: "Un halo global alrededor de la batería"),
                    symbol: "battery.75percent"
                ),
            ]
        )
    }

    private var systemMomentsCard: some View {
        moduleCard(
            title: LaraL10n.text(en: "System Moments", es: "Momentos del sistema"),
            modules: [
                AuraStudioModule(
                    id: Flag.volume,
                    title: "Volume Aura",
                    subtitle: LaraL10n.text(en: "Lights with the system volume HUD", es: "Se muestra con el volumen del sistema"),
                    symbol: "speaker.wave.2.fill"
                ),
                AuraStudioModule(
                    id: Flag.notification,
                    title: "Notification Aura",
                    subtitle: LaraL10n.text(en: "A neon frame for incoming banners", es: "Un marco neón para notificaciones"),
                    symbol: "bell.badge.fill"
                ),
                AuraStudioModule(
                    id: Flag.dock,
                    title: "Dock Aura",
                    subtitle: LaraL10n.text(en: "A focused light around the Home Screen Dock", es: "Luz alrededor del Dock de inicio"),
                    symbol: "dock.rectangle"
                ),
                AuraStudioModule(
                    id: Flag.lock,
                    title: "Lock Aura",
                    subtitle: LaraL10n.text(en: "A lock-screen halo near Face ID", es: "Un halo de bloqueo junto a Face ID"),
                    symbol: "lock.fill"
                ),
            ]
        )
    }

    private func moduleCard(title: String, modules: [AuraStudioModule]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(Array(modules.enumerated()), id: \.element.id) { index, module in
                if index > 0 { Divider().padding(.leading, 44) }
                HStack(spacing: 12) {
                    Image(systemName: module.symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(auraColor)
                        .frame(width: 32, height: 32)
                        .background(auraColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(module.title).font(.subheadline.weight(.semibold))
                        Text(module.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    Toggle("", isOn: binding(for: module.id))
                        .labelsHidden()
                        .tint(auraColor)
                }
                .padding(.vertical, 10)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var adaptiveNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "waveform.path.ecg.rectangle.fill")
                .foregroundStyle(auraColor)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(LaraL10n.text(en: "Adaptive signals are next", es: "Las señales adaptativas serán lo próximo"))
                    .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "Privacy Aura and Charging Aura need a persistent event bridge so they react only when the camera, microphone, recording, or charging state actually changes. They will live here—not as extra Home Screen tools.",
                    es: "Privacy Aura y Charging Aura necesitan un puente persistente de eventos para reaccionar solo cuando cambie realmente la cámara, el micrófono, la grabación o la carga. Vivirán aquí, no como herramientas adicionales en Inicio."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var applyButton: some View {
        Button { apply(mode: selectedMode.rawValue, flags: selectedFlags) } label: {
            Label(
                LaraL10n.text(en: "Apply Aura Studio", es: "Aplicar Aura Studio"),
                systemImage: "sparkles"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(auraColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isApplying || selectedFlags == 0)
    }

    private var restoreButton: some View {
        Button { apply(mode: 0, flags: 0) } label: {
            Label(
                LaraL10n.text(en: "Remove Every Aura", es: "Eliminar todas las auras"),
                systemImage: "arrow.counterclockwise"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(isApplying)
    }

    private var presets: [(name: String, red: Double, green: Double, blue: Double)] {
        [
            ("Electric", 0.10, 0.78, 1.00),
            ("Ultra Violet", 0.62, 0.25, 1.00),
            ("Hot Pink", 1.00, 0.16, 0.62),
            ("Acid", 0.42, 1.00, 0.24),
        ]
    }

    private var activeModuleCount: Int {
        UInt32(max(activeFlagsRaw, 0)).nonzeroBitCount
    }

    private func binding(for flag: UInt32) -> Binding<Bool> {
        switch flag {
        case Flag.island: return $islandEnabled
        case Flag.screen: return $screenEnabled
        case Flag.battery: return $batteryEnabled
        case Flag.volume: return $volumeEnabled
        case Flag.notification: return $notificationEnabled
        case Flag.dock: return $dockEnabled
        default: return $lockEnabled
        }
    }

    private func apply(mode: Int, flags: UInt32) {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        AuraStudioDiagnostics.log(
            "request",
            "mode=\(mode) flags=0x\(String(flags, radix: 16)) device=\(devicemachine()) ios=\(versionString) " +
            "dsready=\(mgr.dsready) rcrunning=\(mgr.rcrunning) rcready=\(mgr.rcready) session=\(mgr.sbProc != nil)"
        )

        guard !isApplying, AuraStudioApplyGate.begin() else {
            AuraStudioDiagnostics.log("rejected", "reason=already-applying")
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Aura Studio is still finishing the previous system update.",
                es: "Aura Studio todavía está terminando la actualización anterior."
            ))
            return
        }
        guard !isdebugged() else {
            finish(message: LaraL10n.text(
                en: "Stop the Xcode run and open Eagle manually from the Home Screen before changing SpringBoard.",
                es: "Detén la ejecución en Xcode y abre Eagle manualmente desde Inicio antes de modificar SpringBoard."
            ))
            return
        }
        guard version.majorVersion == 17 || version.majorVersion == 18 else {
            finish(message: LaraL10n.text(
                en: "Aura Studio currently targets the verified iOS 17 and 18 SpringBoard surfaces.",
                es: "Aura Studio utiliza actualmente las superficies verificadas de SpringBoard en iOS 17 y 18."
            ))
            return
        }
        guard mgr.dsready else {
            finish(message: LaraL10n.text(
                en: "Prepare Eagle access before applying system auras.",
                es: "Prepara el acceso de Eagle antes de aplicar auras del sistema."
            ))
            return
        }

        isApplying = true
        let applyWithSession = {
            guard let process = self.mgr.sbProc else {
                self.finish(message: LaraL10n.text(
                    en: "Eagle connected to SpringBoard but did not receive a live session.",
                    es: "Eagle se conectó a SpringBoard, pero no recibió una sesión activa."
                ))
                return
            }
            let redValue = Int32(max(0, min(255, Int((self.red * 255).rounded()))))
            let greenValue = Int32(max(0, min(255, Int((self.green * 255).rounded()))))
            let blueValue = Int32(max(0, min(255, Int((self.blue * 255).rounded()))))
            AuraStudioDiagnostics.log(
                "session.ready",
                "pid=\(process.pid) isolatedThread=\(process.creatingExtraThread) mode=\(mode) flags=0x\(String(flags, radix: 16))"
            )

            DispatchQueue.global(qos: .userInitiated).async {
                AuraStudioDiagnostics.log("native-call.begin")
                let result = autoreleasepool {
                    eagle_set_aura_studio(
                        process,
                        redValue,
                        greenValue,
                        blueValue,
                        Int32(mode),
                        flags
                    )
                }
                AuraStudioDiagnostics.log("native-call.end", "result=\(result)")
                DispatchQueue.main.async {
                    AuraStudioApplyGate.end()
                    self.isApplying = false
                    if result >= 0 {
                        self.activeFlagsRaw = Int(result)
                        self.notice = AuraStudioNotice(
                            message: self.successMessage(
                                appliedFlags: UInt32(result),
                                requestedFlags: flags,
                                restoring: mode == 0
                            )
                        )
                    } else {
                        self.notice = AuraStudioNotice(message: self.message(for: result))
                    }
                }
            }
        }

        if mgr.rcready, mgr.sbProc != nil {
            AuraStudioDiagnostics.log("session.reuse")
            applyWithSession()
        } else {
            AuraStudioDiagnostics.log("session.init.begin", "process=SpringBoard")
            mgr.rcinit(process: "SpringBoard") { success in
                AuraStudioDiagnostics.log(
                    "session.init.end",
                    "success=\(success) rcready=\(self.mgr.rcready) session=\(self.mgr.sbProc != nil)"
                )
                if success || (self.mgr.rcready && self.mgr.sbProc != nil) {
                    applyWithSession()
                } else {
                    let detail = self.mgr.rcLastError?.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.finish(message: detail?.isEmpty == false
                        ? detail!
                        : LaraL10n.text(
                            en: "Eagle could not start the live SpringBoard session.",
                            es: "Eagle no pudo iniciar la sesión activa con SpringBoard."
                        ))
                }
            }
        }
    }

    private func finish(message: String) {
        AuraStudioDiagnostics.log("finish", "error=true")
        DispatchQueue.main.async {
            AuraStudioApplyGate.end()
            self.isApplying = false
            self.notice = AuraStudioNotice(message: message)
        }
    }

    private func successMessage(
        appliedFlags: UInt32,
        requestedFlags: UInt32,
        restoring: Bool
    ) -> String {
        if restoring {
            return LaraL10n.text(
                en: "Every Eagle aura was removed.",
                es: "Se eliminaron todas las auras de Eagle."
            )
        }
        let applied = names(for: appliedFlags)
        let missing = names(for: requestedFlags & ~appliedFlags)
        if missing.isEmpty {
            return LaraL10n.text(
                en: "Applied and verified: \(applied.joined(separator: ", ")).",
                es: "Aplicado y verificado: \(applied.joined(separator: ", "))."
            )
        }
        return LaraL10n.text(
            en: "Applied: \(applied.joined(separator: ", ")). Unavailable on the current SpringBoard state: \(missing.joined(separator: ", ")). No unavailable surface was reported as active.",
            es: "Aplicado: \(applied.joined(separator: ", ")). No disponible en el estado actual de SpringBoard: \(missing.joined(separator: ", ")). Ninguna superficie ausente se marcó como activa."
        )
    }

    private func message(for result: Int32) -> String {
        switch result {
        case -2:
            return LaraL10n.text(
                en: "SpringBoard did not expose any selected Aura Studio host. Nothing was reported as applied.",
                es: "SpringBoard no mostró ningún contenedor seleccionado de Aura Studio. No se marcó nada como aplicado."
            )
        case -3:
            return LaraL10n.text(en: "The selected aura style is invalid.", es: "El estilo de aura seleccionado no es válido.")
        case -4:
            return LaraL10n.text(
                en: "The SpringBoard session did not provide an isolated call thread.",
                es: "La sesión de SpringBoard no proporcionó un hilo aislado de llamadas."
            )
        case -5:
            return LaraL10n.text(
                en: "This iOS version is outside Aura Studio's verified range.",
                es: "Esta versión de iOS está fuera del rango verificado de Aura Studio."
            )
        case -6:
            return LaraL10n.text(
                en: "SpringBoard could not create the selected aura color.",
                es: "SpringBoard no pudo crear el color de aura seleccionado."
            )
        case -7:
            return LaraL10n.text(
                en: "Aura Studio caught a system exception and stopped without reporting success.",
                es: "Aura Studio detectó una excepción del sistema y se detuvo sin mostrar un éxito falso."
            )
        default:
            return LaraL10n.text(
                en: "SpringBoard rejected the Aura Studio update.",
                es: "SpringBoard rechazó la actualización de Aura Studio."
            )
        }
    }

    private func names(for flags: UInt32) -> [String] {
        var names: [String] = []
        if flags & Flag.island != 0 { names.append("Island") }
        if flags & Flag.screen != 0 { names.append("Screen") }
        if flags & Flag.battery != 0 { names.append("Battery Halo") }
        if flags & Flag.volume != 0 { names.append("Volume") }
        if flags & Flag.notification != 0 { names.append("Notifications") }
        if flags & Flag.dock != 0 { names.append("Dock") }
        if flags & Flag.lock != 0 { names.append("Lock") }
        return names
    }
}
