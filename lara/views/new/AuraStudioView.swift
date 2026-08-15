import SwiftUI
import UIKit

private struct AuraStudioNotice: Identifiable {
    let id = UUID()
    let message: String
}

struct AuraStudioDisplayGeometry {
    let logicalSize: CGSize
    let nativePixelSize: CGSize
    let standardLogicalSize: CGSize
    let renderScale: CGFloat
    let nativeScale: CGFloat
    let xFactor: CGFloat
    let yFactor: CGFloat
    let isDisplayZoomed: Bool

    func scaleStandardFrame(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.origin.x * xFactor,
            y: frame.origin.y * yFactor,
            width: frame.width * xFactor,
            height: frame.height * yFactor
        )
    }

    var compactIslandFrame: CGRect {
        scaleStandardFrame(CGRect(
            x: (standardLogicalSize.width - 132) / 2,
            y: 12,
            width: 132,
            height: 37
        ))
    }

    var dockAuraFrame: CGRect {
        scaleStandardFrame(CGRect(
            x: 15,
            y: 1,
            width: standardLogicalSize.width - 30,
            height: 94
        ))
    }

    static var current: AuraStudioDisplayGeometry {
        let screen = UIScreen.main
        let logical = CGSize(
            width: min(screen.bounds.width, screen.bounds.height),
            height: max(screen.bounds.width, screen.bounds.height)
        )
        let native = CGSize(
            width: min(screen.nativeBounds.width, screen.nativeBounds.height),
            height: max(screen.nativeBounds.width, screen.nativeBounds.height)
        )
        let renderScale = max(screen.scale, 1)
        let nativeScale = max(screen.nativeScale, 1)
        let standard = CGSize(
            width: native.width / renderScale,
            height: native.height / renderScale
        )
        let rawX = standard.width > 0 ? logical.width / standard.width : 1
        let rawY = standard.height > 0 ? logical.height / standard.height : 1
        var xFactor = (0.75...1.015).contains(rawX) ? rawX : 1
        var yFactor = (0.75...1.015).contains(rawY) ? rawY : 1
        if xFactor >= 0.985,
           yFactor >= 0.985,
           nativeScale > renderScale * 1.015 {
            let uniformFactor = renderScale / nativeScale
            if (0.75..<0.985).contains(uniformFactor) {
                xFactor = uniformFactor
                yFactor = uniformFactor
            }
        }
        return AuraStudioDisplayGeometry(
            logicalSize: logical,
            nativePixelSize: native,
            standardLogicalSize: standard,
            renderScale: renderScale,
            nativeScale: nativeScale,
            xFactor: xFactor,
            yFactor: yFactor,
            isDisplayZoomed: xFactor < 0.985 || yFactor < 0.985
        )
    }
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
    case rainbow = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .glow: return LaraL10n.text(en: "Glow", es: "Brillo")
        case .pulse: return LaraL10n.text(en: "Pulse", es: "Pulso")
        case .tint: return LaraL10n.text(en: "Tint", es: "Color")
        case .rainbow: return LaraL10n.text(en: "Rainbow", es: "Arcoíris")
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
        case .rainbow:
            return LaraL10n.text(
                en: "A vivid spectrum moves continuously through every selected light.",
                es: "Un espectro intenso recorre continuamente cada luz seleccionada."
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
        // Bits 3 and 4 remain reserved so existing installs keep the stable
        // Dock and Lock flag values after Volume/Notification Aura removal.
        static let dock: UInt32 = 1 << 5
        static let lock: UInt32 = 1 << 6
        // Aura Studio now exposes only device-verified surfaces. The reserved
        // values stay intact so future rebuilt modules remain migration-safe.
        static let supported = island | dock
    }

    @ObservedObject private var mgr = laramgr.shared

    @AppStorage("eagle.islandAura.red") private var red = 0.10
    @AppStorage("eagle.islandAura.green") private var green = 0.78
    @AppStorage("eagle.islandAura.blue") private var blue = 1.0
    @AppStorage("eagle.auraStudio.mode") private var selectedModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0

    @AppStorage("eagle.auraStudio.island") private var islandEnabled = true
    @AppStorage("eagle.auraStudio.screen") private var screenEnabled = false
    @AppStorage("eagle.auraStudio.battery") private var batteryEnabled = false
    @AppStorage("eagle.auraStudio.dock") private var dockEnabled = false
    @AppStorage("eagle.auraStudio.lock") private var lockEnabled = false

    @State private var isApplying = false
    @State private var previewPulse = false
    @State private var previewRainbowHue = 0.0
    @State private var notice: AuraStudioNotice?

    private var selectedMode: AuraStudioMode {
        get { AuraStudioMode(rawValue: selectedModeRaw) ?? .glow }
        nonmutating set { selectedModeRaw = newValue.rawValue }
    }

    private var auraColor: Color {
        Color(red: red, green: green, blue: blue)
    }

    private var displayGeometry: AuraStudioDisplayGeometry {
        .current
    }

    private var previewLightColor: Color {
        selectedMode == .rainbow
            ? Color(hue: previewRainbowHue, saturation: 0.96, brightness: 1.0)
            : auraColor
    }

    private var previewRingStyle: AnyShapeStyle {
        if selectedMode == .rainbow {
            return AnyShapeStyle(AngularGradient(
                colors: [.pink, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
                center: .center
            ))
        }
        return AnyShapeStyle(auraColor)
    }

    private var selectedFlags: UInt32 {
        var flags: UInt32 = 0
        if islandEnabled { flags |= Flag.island }
        if dockEnabled { flags |= Flag.dock }
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
            // Quarantine old experimental choices before a user can Apply.
            // Only Island and Dock currently have verified live hosts.
            screenEnabled = false
            batteryEnabled = false
            lockEnabled = false
            activeFlagsRaw &= Int(Flag.supported)
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                previewPulse = true
            }
            withAnimation(.linear(duration: 5.2).repeatForever(autoreverses: false)) {
                previewRainbowHue = 1.0
            }
        }
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 5) {
                Text(LaraL10n.text(en: "Island Aura, rebuilt.", es: "Island Aura, reconstruida."))
                    .font(.title2.bold())
                Text(LaraL10n.text(
                    en: "A brighter dual-layer light that follows the live Dynamic Island.",
                    es: "Una luz de dos capas, más intensa, que sigue a Dynamic Island en vivo."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.025, green: 0.035, blue: 0.07),
                        previewLightColor.opacity(0.22),
                        Color(red: 0.018, green: 0.02, blue: 0.04),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack {
                    HStack {
                        Text("9:41")
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "cellularbars")
                            Image(systemName: "wifi")
                            Image(systemName: "battery.75percent")
                        }
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

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
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(previewLightColor.opacity(0.18))
                                }
                                .shadow(color: previewLightColor.opacity(0.95), radius: 14)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(previewLightColor, lineWidth: 2.2)
                        }
                        .shadow(color: previewLightColor, radius: 11)
                    }
                }
                .padding(14)

                if islandEnabled {
                    ZStack {
                        Capsule()
                            .stroke(previewRingStyle, lineWidth: 11)
                            .blur(radius: 7)
                            .opacity(0.78)
                        Capsule()
                            .fill(selectedMode == .tint
                                  ? previewLightColor.opacity(0.32)
                                  : .black)
                        Capsule()
                            .stroke(previewRingStyle, lineWidth: 5)
                    }
                        .frame(width: 102, height: 31)
                        .shadow(color: previewLightColor.opacity(0.95), radius: 18)
                        .hueRotation(.degrees(selectedMode == .rainbow
                                              ? previewRainbowHue * 360
                                              : 0))
                        .opacity(selectedMode == .pulse ? (previewPulse ? 1 : 0.55) : 1)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 9)
                }
            }
            .frame(height: 238)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            HStack(spacing: 7) {
                Circle()
                    .fill(activeFlagsRaw == 0 ? Color.secondary.opacity(0.5) : Color.green)
                    .frame(width: 8, height: 8)
                Text(activeFlagsRaw == 0
                     ? LaraL10n.text(en: "No verified Apply saved", es: "Sin Apply verificado guardado")
                     : LaraL10n.text(en: "Last Apply verified \(activeModuleCount) surfaces", es: "El último Apply verificó \(activeModuleCount) superficies"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 7) {
                Image(systemName: displayGeometry.isDisplayZoomed
                      ? "arrow.down.right.and.arrow.up.left"
                      : "viewfinder.circle.fill")
                    .foregroundStyle(previewLightColor)
                Text(displayGeometry.isDisplayZoomed
                     ? LaraL10n.text(
                        en: "Display Zoom detected · geometry corrected",
                        es: "Zoom de pantalla detectado · geometría corregida"
                     )
                     : LaraL10n.text(
                        en: "Standard display · native geometry",
                        es: "Pantalla estándar · geometría nativa"
                     ))
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
            .disabled(selectedMode == .rainbow)
            .opacity(selectedMode == .rainbow ? 0.45 : 1)

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

                Button {
                    selectedMode = .rainbow
                } label: {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    .red, .orange, .yellow, .green, .cyan,
                                    .blue, .purple, .pink, .red,
                                ],
                                center: .center
                            )
                        )
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle().strokeBorder(.white.opacity(0.72), lineWidth: 1.2)
                            if selectedMode == .rainbow {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.75), radius: 2)
                            }
                        }
                        .shadow(color: previewLightColor.opacity(0.9), radius: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    LaraL10n.text(en: "Animated rainbow", es: "Arcoíris animado")
                )
                Spacer()
            }

            if selectedMode == .rainbow {
                Label(
                    LaraL10n.text(
                        en: "Rainbow drives the bright core and outer bloom in two moving color phases.",
                        es: "Arcoíris mueve el núcleo brillante y la difusión exterior en dos fases de color."
                    ),
                    systemImage: "wand.and.stars"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var alwaysOnCard: some View {
        moduleCard(
            title: LaraL10n.text(en: "Dynamic Island", es: "Dynamic Island"),
            modules: [
                AuraStudioModule(
                    id: Flag.island,
                    title: LaraL10n.text(en: "Island Aura", es: "Aura de la isla"),
                    subtitle: LaraL10n.text(
                        en: "Thick luminous core + diffused outer bloom",
                        es: "Núcleo luminoso grueso + difusión exterior"
                    ),
                    symbol: "capsule.fill"
                ),
            ]
        )
    }

    private var systemMomentsCard: some View {
        moduleCard(
            title: LaraL10n.text(en: "Verified Companion", es: "Complemento verificado"),
            modules: [
                AuraStudioModule(
                    id: Flag.dock,
                    title: LaraL10n.text(en: "Dock Aura", es: "Aura del Dock"),
                    subtitle: LaraL10n.text(en: "Fits the visible Dock capsule without touching its icons", es: "Se ajusta a la cápsula visible sin tocar sus iconos"),
                    symbol: "dock.rectangle"
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
                        .foregroundStyle(previewLightColor)
                        .frame(width: 32, height: 32)
                        .background(previewLightColor.opacity(0.14))
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
                        .tint(previewLightColor)
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
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(previewLightColor)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(LaraL10n.text(
                    en: "Stable-surface rollout",
                    es: "Lanzamiento por superficies estables"
                ))
                    .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "Screen, Battery and Lock are temporarily isolated. This build cannot send them to SpringBoard while each host is rebuilt and verified one by one.",
                    es: "Pantalla, batería y bloqueo están aislados temporalmente. Esta versión no puede enviarlos a SpringBoard mientras reconstruimos y verificamos cada host uno por uno."
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
                LaraL10n.text(en: "Apply Verified Auras", es: "Aplicar auras verificadas"),
                systemImage: "sparkles"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(previewLightColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isApplying || selectedFlags == 0)
    }

    private var restoreButton: some View {
        Button { apply(mode: 0, flags: 0) } label: {
            Label(
                LaraL10n.text(
                    en: "Remove Island & Dock Auras",
                    es: "Eliminar auras de Island y Dock"
                ),
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
        (UInt32(max(activeFlagsRaw, 0)) & Flag.supported).nonzeroBitCount
    }

    private func binding(for flag: UInt32) -> Binding<Bool> {
        switch flag {
        case Flag.island: return $islandEnabled
        case Flag.screen: return $screenEnabled
        case Flag.battery: return $batteryEnabled
        case Flag.dock: return $dockEnabled
        default: return $lockEnabled
        }
    }

    private func apply(mode: Int, flags: UInt32) {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let display = displayGeometry
        let islandFrame = display.compactIslandFrame
        let dockFrame = display.dockAuraFrame
        AuraStudioDiagnostics.log(
            "request",
            "mode=\(mode) flags=0x\(String(flags, radix: 16)) device=\(devicemachine()) ios=\(versionString) " +
            "display=\(display.isDisplayZoomed ? "zoomed" : "standard") " +
            "logical=\(Int(display.logicalSize.width))x\(Int(display.logicalSize.height)) " +
            "standard=\(String(format: "%.1f", display.standardLogicalSize.width))x" +
            "\(String(format: "%.1f", display.standardLogicalSize.height)) " +
            "native=\(Int(display.nativePixelSize.width))x\(Int(display.nativePixelSize.height)) " +
            "renderScale=\(String(format: "%.4f", display.renderScale)) " +
            "nativeScale=\(String(format: "%.4f", display.nativeScale)) " +
            "factor=\(String(format: "%.4f", display.xFactor)),\(String(format: "%.4f", display.yFactor)) " +
            "island=\(String(format: "%.2f,%.2f,%.2f,%.2f", islandFrame.minX, islandFrame.minY, islandFrame.width, islandFrame.height)) " +
            "dock=\(String(format: "%.2f,%.2f,%.2f,%.2f", dockFrame.minX, dockFrame.minY, dockFrame.width, dockFrame.height)) " +
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
                en: "Island and Dock auras were removed.",
                es: "Se eliminaron las auras de Island y Dock."
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
                en: "SpringBoard did not expose the selected Island or Dock host. No partial light was left behind and nothing was reported as applied.",
                es: "SpringBoard no mostró el host seleccionado de Island o Dock. No quedó ninguna luz parcial y no se marcó nada como aplicado."
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
        if flags & Flag.island != 0 {
            names.append(LaraL10n.text(en: "Island", es: "Isla"))
        }
        if flags & Flag.screen != 0 {
            names.append(LaraL10n.text(en: "Screen", es: "Pantalla"))
        }
        if flags & Flag.battery != 0 {
            names.append(LaraL10n.text(en: "Battery Halo", es: "Halo de batería"))
        }
        if flags & Flag.dock != 0 { names.append("Dock") }
        if flags & Flag.lock != 0 {
            names.append(LaraL10n.text(en: "Lock", es: "Bloqueo"))
        }
        return names
    }
}
