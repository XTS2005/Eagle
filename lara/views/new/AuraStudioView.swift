import SwiftUI
import UIKit
import Darwin

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
            x: (standardLogicalSize.width - 134) / 2,
            y: 13,
            width: 134,
            height: 39
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
    private static var safetyLocked = false

    static func begin() -> Bool {
        guard !operationInFlight, !safetyLocked else { return false }
        operationInFlight = true
        return true
    }

    static func end() {
        operationInFlight = false
    }

    static func lock() {
        operationInFlight = false
        safetyLocked = true
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
                en: "Keeps the system-black center and adds a thick, bright outer light.",
                es: "Mantiene el centro negro del sistema y añade una luz exterior gruesa e intensa."
            )
        case .pulse:
            return LaraL10n.text(
                en: "The current surface breathes gently without changing the other profile.",
                es: "La superficie actual respira suavemente sin cambiar el otro perfil."
            )
        case .tint:
            return LaraL10n.text(
                en: "Replaces the software-black center with color; only the physical camera cutouts stay black.",
                es: "Reemplaza el centro negro generado por software con color; solo los recortes físicos de la cámara permanecen negros."
            )
        case .rainbow:
            return LaraL10n.text(
                en: "A vivid spectrum moves continuously through this surface only.",
                es: "Un espectro intenso recorre continuamente solo esta superficie."
            )
        }
    }
}

private enum AuraStudioTarget: Int, CaseIterable, Identifiable {
    case island = 1
    case dock = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .island: return "Dynamic Island"
        case .dock: return "Dock"
        }
    }

}

private struct AuraStudioOperationStep {
    let flag: UInt32
    let englishName: String
    let spanishName: String

    var localizedName: String {
        LaraL10n.text(en: englishName, es: spanishName)
    }
}

private enum AuraStudioOperation {
    case apply(AuraStudioMode)
    case remove

    var nativeMode: Int {
        switch self {
        case .apply(let mode): return mode.rawValue
        case .remove: return 0
        }
    }

    var isRemoving: Bool {
        if case .remove = self { return true }
        return false
    }
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
        static let motionDegraded: UInt32 = 1 << 30
        // Aura Studio now exposes only device-verified surfaces. The reserved
        // values stay intact so future rebuilt modules remain migration-safe.
        static let supported = island | dock
    }

    @ObservedObject private var mgr = laramgr.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Island and Dock intentionally own separate draft profiles. Reusing the
    // original Island RGB keys preserves existing user choices while Dock
    // starts with its own independent color and style.
    @AppStorage("eagle.islandAura.red") private var islandRed = 0.10
    @AppStorage("eagle.islandAura.green") private var islandGreen = 0.78
    @AppStorage("eagle.islandAura.blue") private var islandBlue = 1.0
    @AppStorage("eagle.auraStudio.island.mode") private var islandModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.dockAura.red") private var dockRed = 0.62
    @AppStorage("eagle.dockAura.green") private var dockGreen = 0.25
    @AppStorage("eagle.dockAura.blue") private var dockBlue = 1.0
    @AppStorage("eagle.auraStudio.dock.mode") private var dockModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.auraStudio.editingTarget") private var selectedTargetRaw = AuraStudioTarget.island.rawValue
    @AppStorage("eagle.auraStudio.mode") private var legacySelectedModeRaw = AuraStudioMode.glow.rawValue
    @AppStorage("eagle.auraStudio.independentProfilesMigrated") private var independentProfilesMigrated = false
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0
    @AppStorage("eagle.auraStudio.activeMode") private var activeModeRaw = 0
    @AppStorage("eagle.auraStudio.activeIslandMode") private var activeIslandModeRaw = 0
    @AppStorage("eagle.auraStudio.activeDockMode") private var activeDockModeRaw = 0
    @AppStorage("eagle.auraStudio.activeSpringBoardPID") private var activeSpringBoardPID = 0
    @AppStorage("eagle.auraStudio.activeIslandRed") private var activeIslandRed = 26
    @AppStorage("eagle.auraStudio.activeIslandGreen") private var activeIslandGreen = 199
    @AppStorage("eagle.auraStudio.activeIslandBlue") private var activeIslandBlue = 255
    @AppStorage("eagle.auraStudio.activeDockRed") private var activeDockRed = 158
    @AppStorage("eagle.auraStudio.activeDockGreen") private var activeDockGreen = 64
    @AppStorage("eagle.auraStudio.activeDockBlue") private var activeDockBlue = 255

    @State private var isApplying = false
    @State private var previewPulse = false
    @State private var previewRainbowHue = 0.0
    @State private var notice: AuraStudioNotice?
    @State private var applyStage = ""
    @State private var applySafetyBlocked = false
    @State private var activeOperationID: String?
    @State private var diagnosticsURL: URL?
    @State private var operationStepIndex = 0
    @State private var operationStepCount = 0
    @State private var operationIsRemoval = false

    private let auraEngineBuild = "2026.08.15-r6"

    private var selectedTarget: AuraStudioTarget {
        get { AuraStudioTarget(rawValue: selectedTargetRaw) ?? .island }
        nonmutating set { selectedTargetRaw = newValue.rawValue }
    }

    private var selectedMode: AuraStudioMode {
        get {
            let rawValue = selectedTarget == .island
                ? islandModeRaw
                : dockModeRaw
            let mode = AuraStudioMode(rawValue: rawValue) ?? .glow
            return selectedTarget == .dock && mode == .tint ? .glow : mode
        }
        nonmutating set {
            if selectedTarget == .island {
                islandModeRaw = newValue.rawValue
            } else {
                dockModeRaw = (newValue == .tint ? AuraStudioMode.glow : newValue).rawValue
            }
        }
    }

    private var availableModes: [AuraStudioMode] {
        selectedTarget == .island
            ? AuraStudioMode.allCases
            : AuraStudioMode.allCases.filter { $0 != .tint }
    }

    private var auraColor: Color {
        color(for: selectedTarget)
    }

    private var displayGeometry: AuraStudioDisplayGeometry {
        .current
    }

    private var previewLightColor: Color {
        previewLightColor(for: selectedTarget)
    }

    private var previewTintFillColor: Color {
        let brightest = max(islandRed, max(islandGreen, islandBlue))
        let scale = brightest > (112.0 / 255.0)
            ? (112.0 / 255.0) / brightest
            : 1.0
        return Color(
            red: islandRed * scale,
            green: islandGreen * scale,
            blue: islandBlue * scale
        )
    }

    private func previewRingStyle(for target: AuraStudioTarget) -> AnyShapeStyle {
        if mode(for: target) == .rainbow {
            return AnyShapeStyle(AngularGradient(
                colors: [.pink, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
                center: .center
            ))
        }
        return AnyShapeStyle(color(for: target))
    }

    private var selectedFlags: UInt32 {
        selectedTarget == .island ? Flag.island : Flag.dock
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
                setSelectedRGB(
                    red: Double(nextRed),
                    green: Double(nextGreen),
                    blue: Double(nextBlue)
                )
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                previewCard
                surfaceProfilesCard
                appearanceCard
                adaptiveNote

                if !mgr.dsready {
                    LaraAccessView(compact: true)
                }

                applyButton
                restoreButton
                diagnosticsCard
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Aura Studio")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isApplying)
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
                        Text(applyStage.isEmpty
                             ? LaraL10n.text(
                                en: "Preparing a safe system update…",
                                es: "Preparando una actualización segura…"
                             )
                             : applyStage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    if operationStepCount > 0 {
                        Text(LaraL10n.text(
                            en: "Step \(min(operationStepIndex, operationStepCount)) of \(operationStepCount)",
                            es: "Paso \(min(operationStepIndex, operationStepCount)) de \(operationStepCount)"
                        ))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                }
                    .padding(22)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .onAppear {
            if !independentProfilesMigrated {
                let legacyMode = AuraStudioMode(rawValue: legacySelectedModeRaw) ?? .glow
                islandModeRaw = legacyMode.rawValue
                dockModeRaw = (legacyMode == .tint ? AuraStudioMode.glow : legacyMode).rawValue
                independentProfilesMigrated = true
            }
            reconcilePersistedActiveState()
            if mgr.rcSafetyLocked { applySafetyBlocked = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                    previewPulse = true
                }
                withAnimation(.linear(duration: 5.2).repeatForever(autoreverses: false)) {
                    previewRainbowHue = 1.0
                }
            }
        }
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 5) {
                Text(LaraL10n.text(
                    en: "Two surfaces. Two identities.",
                    es: "Dos superficies. Dos identidades."
                ))
                    .font(.title2.bold())
                Text(LaraL10n.text(
                    en: "Preview Island and Dock together, then apply each profile without changing the other.",
                    es: "Previsualiza Island y Dock juntos y aplica cada perfil sin cambiar el otro."
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

                    Group {
                        let dockPreviewColor = previewLightColor(for: .dock)
                        let dockPreviewMode = mode(for: .dock)
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
                                        .fill(dockPreviewColor.opacity(0.18))
                                }
                                .shadow(color: dockPreviewColor.opacity(0.95), radius: 14)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(previewRingStyle(for: .dock), lineWidth: 2.2)
                        }
                        .shadow(color: dockPreviewColor, radius: 11)
                        .hueRotation(.degrees(dockPreviewMode == .rainbow
                                              ? previewRainbowHue * 360
                                              : 0))
                        .opacity(dockPreviewMode == .pulse
                                 ? (previewPulse ? 1 : 0.55)
                                 : 1)
                    }
                }
                .padding(14)

                Group {
                    let islandPreviewColor = previewLightColor(for: .island)
                    let islandPreviewMode = mode(for: .island)
                    ZStack {
                        Capsule()
                            .stroke(previewRingStyle(for: .island), lineWidth: 14)
                            .blur(radius: 9)
                            .opacity(0.88)
                        Capsule()
                            .fill(islandPreviewMode == .tint
                                  ? previewTintFillColor
                                  : .black)
                        Capsule()
                            .stroke(previewRingStyle(for: .island), lineWidth: 6)
                        if islandPreviewMode == .tint {
                            HStack(spacing: 5) {
                                Capsule()
                                    .fill(.black)
                                    .frame(width: 42, height: 13)
                                Circle()
                                    .fill(.black)
                                    .frame(width: 13, height: 13)
                            }
                            .offset(x: 3)
                        }
                    }
                        .frame(width: 108, height: 34)
                        .shadow(color: islandPreviewColor, radius: 22)
                        .hueRotation(.degrees(islandPreviewMode == .rainbow
                                              ? previewRainbowHue * 360
                                              : 0))
                        .opacity(islandPreviewMode == .pulse
                                 ? (previewPulse ? 1 : 0.55)
                                 : 1)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 11)
                }
            }
            .frame(height: 238)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LaraL10n.text(
                en: "Preview. Dynamic Island: \(mode(for: .island).title). Dock: \(mode(for: .dock).title).",
                es: "Vista previa. Dynamic Island: \(mode(for: .island).title). Dock: \(mode(for: .dock).title)."
            ))

            HStack(spacing: 7) {
                Circle()
                    .fill(activeFlagsRaw == 0 ? Color.secondary.opacity(0.5) : Color.green)
                    .frame(width: 8, height: 8)
                Text(activeFlagsRaw == 0
                     ? LaraL10n.text(
                        en: "No verified aura active in this SpringBoard session",
                        es: "No hay un aura verificada activa en esta sesión de SpringBoard"
                     )
                     : verifiedSurfaceSummary)
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
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(LaraL10n.text(en: "Independent Profile", es: "Perfil independiente"))
                        .font(.headline)
                    Text(LaraL10n.text(
                        en: "Editing \(selectedTarget.title) only",
                        es: "Editando solo \(selectedTarget.title)"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(previewLightColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: previewLightColor, radius: 6)
            }

            Text(LaraL10n.text(en: "Light Style", es: "Estilo de luz"))
                .font(.headline)

            Picker(
                LaraL10n.text(en: "Light Style", es: "Estilo de luz"),
                selection: Binding(get: { selectedMode }, set: { selectedMode = $0 })
            ) {
                ForEach(availableModes) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedMode.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Label {
                if selectedTarget == .dock {
                    Text(LaraL10n.text(
                        en: "Native Dock material stays intact · neon remains behind every icon",
                        es: "El material nativo del Dock se conserva · el neón queda detrás de cada icono"
                    ))
                } else if selectedMode == .tint {
                    Text(LaraL10n.text(
                        en: "Software black: off · native iOS 18 Island only",
                        es: "Negro por software: desactivado · solo Island nativa de iOS 18"
                    ))
                } else {
                    Text(LaraL10n.text(
                        en: "Software black: on · restored by Glow, Pulse and Rainbow",
                        es: "Negro por software: activado · restaurado por Brillo, Pulso y Arcoíris"
                    ))
                }
            } icon: {
                Image(systemName: selectedTarget == .dock
                      ? "dock.rectangle"
                      : (selectedMode == .tint ? "camera.aperture" : "capsule.fill"))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(selectedMode == .tint ? previewLightColor : .secondary)

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
                        setSelectedRGB(
                            red: preset.red,
                            green: preset.green,
                            blue: preset.blue
                        )
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(red: preset.red, green: preset.green, blue: preset.blue))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1)
                                    if presetIsSelected(preset) && selectedMode != .rainbow {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.75), radius: 2)
                                    }
                                }
                                .shadow(
                                    color: Color(red: preset.red, green: preset.green, blue: preset.blue).opacity(0.6),
                                    radius: 6
                                )
                        }
                        .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.name)
                    .accessibilityValue(
                        presetIsSelected(preset) && selectedMode != .rainbow
                            ? LaraL10n.text(en: "Selected", es: "Seleccionado")
                            : ""
                    )
                }

                Button {
                    selectedMode = .rainbow
                } label: {
                    ZStack {
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
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    LaraL10n.text(en: "Animated rainbow", es: "Arcoíris animado")
                )
                .accessibilityValue(
                    selectedMode == .rainbow
                        ? LaraL10n.text(en: "Selected", es: "Seleccionado")
                        : ""
                )
                Spacer()
            }

            if selectedMode == .rainbow {
                Label(
                    LaraL10n.text(
                        en: "Rainbow moves continuously through the bright edge and its outer light.",
                        es: "Arcoíris recorre continuamente el borde brillante y su luz exterior."
                    ),
                    systemImage: "wand.and.stars"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Label(
                LaraL10n.text(
                    en: "Apply changes only to \(selectedTarget.title). The other surface keeps its current verified color and style.",
                    es: "Aplicar cambia solo \(selectedTarget.title). La otra superficie conserva su color y estilo verificados."
                ),
                systemImage: "arrow.left.and.right.circle.fill"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .disabled(isApplying)
    }

    private var surfaceProfilesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(LaraL10n.text(en: "Choose What to Edit", es: "Elige qué editar"))
                    .font(.headline)
                Text(LaraL10n.text(
                    en: "Each surface keeps its own color and animation.",
                    es: "Cada superficie conserva su propio color y animación."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            ForEach(AuraStudioTarget.allCases) { target in
                profileButton(for: target)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func profileButton(for target: AuraStudioTarget) -> some View {
        let isSelected = selectedTarget == target
        let targetFlag = flag(for: target)
        let isActive = isTargetActive(target)
        let hasPendingChanges = isActive && !draftMatchesActive(target)
        let profileColor = previewLightColor(for: target)

        return Button {
            selectedTarget = target
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 11) {
                    Image(systemName: target == .island ? "capsule.fill" : "dock.rectangle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(profileColor)
                        .frame(width: 34, height: 34)
                        .background(profileColor.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(target.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(LaraL10n.text(
                            en: "Selected profile: \(mode(for: target).title)",
                            es: "Perfil seleccionado: \(mode(for: target).title)"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 6)

                    if isSelected {
                        Text(LaraL10n.text(en: "EDITING", es: "EDITANDO"))
                            .font(.caption2.bold())
                            .foregroundStyle(profileColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(profileColor.opacity(0.12), in: Capsule())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }

                HStack(spacing: 7) {
                    Circle()
                        .fill(isActive ? activeColor(for: targetFlag) : Color.secondary.opacity(0.45))
                        .frame(width: 7, height: 7)
                    Text(profileStatusText(for: target))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hasPendingChanges ? .orange : (isActive ? .green : .secondary))
                    Spacer(minLength: 0)
                }
            }
            .padding(13)
            .background(
                isSelected ? profileColor.opacity(0.10) : Color(uiColor: .tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? profileColor.opacity(0.65) : .clear, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
        .accessibilityLabel(target.title)
        .accessibilityValue(LaraL10n.text(
            en: "Selected profile: \(mode(for: target).title). \(profileStatusText(for: target)).",
            es: "Perfil seleccionado: \(mode(for: target).title). \(profileStatusText(for: target))."
        ))
        .accessibilityHint(LaraL10n.text(
            en: "Edits only this surface.",
            es: "Edita únicamente esta superficie."
        ))
    }

    private var adaptiveNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(previewLightColor)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(LaraL10n.text(
                    en: "Verified support",
                    es: "Compatibilidad verificada"
                ))
                    .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "Dynamic Island and Dock are available now. Screen, Battery and Lock remain safely disabled until their live surfaces are verified.",
                    es: "Dynamic Island y Dock están disponibles. Pantalla, batería y bloqueo permanecen desactivados de forma segura hasta verificar sus superficies en vivo."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                Text("Aura Engine \(auraEngineBuild)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var applyButton: some View {
        Button {
            runAuraOperation(.apply(selectedMode), flags: selectedFlags)
        } label: {
            Label(
                mgr.dsready
                    ? LaraL10n.text(
                        en: "Apply \(selectedMode.title) to \(selectedTarget.title)",
                        es: "Aplicar \(selectedMode.title) a \(selectedTarget.title)"
                    )
                    : LaraL10n.text(
                        en: "Prepare iPhone to Apply",
                        es: "Prepara el iPhone para aplicar"
                    ),
                systemImage: mgr.dsready ? "sparkles" : "lock.shield.fill"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(previewLightColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(
            isApplying || !mgr.dsready || selectedFlags == 0 ||
            applySafetyBlocked || mgr.rcSafetyLocked
        )
        .opacity(!mgr.dsready || applySafetyBlocked || mgr.rcSafetyLocked ? 0.48 : 1)
        .accessibilityHint(LaraL10n.text(
            en: "Changes only \(selectedTarget.title).",
            es: "Cambia únicamente \(selectedTarget.title)."
        ))
    }

    private var restoreButton: some View {
        Button {
            runAuraOperation(.remove, flags: selectedFlags)
        } label: {
            Label(
                LaraL10n.text(
                    en: "Remove \(selectedTarget.title) Aura",
                    es: "Eliminar aura de \(selectedTarget.title)"
                ),
                systemImage: "arrow.counterclockwise"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(
            isApplying || !mgr.dsready || !isTargetActive(selectedTarget) ||
            applySafetyBlocked || mgr.rcSafetyLocked
        )
        .accessibilityHint(LaraL10n.text(
            en: "Restores only \(selectedTarget.title) and keeps the other aura active.",
            es: "Restaura únicamente \(selectedTarget.title) y mantiene activa la otra aura."
        ))
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if applySafetyBlocked || mgr.rcSafetyLocked {
                Label(
                    LaraL10n.text(
                        en: "Safety lock active for this Eagle run",
                        es: "Bloqueo de seguridad activo durante esta ejecución de Eagle"
                    ),
                    systemImage: "exclamationmark.shield.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

                Text(LaraL10n.text(
                    en: "Aura Studio will not retry after an unverified call, timeout, SpringBoard restart, or main-thread error. Export the report, then fully close and reopen Eagle before another test.",
                    es: "Aura Studio no volverá a intentarlo después de una llamada no verificada, un tiempo agotado, un reinicio de SpringBoard o un error del hilo principal. Exporta el informe y luego cierra y abre Eagle completamente antes de otra prueba."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    diagnosticsURL = makeDiagnosticsReport(
                        summary: mgr.rcSafetyReason ?? "Manual Aura Studio export"
                    )
                } label: {
                    Label(
                        LaraL10n.text(en: "Build Report", es: "Crear informe"),
                        systemImage: "doc.text.magnifyingglass"
                    )
                }
                .buttonStyle(.bordered)

                if let diagnosticsURL {
                    ShareLink(item: diagnosticsURL) {
                        Label(
                            LaraL10n.text(en: "Share", es: "Compartir"),
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var presets: [(name: String, red: Double, green: Double, blue: Double)] {
        [
            (LaraL10n.text(en: "Electric Blue", es: "Azul eléctrico"), 0.10, 0.78, 1.00),
            (LaraL10n.text(en: "Ultra Violet", es: "Ultravioleta"), 0.62, 0.25, 1.00),
            (LaraL10n.text(en: "Hot Pink", es: "Rosa intenso"), 1.00, 0.16, 0.62),
            (LaraL10n.text(en: "Acid Green", es: "Verde ácido"), 0.42, 1.00, 0.24),
        ]
    }

    private func presetIsSelected(
        _ preset: (name: String, red: Double, green: Double, blue: Double)
    ) -> Bool {
        let selectedRGB = selectedTarget == .island
            ? (islandRed, islandGreen, islandBlue)
            : (dockRed, dockGreen, dockBlue)
        let tolerance = 0.002
        return abs(selectedRGB.0 - preset.red) < tolerance &&
            abs(selectedRGB.1 - preset.green) < tolerance &&
            abs(selectedRGB.2 - preset.blue) < tolerance
    }

    private func mode(for target: AuraStudioTarget) -> AuraStudioMode {
        let rawValue = target == .island ? islandModeRaw : dockModeRaw
        let stored = AuraStudioMode(rawValue: rawValue) ?? .glow
        return target == .dock && stored == .tint ? .glow : stored
    }

    private func color(for target: AuraStudioTarget) -> Color {
        switch target {
        case .island:
            return Color(red: islandRed, green: islandGreen, blue: islandBlue)
        case .dock:
            return Color(red: dockRed, green: dockGreen, blue: dockBlue)
        }
    }

    private func previewLightColor(for target: AuraStudioTarget) -> Color {
        mode(for: target) == .rainbow
            ? Color(hue: previewRainbowHue, saturation: 0.96, brightness: 1.0)
            : color(for: target)
    }

    private func setSelectedRGB(red: Double, green: Double, blue: Double) {
        let nextRed = max(0, min(1, red))
        let nextGreen = max(0, min(1, green))
        let nextBlue = max(0, min(1, blue))
        if selectedTarget == .island {
            islandRed = nextRed
            islandGreen = nextGreen
            islandBlue = nextBlue
        } else {
            dockRed = nextRed
            dockGreen = nextGreen
            dockBlue = nextBlue
        }
    }

    private func activeColor(for flag: UInt32) -> Color {
        let rgb = flag == Flag.island
            ? (activeIslandRed, activeIslandGreen, activeIslandBlue)
            : (activeDockRed, activeDockGreen, activeDockBlue)
        return Color(
            red: Double(rgb.0) / 255.0,
            green: Double(rgb.1) / 255.0,
            blue: Double(rgb.2) / 255.0
        )
    }

    private func flag(for target: AuraStudioTarget) -> UInt32 {
        target == .island ? Flag.island : Flag.dock
    }

    private func isTargetActive(_ target: AuraStudioTarget) -> Bool {
        UInt32(max(activeFlagsRaw, 0)) & flag(for: target) != 0
    }

    private func activeMode(for target: AuraStudioTarget) -> AuraStudioMode? {
        let rawValue = target == .island ? activeIslandModeRaw : activeDockModeRaw
        return AuraStudioMode(rawValue: rawValue)
    }

    private func draftMatchesActive(_ target: AuraStudioTarget) -> Bool {
        guard isTargetActive(target), activeMode(for: target) == mode(for: target) else {
            return false
        }
        // Rainbow has no single active RGB value; its verified mode is enough
        // to distinguish the applied state from the editable draft.
        if mode(for: target) == .rainbow { return true }

        let draftRGB: (Int, Int, Int)
        let activeRGB: (Int, Int, Int)
        if target == .island {
            draftRGB = (
                Int((islandRed * 255).rounded()),
                Int((islandGreen * 255).rounded()),
                Int((islandBlue * 255).rounded())
            )
            activeRGB = (activeIslandRed, activeIslandGreen, activeIslandBlue)
        } else {
            draftRGB = (
                Int((dockRed * 255).rounded()),
                Int((dockGreen * 255).rounded()),
                Int((dockBlue * 255).rounded())
            )
            activeRGB = (activeDockRed, activeDockGreen, activeDockBlue)
        }
        return draftRGB == activeRGB
    }

    private func profileStatusText(for target: AuraStudioTarget) -> String {
        guard let appliedMode = activeMode(for: target), isTargetActive(target) else {
            return LaraL10n.text(en: "Not active", es: "No activo")
        }
        if draftMatchesActive(target) {
            return LaraL10n.text(
                en: "Applied · \(appliedMode.title)",
                es: "Aplicado · \(appliedMode.title)"
            )
        }
        return LaraL10n.text(
            en: "Active: \(appliedMode.title) · selected changes not applied",
            es: "Activo: \(appliedMode.title) · cambios seleccionados sin aplicar"
        )
    }

    private func rgb255String(_ red: Double, _ green: Double, _ blue: Double) -> String {
        [red, green, blue]
            .map { String(max(0, min(255, Int(($0 * 255).rounded())))) }
            .joined(separator: ",")
    }

    private var activeModuleCount: Int {
        (UInt32(max(activeFlagsRaw, 0)) & Flag.supported).nonzeroBitCount
    }

    private var verifiedSurfaceSummary: String {
        if activeModuleCount == 1 {
            return LaraL10n.text(
                en: "1 verified aura active in this SpringBoard session",
                es: "1 aura verificada activa en esta sesión de SpringBoard"
            )
        }
        return LaraL10n.text(
            en: "\(activeModuleCount) verified auras active in this SpringBoard session",
            es: "\(activeModuleCount) auras verificadas activas en esta sesión de SpringBoard"
        )
    }

    private func reconcilePersistedActiveState(currentPID providedPID: Int32? = nil) {
        let currentPID = providedPID ?? "SpringBoard".withCString {
            find_process_pid($0)
        }
        let savedFlags = UInt32(max(activeFlagsRaw, 0)) & Flag.supported
        guard savedFlags != 0 else {
            activeFlagsRaw = 0
            activeModeRaw = 0
            activeIslandModeRaw = 0
            activeDockModeRaw = 0
            activeSpringBoardPID = 0
            return
        }

        // Auras live inside SpringBoard. A badge saved by an older build, or
        // by a SpringBoard PID that no longer exists, cannot be called active.
        guard activeSpringBoardPID > 0,
              currentPID == Int32(activeSpringBoardPID) else {
            AuraStudioDiagnostics.log(
                "state.expired",
                "savedPID=\(activeSpringBoardPID) currentPID=\(currentPID) " +
                "flags=0x\(String(savedFlags, radix: 16))"
            )
            activeFlagsRaw = 0
            activeModeRaw = 0
            activeIslandModeRaw = 0
            activeDockModeRaw = 0
            activeSpringBoardPID = 0
            return
        }

        // One-time migration from the original shared style field.
        if savedFlags & Flag.island != 0, activeIslandModeRaw == 0 {
            activeIslandModeRaw = activeModeRaw
        }
        if savedFlags & Flag.dock != 0, activeDockModeRaw == 0 {
            activeDockModeRaw = activeModeRaw
        }
    }

    private func runAuraOperation(
        _ operation: AuraStudioOperation,
        flags: UInt32
    ) {
        // The visual objects live inside one SpringBoard process. Reconcile
        // again at the moment of the request (not only onAppear) so a respring
        // while this screen remains open cannot carry stale badges or modes
        // into a fresh process.
        let operationSpringBoardPID = "SpringBoard".withCString {
            find_process_pid($0)
        }
        reconcilePersistedActiveState(currentPID: operationSpringBoardPID)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let operationID = String(UUID().uuidString.prefix(8))
        let mode = operation.nativeMode
        let requestedFlags = flags & Flag.supported
        let display = displayGeometry
        let islandFrame = display.compactIslandFrame
        let dockFrame = display.dockAuraFrame
        AuraStudioDiagnostics.log(
            "request",
            "op=\(operationID) engine=\(auraEngineBuild) " +
            "action=\(operation.isRemoving ? "remove" : "apply") mode=\(mode) " +
            "target=\(selectedTarget.title) flags=0x\(String(requestedFlags, radix: 16)) " +
            "device=\(devicemachine()) " +
            "ios=\(version.majorVersion).\(version.minorVersion).\(version.patchVersion) " +
            "display=\(display.isDisplayZoomed ? "zoomed" : "standard") " +
            "factor=\(String(format: "%.4f", display.xFactor))," +
            "\(String(format: "%.4f", display.yFactor)) " +
            "island=\(String(format: "%.2f,%.2f,%.2f,%.2f", islandFrame.minX, islandFrame.minY, islandFrame.width, islandFrame.height)) " +
            "dock=\(String(format: "%.2f,%.2f,%.2f,%.2f", dockFrame.minX, dockFrame.minY, dockFrame.width, dockFrame.height))"
        )

        guard !applySafetyBlocked, !mgr.rcSafetyLocked else {
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Aura Studio is safety locked after the previous unverified attempt. Export the report, fully close Eagle, and reopen it before testing again.",
                es: "Aura Studio está bloqueado por seguridad después del intento anterior no verificado. Exporta el informe, cierra Eagle completamente y vuelve a abrirlo antes de probar otra vez."
            ))
            return
        }
        guard !isApplying, AuraStudioApplyGate.begin() else {
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
        guard operation.isRemoving ||
                mode != AuraStudioMode.tint.rawValue ||
                version.majorVersion == 18 else {
            finish(message: message(for: -17))
            return
        }
        guard mgr.dsready, requestedFlags != 0 else {
            finish(message: LaraL10n.text(
                en: "Prepare Eagle access and select at least one verified surface before applying.",
                es: "Prepara el acceso de Eagle y selecciona al menos una superficie verificada antes de aplicar."
            ))
            return
        }
        guard requestedFlags.nonzeroBitCount == 1 else {
            finish(message: LaraL10n.text(
                en: "Choose exactly one Aura surface. Island and Dock are applied independently.",
                es: "Elige exactamente una superficie Aura. Island y Dock se aplican de forma independiente."
            ))
            return
        }

        var steps: [AuraStudioOperationStep] = []
        if requestedFlags & Flag.island != 0 {
            steps.append(AuraStudioOperationStep(
                flag: Flag.island,
                englishName: "Dynamic Island",
                spanishName: "Dynamic Island"
            ))
        }
        if requestedFlags & Flag.dock != 0 {
            steps.append(AuraStudioOperationStep(
                flag: Flag.dock,
                englishName: "Dock",
                spanishName: "Dock"
            ))
        }

        let selectedRGB: (red: Double, green: Double, blue: Double) =
            selectedTarget == .island
                ? (islandRed, islandGreen, islandBlue)
                : (dockRed, dockGreen, dockBlue)
        let redValue = Int32(max(0, min(255, Int((selectedRGB.red * 255).rounded()))))
        let greenValue = Int32(max(0, min(255, Int((selectedRGB.green * 255).rounded()))))
        let blueValue = Int32(max(0, min(255, Int((selectedRGB.blue * 255).rounded()))))
        let previouslyVerified = UInt32(max(activeFlagsRaw, 0)) & Flag.supported
        var retainedVerified = previouslyVerified
        var newlyApplied: UInt32 = 0
        var removedFlags: UInt32 = 0
        var motionDegraded = false
        var firstUnavailableResult: Int32?
        var verifiedFallbackResult: Int32?

        isApplying = true
        operationIsRemoval = operation.isRemoving
        operationStepIndex = 0
        operationStepCount = steps.count
        activeOperationID = operationID
        applyStage = LaraL10n.text(
            en: "Preparing a fresh SpringBoard session…",
            es: "Preparando una sesión nueva de SpringBoard…"
        )

        func resetOperationUI() {
            isApplying = false
            applyStage = ""
            operationStepIndex = 0
            operationStepCount = 0
            operationIsRemoval = false
            activeOperationID = nil
        }

        func failBeforeNativeCall(_ reason: String) {
            AuraStudioDiagnostics.log(
                "sequence.preflight-failed",
                "op=\(operationID) reason=\(reason)"
            )
            diagnosticsURL = makeDiagnosticsReport(summary: reason)
            resetOperationUI()
            AuraStudioApplyGate.end()
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Aura Studio could not prepare a safe session for \(selectedTarget.title). Nothing was sent, and the other aura was not touched. A technical report is ready if the problem repeats.",
                es: "Aura Studio no pudo preparar una sesión segura para \(selectedTarget.title). No se envió nada y no se tocó la otra aura. Hay un informe técnico disponible si el problema se repite."
            ))
        }

        func failAfterNativeCall(_ reason: String, result: Int32? = nil) {
            let resultText = result.map { " result=\($0)" } ?? ""
            AuraStudioDiagnostics.log(
                "breaker.open",
                "op=\(operationID) applied=0x\(String(newlyApplied, radix: 16)) " +
                "removed=0x\(String(removedFlags, radix: 16))" +
                resultText + " reason=\(reason)"
            )
            activeFlagsRaw = Int(retainedVerified | newlyApplied)
            if activeFlagsRaw & Int(Flag.island) == 0 {
                activeModeRaw = 0
                activeIslandModeRaw = 0
            }
            if activeFlagsRaw & Int(Flag.dock) == 0 {
                activeDockModeRaw = 0
            }
            if activeFlagsRaw == 0 {
                activeSpringBoardPID = 0
            } else {
                activeSpringBoardPID = Int(
                    "SpringBoard".withCString { find_process_pid($0) }
                )
            }
            mgr.quarantineRemoteCall(reason: reason)
            applySafetyBlocked = true
            AuraStudioApplyGate.lock()
            diagnosticsURL = makeDiagnosticsReport(summary: reason)
            resetOperationUI()
            notice = AuraStudioNotice(message: LaraL10n.text(
                en: "Aura Studio stopped because \(selectedTarget.title) could not be verified. The other aura was not changed and no automatic respring was attempted. Share the diagnostic report, then fully close and reopen Eagle before another test.",
                es: "Aura Studio se detuvo porque no pudo verificar \(selectedTarget.title). No se cambió la otra aura ni se intentó un respring automático. Comparte el informe y luego cierra y abre Eagle completamente antes de otra prueba."
            ))
        }

        func completeSuccess(deadlineWarning: Bool = false) {
            let finalFlags = retainedVerified | newlyApplied
            activeFlagsRaw = Int(finalFlags)
            activeModeRaw = activeIslandModeRaw
            if finalFlags == 0 {
                activeSpringBoardPID = 0
                activeModeRaw = 0
                activeIslandModeRaw = 0
                activeDockModeRaw = 0
            } else {
                activeSpringBoardPID = Int(operationSpringBoardPID)
            }
            AuraStudioDiagnostics.log(
                "sequence.success",
                "op=\(operationID) applied=0x\(String(newlyApplied, radix: 16)) " +
                "removed=0x\(String(removedFlags, radix: 16)) " +
                "degraded=\(motionDegraded) deadlineWarning=\(deadlineWarning)"
            )
            diagnosticsURL = makeDiagnosticsReport(
                summary: operation.isRemoving
                    ? "Scoped removal completed"
                    : "Apply completed"
            )
            resetOperationUI()
            if !deadlineWarning {
                AuraStudioApplyGate.end()
            }
            let baseResultMessage: String
            if let verifiedFallbackResult {
                baseResultMessage = message(for: verifiedFallbackResult)
            } else if !operation.isRemoving,
                      newlyApplied == 0,
                      let firstUnavailableResult {
                baseResultMessage = message(for: firstUnavailableResult)
            } else {
                baseResultMessage = successMessage(
                    appliedFlags: operation.isRemoving
                        ? removedFlags
                        : newlyApplied,
                    requestedFlags: requestedFlags,
                    restoring: operation.isRemoving,
                    motionDegraded: motionDegraded
                )
            }
            let resultMessage: String
            if deadlineWarning {
                resultMessage = baseResultMessage + " " + LaraL10n.text(
                    en: "Verification exceeded the safety deadline, so Eagle will not retry this surface. Fully close and reopen Eagle before another Aura Studio operation.",
                    es: "La verificación superó el límite de seguridad, por lo que Eagle no volverá a intentar esta superficie. Cierra Eagle completamente y vuelve a abrirlo antes de otra operación de Aura Studio."
                )
            } else {
                resultMessage = baseResultMessage
            }
            notice = AuraStudioNotice(message: resultMessage)
        }

        func runStep(_ index: Int) {
            guard activeOperationID == operationID, isApplying else { return }
            guard index < steps.count else {
                completeSuccess()
                return
            }
            let step = steps[index]
            operationStepIndex = index + 1
            applyStage = LaraL10n.text(
                en: "Preparing \(step.englishName) safely…",
                es: "Preparando \(step.spanishName) de forma segura…"
            )
            AuraStudioDiagnostics.log(
                "step.session.begin",
                "op=\(operationID) index=\(index) module=\(step.englishName) " +
                "flag=0x\(String(step.flag, radix: 16))"
            )
            mgr.prepareFreshRemoteCall(
                process: "SpringBoard",
                timeout: 20
            ) { process, sessionError in
                guard activeOperationID == operationID, isApplying else { return }
                guard let process else {
                    let reason = sessionError ?? "Fresh SpringBoard session was unavailable"
                    let isReadOnlyPreflight =
                        reason.localizedCaseInsensitiveContains("access is not ready") ||
                        reason.localizedCaseInsensitiveContains("still running") ||
                        reason.localizedCaseInsensitiveContains("safety locked")
                    if isReadOnlyPreflight {
                        failBeforeNativeCall(reason)
                    } else {
                        // RemoteCall initialization can already install target
                        // exception ports and create a helper thread. Any
                        // failure after that point is a transport event, not a
                        // harmless host miss, so this run must fail closed.
                        retainedVerified &= ~step.flag
                        failAfterNativeCall(reason)
                    }
                    return
                }

                let targetPID = process.pid
                let currentPID = "SpringBoard".withCString { find_process_pid($0) }
                guard targetPID > 0,
                      process.creatingExtraThread else {
                    failBeforeNativeCall(
                        "Fresh session identity check failed " +
                        "(target \(targetPID), current \(currentPID), " +
                        "isolated \(process.creatingExtraThread))"
                    )
                    return
                }
                guard currentPID == targetPID,
                      targetPID == operationSpringBoardPID else {
                    retainedVerified = 0
                    newlyApplied = 0
                    activeFlagsRaw = 0
                    activeModeRaw = 0
                    activeIslandModeRaw = 0
                    activeDockModeRaw = 0
                    activeSpringBoardPID = 0
                    failAfterNativeCall(
                        "SpringBoard changed while preparing \(step.englishName) " +
                        "(operation \(operationSpringBoardPID), target \(targetPID), " +
                        "current \(currentPID))"
                    )
                    return
                }
                guard mgr.beginExclusiveRemoteCall(
                    label: "Aura \(step.englishName) \(operationID)"
                ) else {
                    failBeforeNativeCall(
                        "Could not acquire the serialized \(step.englishName) session"
                    )
                    return
                }

                applyStage = LaraL10n.text(
                    en: operation.isRemoving
                        ? "Removing \(step.englishName) only…"
                        : "Applying \(step.englishName) only…",
                    es: operation.isRemoving
                        ? "Eliminando solo \(step.spanishName)…"
                        : "Aplicando solo \(step.spanishName)…"
                )
                AuraStudioDiagnostics.log(
                    "step.native.begin",
                    "op=\(operationID) module=\(step.englishName) " +
                    "action=\(operation.isRemoving ? "remove" : "apply") " +
                    "pid=\(targetPID) flag=0x\(String(step.flag, radix: 16))"
                )
                let started = Date()
                var nativeFinished = false
                var hardDeadlineExceeded = false
                let softProgressWork = DispatchWorkItem {
                    guard activeOperationID == operationID,
                          isApplying,
                          !nativeFinished else { return }
                    applyStage = LaraL10n.text(
                        en: "\(step.englishName) is responding · verifying the live result…",
                        es: "\(step.spanishName) está respondiendo · verificando el resultado en vivo…"
                    )
                    AuraStudioDiagnostics.log(
                        "step.native.progress",
                        "op=\(operationID) module=\(step.englishName) elapsed=10"
                    )
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 10,
                    execute: softProgressWork
                )

                // Device evidence on iOS 18.6.2 shows a healthy, verified
                // Island call can take ~17 seconds. The hard deadline is a
                // circuit breaker, not a false failure: the in-flight result
                // is still consumed, but an automatic retry can never start.
                let hardDeadlineWork = DispatchWorkItem {
                    guard activeOperationID == operationID,
                          isApplying,
                          !nativeFinished else { return }
                    hardDeadlineExceeded = true
                    let reason = "\(step.englishName) exceeded the 60-second safety deadline"
                    AuraStudioDiagnostics.log(
                        "step.native.deadline",
                        "op=\(operationID) module=\(step.englishName) elapsed=60"
                    )
                    applyStage = LaraL10n.text(
                        en: "Still waiting safely for \(step.englishName) · no automatic retry will start…",
                        es: "Aún esperando de forma segura a \(step.spanishName) · no se iniciará otro intento automático…"
                    )
                    mgr.quarantineRemoteCall(reason: reason)
                    applySafetyBlocked = true
                    AuraStudioApplyGate.lock()
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 60,
                    execute: hardDeadlineWork
                )

                DispatchQueue.global(qos: .userInitiated).async {
                    let result = autoreleasepool {
                        eagle_set_aura_studio(
                            process,
                            redValue,
                            greenValue,
                            blueValue,
                            Int32(operation.nativeMode),
                            step.flag
                        )
                    }
                    let elapsed = Date().timeIntervalSince(started)
                    let processError = process.lastError
                    let springBoardPID = "SpringBoard".withCString {
                        find_process_pid($0)
                    }
                    AuraStudioDiagnostics.log(
                        "step.native.end",
                        "op=\(operationID) module=\(step.englishName) result=\(result) " +
                        "elapsed=\(String(format: "%.3f", elapsed)) target=\(targetPID) " +
                        "current=\(springBoardPID) error=\(processError ?? "none")"
                    )
                    DispatchQueue.main.async {
                        let liveSpringBoardPID = "SpringBoard".withCString {
                            find_process_pid($0)
                        }
                        guard activeOperationID == operationID,
                              isApplying,
                              !nativeFinished else {
                            AuraStudioDiagnostics.log(
                                "step.native.late",
                                "op=\(operationID) module=\(step.englishName) result=\(result)"
                            )
                            if springBoardPID != targetPID ||
                                liveSpringBoardPID != targetPID {
                                activeFlagsRaw = 0
                                activeModeRaw = 0
                                activeIslandModeRaw = 0
                                activeDockModeRaw = 0
                                activeSpringBoardPID = 0
                            }
                            mgr.endExclusiveRemoteCall(
                                label: "Aura \(step.englishName) \(operationID)"
                            )
                            return
                        }
                        nativeFinished = true
                        softProgressWork.cancel()
                        hardDeadlineWork.cancel()
                        mgr.endExclusiveRemoteCall(
                            label: "Aura \(step.englishName) \(operationID)"
                        )

                        if springBoardPID != targetPID ||
                            liveSpringBoardPID != targetPID ||
                            targetPID != operationSpringBoardPID {
                            activeFlagsRaw = 0
                            activeModeRaw = 0
                            activeIslandModeRaw = 0
                            activeDockModeRaw = 0
                            activeSpringBoardPID = 0
                            retainedVerified = 0
                            newlyApplied = 0
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "SpringBoard restarted during \(step.englishName) " +
                                "(PID \(targetPID) → \(liveSpringBoardPID))",
                                result: result
                            )
                            return
                        }
                        if !process.isHealthy ||
                            process.lastCallTimedOut ||
                            (processError?.isEmpty == false) {
                            let transportReason = processError ??
                                (process.lastCallTimedOut
                                    ? "RemoteCall transport timed out"
                                    : "RemoteCall session became unhealthy")
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "\(step.englishName) RemoteCall error: \(transportReason)",
                                result: result
                            )
                            return
                        }
                        if operation.isRemoving {
                            guard result == 0 else {
                                retainedVerified &= ~step.flag
                                failAfterNativeCall(
                                    "\(step.englishName) removal could not be verified",
                                    result: result
                                )
                                return
                            }
                            retainedVerified &= ~step.flag
                            removedFlags |= step.flag
                            if step.flag == Flag.island {
                                activeIslandModeRaw = 0
                                activeModeRaw = 0
                            } else if step.flag == Flag.dock {
                                activeDockModeRaw = 0
                            }
                            activeFlagsRaw = Int(retainedVerified | newlyApplied)
                            activeSpringBoardPID = activeFlagsRaw == 0
                                ? 0
                                : Int(springBoardPID)
                            AuraStudioDiagnostics.log(
                                "step.remove.success",
                                "op=\(operationID) module=\(step.englishName) " +
                                "removed=0x\(String(removedFlags, radix: 16))"
                            )
                            if hardDeadlineExceeded {
                                completeSuccess(deadlineWarning: true)
                            } else {
                                runStep(index + 1)
                            }
                            return
                        }
                        if result == -15 || result == -16 {
                            // These results explicitly guarantee that the
                            // static black Glow core was restored and verified.
                            // Keep that truthful state without opening the
                            // circuit breaker or attempting to reapply Tint.
                            newlyApplied |= Flag.island
                            retainedVerified &= ~Flag.island
                            activeFlagsRaw = Int(retainedVerified | newlyApplied)
                            activeSpringBoardPID = Int(springBoardPID)
                            activeModeRaw = AuraStudioMode.glow.rawValue
                            activeIslandModeRaw = AuraStudioMode.glow.rawValue
                            activeIslandRed = Int(redValue)
                            activeIslandGreen = Int(greenValue)
                            activeIslandBlue = Int(blueValue)
                            verifiedFallbackResult = result
                            AuraStudioDiagnostics.log(
                                "step.fallback",
                                "op=\(operationID) module=\(step.englishName) result=\(result) verified=glow"
                            )
                            if hardDeadlineExceeded {
                                completeSuccess(deadlineWarning: true)
                            } else {
                                runStep(index + 1)
                            }
                            return
                        }
                        if result == -2 || result == -17 || result == -20 {
                            // The native contract defines these as read-only
                            // host/preflight misses. They are safe to report as
                            // unavailable and must not prevent the other
                            // independently selected module from being tried.
                            if firstUnavailableResult == nil {
                                firstUnavailableResult = result
                            }
                            retainedVerified |= previouslyVerified & step.flag
                            activeFlagsRaw = Int(retainedVerified | newlyApplied)
                            if activeFlagsRaw & Int(Flag.island) == 0 {
                                activeModeRaw = 0
                            }
                            AuraStudioDiagnostics.log(
                                "step.unavailable",
                                "op=\(operationID) module=\(step.englishName) result=\(result) mutation=none"
                            )
                            if hardDeadlineExceeded {
                                completeSuccess(deadlineWarning: true)
                            } else {
                                runStep(index + 1)
                            }
                            return
                        }
                        guard result >= 0 else {
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "\(step.englishName) returned unverified native error \(result)",
                                result: result
                            )
                            return
                        }
                        let rawResult = UInt32(bitPattern: result)
                        guard rawResult & step.flag != 0 else {
                            retainedVerified &= ~step.flag
                            failAfterNativeCall(
                                "\(step.englishName) did not verify its requested host",
                                result: result
                            )
                            return
                        }

                        newlyApplied |= step.flag
                        retainedVerified &= ~step.flag
                        motionDegraded = motionDegraded ||
                            rawResult & Flag.motionDegraded != 0
                        activeFlagsRaw = Int(retainedVerified | newlyApplied)
                        activeSpringBoardPID = Int(springBoardPID)
                        if step.flag == Flag.island {
                            activeModeRaw = mode
                            activeIslandModeRaw = mode
                            activeIslandRed = Int(redValue)
                            activeIslandGreen = Int(greenValue)
                            activeIslandBlue = Int(blueValue)
                        } else if step.flag == Flag.dock {
                            activeDockModeRaw = mode
                            activeDockRed = Int(redValue)
                            activeDockGreen = Int(greenValue)
                            activeDockBlue = Int(blueValue)
                        }
                        AuraStudioDiagnostics.log(
                            "step.success",
                            "op=\(operationID) module=\(step.englishName) applied=0x\(String(newlyApplied, radix: 16))"
                        )
                        if hardDeadlineExceeded {
                            completeSuccess(deadlineWarning: true)
                        } else {
                            runStep(index + 1)
                        }
                    }
                }
            }
        }

        runStep(0)
    }

    private func makeDiagnosticsReport(summary: String) -> URL? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let relevantFragments = [
            "eagle.aura",
            "eagle.island",
            "eagle.dock",
            "(rc)",
            "remote call",
            "RemoteCall",
        ]
        let lines = globallogger.logs
            .flatMap { $0.components(separatedBy: .newlines) }
            .filter { line in
                relevantFragments.contains { fragment in
                    line.localizedCaseInsensitiveContains(fragment)
                }
            }
            .suffix(600)
        let header = [
            "Eagle Aura Studio diagnostics",
            "timestamp=\(timestamp)",
            "engine=\(auraEngineBuild)",
            "operation=\(activeOperationID ?? "none")",
            "operationKind=\(operationIsRemoval ? "remove" : "apply")",
            "operationStep=\(operationStepIndex)/\(operationStepCount)",
            "summary=\(summary)",
            "device=\(devicemachine())",
            "ios=\(ProcessInfo.processInfo.operatingSystemVersionString)",
            "dsready=\(mgr.dsready)",
            "rcrunning=\(mgr.rcrunning)",
            "rcready=\(mgr.rcready)",
            "rcSafetyLocked=\(mgr.rcSafetyLocked)",
            "rcError=\(mgr.rcLastError ?? "none")",
            "selectedTarget=\(selectedTarget.title)",
            "islandDraft=mode:\(islandModeRaw) rgb:\(rgb255String(islandRed, islandGreen, islandBlue))",
            "dockDraft=mode:\(dockModeRaw) rgb:\(rgb255String(dockRed, dockGreen, dockBlue))",
            "selectedFlags=0x\(String(selectedFlags, radix: 16))",
            "activeFlags=0x\(String(UInt32(max(activeFlagsRaw, 0)) & Flag.supported, radix: 16))",
            "activeIsland=mode:\(activeIslandModeRaw) rgb:\(activeIslandRed),\(activeIslandGreen),\(activeIslandBlue)",
            "activeDock=mode:\(activeDockModeRaw) rgb:\(activeDockRed),\(activeDockGreen),\(activeDockBlue)",
            "activeSpringBoardPID=\(activeSpringBoardPID)",
            "currentSpringBoardPID=\("SpringBoard".withCString { find_process_pid($0) })",
            "displayZoomed=\(displayGeometry.isDisplayZoomed)",
            "displayFactor=\(String(format: "%.4f,%.4f", displayGeometry.xFactor, displayGeometry.yFactor))",
            "--- filtered log ---",
        ]
        let report = (header + Array(lines)).joined(separator: "\n") + "\n"
        let filename = "Eagle-Aura-Diagnostics-" +
            timestamp.replacingOccurrences(of: ":", with: "-") + ".txt"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        do {
            try report.write(to: url, atomically: true, encoding: .utf8)
            AuraStudioDiagnostics.log(
                "diagnostics.ready",
                "path=\(url.lastPathComponent) lines=\(lines.count)"
            )
            return url
        } catch {
            AuraStudioDiagnostics.log(
                "diagnostics.failed",
                "error=\(error.localizedDescription)"
            )
            return nil
        }
    }

    private func finish(message: String) {
        AuraStudioDiagnostics.log("finish", "error=true")
        DispatchQueue.main.async {
            AuraStudioApplyGate.end()
            self.activeOperationID = nil
            self.isApplying = false
            self.applyStage = ""
            self.operationStepIndex = 0
            self.operationStepCount = 0
            self.operationIsRemoval = false
            self.notice = AuraStudioNotice(message: message)
        }
    }

    private func successMessage(
        appliedFlags: UInt32,
        requestedFlags: UInt32,
        restoring: Bool,
        motionDegraded: Bool
    ) -> String {
        if restoring {
            let removed = names(for: appliedFlags)
            let missing = names(for: requestedFlags & ~appliedFlags)
            let removedText = removed.isEmpty
                ? LaraL10n.text(en: "No aura", es: "Ningún aura")
                : removed.joined(separator: ", ")
            if !missing.isEmpty {
                return LaraL10n.text(
                    en: "Removed and verified: \(removedText). Not verified: \(missing.joined(separator: ", ")).",
                    es: "Eliminado y verificado: \(removedText). Sin verificar: \(missing.joined(separator: ", "))."
                )
            }
            return LaraL10n.text(
                en: "Removed and verified: \(removedText). The original system appearance is restored.",
                es: "Eliminado y verificado: \(removedText). Se restauró la apariencia original del sistema."
            )
        }
        let applied = names(for: appliedFlags)
        let missing = names(for: requestedFlags & ~appliedFlags)
        if motionDegraded {
            let unavailable = missing.isEmpty
                ? ""
                : LaraL10n.text(
                    en: " Unavailable: \(missing.joined(separator: ", ")).",
                    es: " No disponible: \(missing.joined(separator: ", "))."
                )
            return LaraL10n.text(
                en: "Applied and verified: \(applied.joined(separator: ", ")). The neon cores are active, but SpringBoard did not retain every moving Rainbow phase; no valid light was removed.",
                es: "Aplicado y verificado: \(applied.joined(separator: ", ")). Los núcleos de neón están activos, pero SpringBoard no conservó todas las fases móviles de Arcoíris; no se eliminó ninguna luz válida."
            ) + unavailable
        }
        if missing.isEmpty {
            let style = appliedFlags != 0
                ? " · \(selectedMode.title)"
                : ""
            return LaraL10n.text(
                en: "Applied and verified: \(applied.joined(separator: ", "))\(style).",
                es: "Aplicado y verificado: \(applied.joined(separator: ", "))\(style)."
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
                en: "Aura Studio did not receive a valid single-surface request. Nothing was changed.",
                es: "Aura Studio no recibió una solicitud válida para una sola superficie. No se cambió nada."
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
        case -8:
            return LaraL10n.text(
                en: "Eagle could not resolve the safe Dynamic Island window.",
                es: "Eagle no pudo resolver la ventana segura de Dynamic Island."
            )
        case -9:
            return LaraL10n.text(
                en: "SpringBoard did not provide the UIKit classes required for Island Aura.",
                es: "SpringBoard no proporcionó las clases de UIKit necesarias para Island Aura."
            )
        case -10:
            return LaraL10n.text(
                en: "SpringBoard could not create or position the Island Aura view.",
                es: "SpringBoard no pudo crear o posicionar la vista de Island Aura."
            )
        case -11:
            return LaraL10n.text(
                en: "SpringBoard created the Island host but rejected its light layer.",
                es: "SpringBoard creó el host de Island, pero rechazó su capa luminosa."
            )
        case -12:
            return LaraL10n.text(
                en: "The Island view was created but could not be read back safely. Eagle removed it instead of leaving a partial effect.",
                es: "La vista de Island se creó, pero no pudo verificarse de forma segura. Eagle la eliminó para no dejar un efecto parcial."
            )
        case -13:
            return LaraL10n.text(
                en: "The SpringBoard session is missing its isolated call thread.",
                es: "La sesión de SpringBoard no tiene su hilo aislado de llamadas."
            )
        case -14:
            return LaraL10n.text(
                en: "Island Aura caught a SpringBoard exception. The resulting system state could not be verified, so Eagle cleared the verified badge.",
                es: "Island Aura detectó una excepción de SpringBoard. No se pudo verificar el estado resultante del sistema, por lo que Eagle eliminó el indicador de verificación."
            )
        case -15:
            return LaraL10n.text(
                en: "The thick Island glow is active, but SpringBoard did not retain the moving Rainbow animation. The static core was preserved; choose Glow if you want the verified style.",
                es: "El brillo grueso de Island está activo, pero SpringBoard no conservó la animación Rainbow. El núcleo estático se mantuvo; elige Brillo para usar el estilo verificado."
            )
        case -16:
            return LaraL10n.text(
                en: "SpringBoard did not retain the native Tint background or its gain-map change. Eagle restored and verified the black Glow center; no color layer was left over.",
                es: "SpringBoard no conservó el fondo nativo de Color o el cambio de su mapa de ganancia. Eagle restauró y verificó el centro negro de Brillo; no quedó ninguna capa de color."
            )
        case -17:
            return LaraL10n.text(
                en: "True Tint needs the native adaptive Island background available on this iOS 18 SpringBoard state. Eagle preserved the current aura instead of placing color over music or timer controls.",
                es: "Color real necesita el fondo adaptativo nativo de Island disponible en este estado de SpringBoard de iOS 18. Eagle conservó el aura actual en vez de poner color sobre los controles de música o temporizador."
            )
        case -18:
            return LaraL10n.text(
                en: "Eagle could not verify the complete return to the black system center. The verified badge was cleared. Reopen Eagle on the Home Screen and choose Glow or Remove again.",
                es: "Eagle no pudo verificar el regreso completo al centro negro del sistema. Se eliminó el indicador de verificación. Abre Eagle de nuevo desde Inicio y elige Brillo o Eliminar otra vez."
            )
        case -19:
            return LaraL10n.text(
                en: "SpringBoard did not expose the Home Screen Dock for a verified removal. The Dock badge was cleared and Island was not touched. Return to the Home Screen, reopen Eagle, and choose Remove Dock again.",
                es: "SpringBoard no mostró el Dock de Inicio para verificar su eliminación. Se borró el indicador del Dock y no se modificó Island. Vuelve a Inicio, abre Eagle y elige Eliminar Dock nuevamente."
            )
        case -20:
            return LaraL10n.text(
                en: "SpringBoard did not expose the live Home Screen Dock. Island was not reported as the Dock. Return to the Home Screen once, reopen Aura Studio, and try Dock again.",
                es: "SpringBoard no mostró el Dock activo de Inicio. Island no se marcó como Dock. Vuelve una vez a Inicio, abre Aura Studio y prueba el Dock nuevamente."
            )
        case -21:
            return LaraL10n.text(
                en: "The live Dock was found, but its neon core could not be read back safely. Eagle removed only the unverified Dock layer.",
                es: "Se encontró el Dock activo, pero su núcleo de neón no pudo verificarse de forma segura. Eagle eliminó únicamente la capa del Dock no verificada."
            )
        case -22:
            return LaraL10n.text(
                en: "Aura Studio refused a combined Island and Dock request before changing SpringBoard. Select one profile and apply it separately.",
                es: "Aura Studio rechazó una solicitud combinada de Island y Dock antes de cambiar SpringBoard. Selecciona un perfil y aplícalo por separado."
            )
        case -23:
            return LaraL10n.text(
                en: "The protected SpringBoard session became unavailable before this surface could be changed. Nothing was reported as applied. Export the report, fully close Eagle, and reopen it before retrying.",
                es: "La sesión protegida de SpringBoard dejó de estar disponible antes de cambiar esta superficie. No se indicó nada como aplicado. Exporta el informe, cierra Eagle completamente y vuelve a abrirlo antes de intentarlo de nuevo."
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
