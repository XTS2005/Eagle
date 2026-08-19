import SwiftUI
import Darwin
import UIKit

private struct BatteryXNotice: Identifiable {
    let id = UUID()
    let message: String
    let offersReport: Bool

    init(message: String, offersReport: Bool = false) {
        self.message = message
        self.offersReport = offersReport
    }
}

private struct BatteryXReport: Identifiable {
    let id = UUID()
    let url: URL
    let text: String
    let summary: String
}

private struct BatteryXReportView: View {
    @Environment(\.dismiss) private var dismiss
    let report: BatteryXReport
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Label(
                        LaraL10n.text(
                            en: "Battery X diagnostic report",
                            es: "Reporte de diagnóstico de Batería X"
                        ),
                        systemImage: "doc.text.magnifyingglass"
                    )
                    .font(.headline)

                    Text(report.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(report.text)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
            }
            .navigationTitle(LaraL10n.text(en: "Battery X Report", es: "Reporte Batería X"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LaraL10n.text(en: "Close", es: "Cerrar")) {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ShareLink(item: report.url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(LaraL10n.text(
                        en: "Share Battery X report",
                        es: "Compartir reporte de Batería X"
                    ))

                    Button {
                        UIPasteboard.general.string = report.text
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        copied = true
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                    .accessibilityLabel(copied
                        ? LaraL10n.text(en: "Copied", es: "Copiado")
                        : LaraL10n.text(en: "Copy report", es: "Copiar reporte"))
                }
            }
        }
    }
}

private enum BatteryXPalette: Int, CaseIterable, Identifiable {
    case red = 1
    case blue
    case pink
    case green
    case purple
    case orange

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .red: return LaraL10n.text(en: "Signal Red", es: "Rojo señal")
        case .blue: return LaraL10n.text(en: "Electric Blue", es: "Azul eléctrico")
        case .pink: return LaraL10n.text(en: "Hot Pink", es: "Rosa intenso")
        case .green: return LaraL10n.text(en: "Acid Green", es: "Verde ácido")
        case .purple: return LaraL10n.text(en: "Ultra Violet", es: "Ultravioleta")
        case .orange: return LaraL10n.text(en: "Amber", es: "Ámbar")
        }
    }

    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .pink: return .pink
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        }
    }
}

private enum BatteryXDiagnostics {
    static func log(_ stage: String, _ detail: String = "") {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let suffix = detail.isEmpty ? "" : " \(detail)"
        globallogger.log(
            "[\(formatter.string(from: Date()))] " +
            "(eagle.battery-x.apply) stage=\(stage)\(suffix)"
        )
    }
}

@MainActor
private enum BatteryXApplyGate {
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

struct BatteryXAuraView: View {
    @ObservedObject private var mgr = laramgr.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("eagle.batteryX.palette")
    private var selectedPaletteRaw = BatteryXPalette.red.rawValue
    @AppStorage("eagle.batteryX.activePalette")
    private var activePaletteRaw = 0
    @AppStorage("eagle.batteryX.activeSpringBoardPID")
    private var activeSpringBoardPID = 0
    @AppStorage("eagle.batteryX.cleanupRequired")
    private var cleanupRequired = false
    @AppStorage("eagle.batteryX.lastReportFilename")
    private var lastReportFilename = ""

    @State private var isApplying = false
    @State private var applyStage = ""
    @State private var notice: BatteryXNotice?
    @State private var latestReport: BatteryXReport?
    @State private var showingReport = false
    @State private var lastDiagnosticSummary = "Manual Battery X report"
    @State private var lastOperationID = "none"
    @State private var lastRequestedPalette = 0
    @State private var lastNativeResult: Int32?
    @State private var lastElapsed = 0.0
    @State private var lastTargetPID: Int32 = 0
    @State private var lastCurrentPID: Int32 = 0
    @State private var lastProcessHealthy = true
    @State private var lastTimedOut = false
    @State private var lastProcessError: String?

    private var selectedPalette: BatteryXPalette {
        get { BatteryXPalette(rawValue: selectedPaletteRaw) ?? .red }
        nonmutating set { selectedPaletteRaw = newValue.rawValue }
    }

    private var activePalette: BatteryXPalette? {
        BatteryXPalette(rawValue: activePaletteRaw)
    }

    private var paletteColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 10)]
        }
        return [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ]
    }

    // First field rollout is intentionally exact. Expanding this allowlist
    // requires a physical result from another model/build, not an assumption
    // based on screen size or marketing generation.
    private var isFieldTestDevice: Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return devicemachine() == "iPhone17,1" &&
            version.majorVersion == 18 &&
            version.minorVersion == 6 &&
            version.patchVersion == 2 &&
            operatingSystemBuild == "22G100"
    }

    private var operatingSystemBuild: String {
        var length = 0
        guard sysctlbyname(
            "kern.osversion", nil, &length, nil, 0) == 0,
              length > 1 else { return "" }
        var buffer = [CChar](repeating: 0, count: length)
        let result = buffer.withUnsafeMutableBytes { bytes in
            sysctlbyname(
                "kern.osversion", bytes.baseAddress, &length, nil, 0)
        }
        guard result == 0 else {
            return ""
        }
        return String(cString: buffer)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                previewCard
                paletteCard
                isolationCard

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
        .accessibilityHidden(isApplying)
        .navigationTitle("Battery X")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isApplying)
        .alert(item: $notice) { notice in
            if notice.offersReport {
                Alert(
                    title: Text("Battery X"),
                    message: Text(notice.message),
                    primaryButton: .default(Text(LaraL10n.text(
                        en: "View Report",
                        es: "Ver reporte"
                    ))) {
                        DispatchQueue.main.async {
                            showingReport = latestReport != nil
                        }
                    },
                    secondaryButton: .cancel(Text(LaraL10n.text(
                        en: "Close",
                        es: "Cerrar"
                    )))
                )
            } else {
                Alert(
                    title: Text("Battery X"),
                    message: Text(notice.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showingReport) {
            if let latestReport {
                BatteryXReportView(report: latestReport)
            }
        }
        .overlay {
            if isApplying {
                ZStack {
                    Color.black.opacity(0.14).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(applyStage.isEmpty
                             ? LaraL10n.text(
                                en: "Preparing the battery surface safely…",
                                es: "Preparando la superficie de batería de forma segura…"
                             )
                             : applyStage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(22)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(applyStage)
                }
            }
        }
        .onAppear {
            reconcileActiveState()
            restoreLastReport()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { reconcileActiveState() }
        }
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 5) {
                Text(LaraL10n.text(
                    en: "A neon X, anchored to the battery.",
                    es: "Una X neón, anclada a la batería."
                ))
                    .font(.title2.bold())
                Text(LaraL10n.text(
                    en: "The X follows the system battery glyph without touching Wi-Fi, Island, or Dock.",
                    es: "La X sigue el icono de batería del sistema sin tocar Wi‑Fi, Isla ni Dock."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.025, green: 0.035, blue: 0.07),
                        selectedPalette.color.opacity(0.18),
                        Color(red: 0.015, green: 0.018, blue: 0.035),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack {
                    Text("9:41")
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "cellularbars")
                        Image(systemName: "wifi")
                        batteryXGlyph
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 18)
            }
            .frame(height: 116)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LaraL10n.text(
                en: "Battery X preview in \(selectedPalette.title)",
                es: "Vista previa de Battery X en \(selectedPalette.title)"
            ))

            HStack(spacing: 7) {
                Circle()
                    .fill(cleanupRequired
                          ? Color.orange
                          : (activePalette == nil
                             ? Color.secondary.opacity(0.5)
                             : Color.green))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(activePalette.map {
                    LaraL10n.text(
                        en: "Last apply verified in this SpringBoard session · \($0.title)",
                        es: "Última aplicación verificada en esta sesión de SpringBoard · \($0.title)"
                    )
                } ?? (cleanupRequired
                    ? LaraL10n.text(
                        en: "Cleanup required before another apply",
                        es: "Se requiere limpieza antes de otra aplicación"
                    )
                    : LaraL10n.text(
                        en: "No verified Battery X",
                        es: "Sin Battery X verificada"
                    )))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var batteryXGlyph: some View {
        ZStack {
            HStack(spacing: 2) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(.white.opacity(0.68), lineWidth: 1.5)
                        .frame(width: 29, height: 14)
                    RoundedRectangle(cornerRadius: 2.4, style: .continuous)
                        .fill(.white.opacity(0.22))
                        .frame(width: 18, height: 9)
                        .padding(.leading, 2.5)
                }
                Capsule()
                    .fill(.white.opacity(0.62))
                    .frame(width: 2.5, height: 6)
            }

            ForEach([-1.0, 1.0], id: \.self) { direction in
                Capsule()
                    .fill(selectedPalette.color)
                    .frame(width: 27, height: 2.7)
                    .rotationEffect(.degrees(27 * direction))
                    .shadow(color: selectedPalette.color, radius: 3.5)
            }
        }
        .frame(width: 34, height: 20)
    }

    private var paletteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LaraL10n.text(en: "Neon color", es: "Color neón"))
                .font(.headline)

            LazyVGrid(columns: paletteColumns, spacing: 10) {
                ForEach(BatteryXPalette.allCases) { palette in
                    Button {
                        selectedPalette = palette
                    } label: {
                        VStack(spacing: 7) {
                            Circle()
                                .fill(palette.color)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Circle().strokeBorder(.white.opacity(0.62), lineWidth: 1)
                                }
                                .shadow(color: palette.color.opacity(0.72), radius: 6)
                            Text(palette.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 76)
                        .padding(.vertical, 8)
                        .background(
                            palette == selectedPalette
                                ? palette.color.opacity(0.15)
                                : Color.primary.opacity(0.035)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    palette == selectedPalette
                                        ? palette.color.opacity(0.8)
                                        : .clear,
                                    lineWidth: 1.5
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(palette.title)
                    .accessibilityAddTraits(
                        palette == selectedPalette ? .isSelected : []
                    )
                }
            }

            Text(LaraL10n.text(
                en: "Beta 9 uses named system colors so the remote call avoids custom floating-point color construction.",
                es: "Beta 9 usa colores del sistema para evitar construir colores personalizados con punto flotante durante la llamada remota."
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var isolationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isFieldTestDevice
                  ? "checkmark.shield.fill"
                  : "exclamationmark.triangle.fill")
                .foregroundStyle(isFieldTestDevice ? Color.green : Color.orange)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(isFieldTestDevice
                     ? LaraL10n.text(
                        en: "Independent battery surface",
                        es: "Superficie de batería independiente"
                     )
                     : LaraL10n.text(
                        en: "Hardware not allowlisted",
                        es: "Hardware fuera de la lista permitida"
                     ))
                    .font(.subheadline.weight(.semibold))
                Text(isFieldTestDevice
                     ? LaraL10n.text(
                        en: "Only a tagged child inside the live battery glyph is staged, read back, and committed. Battery colors, Island, Dock, and Prepare are outside this transaction.",
                        es: "Solo se prepara, verifica y confirma una vista etiquetada dentro del icono activo de batería. Los colores de batería, Isla, Dock y Preparar quedan fuera de esta transacción."
                     )
                     : LaraL10n.text(
                        en: "The first live test is limited to iPhone 16 Pro (iPhone17,1) on iOS 18.6.2. This screen sends no native call on other configurations.",
                        es: "La primera prueba en vivo está limitada al iPhone 16 Pro (iPhone17,1) con iOS 18.6.2. Esta pantalla no envía llamadas nativas en otras configuraciones."
                     ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var applyButton: some View {
        Button {
            run(palette: selectedPalette.rawValue)
        } label: {
            Label(
                activePalette == selectedPalette
                    ? LaraL10n.text(en: "Reapply Battery X", es: "Volver a aplicar Battery X")
                    : LaraL10n.text(en: "Apply Battery X", es: "Aplicar Battery X"),
                systemImage: "xmark"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(selectedPalette.color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(
            isApplying || !isFieldTestDevice || cleanupRequired ||
            !mgr.dsready || mgr.rcSafetyLocked
        )
        .opacity(
            !isFieldTestDevice || cleanupRequired ||
                !mgr.dsready || mgr.rcSafetyLocked ? 0.48 : 1
        )
    }

    private var restoreButton: some View {
        Button {
            run(palette: 0)
        } label: {
            Label(
                LaraL10n.text(en: "Remove Battery X", es: "Quitar Battery X"),
                systemImage: "arrow.counterclockwise"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(
            isApplying || !isFieldTestDevice ||
            (activePalette == nil && !cleanupRequired) ||
            !mgr.dsready || mgr.rcSafetyLocked
        )
        .opacity(activePalette == nil && !cleanupRequired ? 0.52 : 1)
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                LaraL10n.text(
                    en: "Battery X diagnostics",
                    es: "Diagnóstico de Batería X"
                ),
                systemImage: "doc.text.magnifyingglass"
            )
            .font(.headline)

            Text(LaraL10n.text(
                en: "If Apply returns an error, Eagle creates a focused report here with the Battery X and protected-call trace.",
                es: "Si Aplicar devuelve un error, Eagle crea aquí un reporte específico con el registro de Batería X y la llamada protegida."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    reportButton
                    if let latestReport {
                        reportShareButton(latestReport)
                    }
                }

                VStack(spacing: 10) {
                    reportButton
                        .frame(maxWidth: .infinity)
                    if let latestReport {
                        reportShareButton(latestReport)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var reportButton: some View {
        Button {
            if latestReport == nil {
                latestReport = makeDiagnosticsReport(
                    summary: lastDiagnosticSummary
                )
            }
            DispatchQueue.main.async {
                showingReport = latestReport != nil
            }
        } label: {
            Label(
                latestReport == nil
                    ? LaraL10n.text(en: "Create Report", es: "Crear reporte")
                    : LaraL10n.text(en: "View Report", es: "Ver reporte"),
                systemImage: latestReport == nil
                    ? "doc.badge.plus"
                    : "doc.text.magnifyingglass"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private func reportShareButton(_ report: BatteryXReport) -> some View {
        ShareLink(item: report.url) {
            Label(
                LaraL10n.text(en: "Share", es: "Compartir"),
                systemImage: "square.and.arrow.up"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func reconcileActiveState() {
        let currentPID = "SpringBoard".withCString { find_process_pid($0) }
        if activePaletteRaw != 0, activePalette == nil {
            BatteryXDiagnostics.log(
                "state.invalid", "palette=\(activePaletteRaw)"
            )
            cleanupRequired = true
            activePaletteRaw = 0
            activeSpringBoardPID = 0
        }
        guard activePaletteRaw != 0 else {
            activeSpringBoardPID = 0
            return
        }
        guard activeSpringBoardPID > 0 else {
            cleanupRequired = true
            return
        }
        guard currentPID > 0 else {
            BatteryXDiagnostics.log(
                "state.pid-unavailable", "savedPID=\(activeSpringBoardPID)"
            )
            cleanupRequired = true
            return
        }
        guard currentPID == Int32(activeSpringBoardPID) else {
            BatteryXDiagnostics.log(
                "state.expired",
                "savedPID=\(activeSpringBoardPID) currentPID=\(currentPID)"
            )
            activePaletteRaw = 0
            activeSpringBoardPID = 0
            cleanupRequired = false
            return
        }
    }

    private func run(palette: Int) {
        let operationID = String(UUID().uuidString.prefix(8))
        lastOperationID = operationID
        lastRequestedPalette = palette
        lastNativeResult = nil
        lastElapsed = 0
        lastTargetPID = 0
        lastCurrentPID = 0
        lastProcessHealthy = true
        lastTimedOut = false
        lastProcessError = nil
        lastDiagnosticSummary = palette == 0
            ? "Battery X remove requested"
            : "Battery X apply requested"
        BatteryXDiagnostics.log(
            "request",
            "op=\(operationID) palette=\(palette) device=\(devicemachine()) " +
            "cleanup=\(cleanupRequired) " +
            "dsready=\(mgr.dsready) safety=\(mgr.rcSafetyLocked)"
        )

        guard !isApplying, BatteryXApplyGate.begin() else {
            notice = BatteryXNotice(message: LaraL10n.text(
                en: "Battery X is still finishing the previous operation.",
                es: "Battery X todavía está terminando la operación anterior."
            ))
            return
        }
        guard palette == 0 || !cleanupRequired else {
            finish(message: LaraL10n.text(
                en: "Remove the uncertain Battery X state before applying another color.",
                es: "Quita el estado incierto de Battery X antes de aplicar otro color."
            ))
            return
        }
        guard isFieldTestDevice else {
            finish(message: LaraL10n.text(
                en: "Battery X sent nothing because this device/build is not in the first field-test allowlist.",
                es: "Battery X no envió nada porque este dispositivo y versión no están en la primera lista de prueba."
            ))
            return
        }
        guard !isdebugged() else {
            finish(message: LaraL10n.text(
                en: "Stop the Xcode run and open Eagle manually before changing SpringBoard.",
                es: "Detén la ejecución de Xcode y abre Eagle manualmente antes de cambiar SpringBoard."
            ))
            return
        }
        guard mgr.dsready else {
            finish(message: LaraL10n.text(
                en: "Prepare Eagle access before applying Battery X.",
                es: "Prepara el acceso de Eagle antes de aplicar Battery X."
            ))
            return
        }
        guard !mgr.rcSafetyLocked else {
            finish(message: mgr.rcSafetyReason ?? LaraL10n.text(
                en: "The protected call channel is safety locked. Fully close and reopen Eagle before another test.",
                es: "El canal protegido está bloqueado por seguridad. Cierra Eagle completamente y vuelve a abrirlo antes de otra prueba."
            ))
            return
        }

        isApplying = true
        applyStage = LaraL10n.text(
            en: "Preparing a fresh SpringBoard session…",
            es: "Preparando una sesión nueva de SpringBoard…"
        )

        mgr.prepareFreshRemoteCall(
            process: "SpringBoard",
            timeout: 20
        ) { process, sessionError in
            guard let process else {
                let reason = sessionError ??
                    "Fresh SpringBoard session was unavailable"
                let isReadOnlyPreflight =
                    reason.localizedCaseInsensitiveContains("access is not ready") ||
                    reason.localizedCaseInsensitiveContains("still running") ||
                    reason.localizedCaseInsensitiveContains("safety locked")
                if isReadOnlyPreflight {
                    finish(message: reason)
                } else {
                    quarantine(reason: reason, mutationUncertain: false)
                }
                return
            }

            let targetPID = process.pid
            let currentPID = "SpringBoard".withCString { find_process_pid($0) }
            guard targetPID > 0,
                  targetPID == currentPID,
                  process.creatingExtraThread else {
                quarantine(
                    reason: "Battery X fresh session identity check failed " +
                        "(target \(targetPID), current \(currentPID), " +
                        "isolated \(process.creatingExtraThread))",
                    mutationUncertain: false
                )
                return
            }

            let label = "Battery X \(operationID)"
            guard mgr.beginExclusiveRemoteCall(label: label) else {
                finish(message: LaraL10n.text(
                    en: "Another protected system operation is still running. Nothing was changed.",
                    es: "Otra operación protegida del sistema todavía está activa. No se cambió nada."
                ))
                return
            }

            applyStage = palette == 0
                ? LaraL10n.text(
                    en: "Removing only Battery X…",
                    es: "Quitando únicamente Battery X…"
                )
                : LaraL10n.text(
                    en: "Staging and verifying Battery X…",
                    es: "Preparando y verificando Battery X…"
                )
            let started = Date()
            var nativeFinished = false
            var hardDeadlineExceeded = false

            let progressWork = DispatchWorkItem {
                guard isApplying, !nativeFinished else { return }
                applyStage = LaraL10n.text(
                    en: "SpringBoard is responding · verifying the live battery…",
                    es: "SpringBoard está respondiendo · verificando la batería activa…"
                )
                BatteryXDiagnostics.log(
                    "native.progress", "op=\(operationID) elapsed=10"
                )
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 10,
                execute: progressWork
            )

            let deadlineWork = DispatchWorkItem {
                guard isApplying, !nativeFinished else { return }
                hardDeadlineExceeded = true
                let reason = "Battery X exceeded the 60-second safety deadline"
                BatteryXDiagnostics.log(
                    "native.deadline", "op=\(operationID) elapsed=60"
                )
                applyStage = LaraL10n.text(
                    en: "Still waiting safely · no automatic retry will start…",
                    es: "Aún esperando de forma segura · no se iniciará otro intento automático…"
                )
                cleanupRequired = true
                activePaletteRaw = 0
                activeSpringBoardPID = 0
                mgr.quarantineRemoteCall(reason: reason)
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 60,
                execute: deadlineWork
            )

            DispatchQueue.global(qos: .userInitiated).async {
                let result = autoreleasepool {
                    eagle_set_battery_x_aura(process, Int32(palette))
                }
                let elapsed = Date().timeIntervalSince(started)
                let processError = process.lastError
                let processHealthy = process.isHealthy
                let timedOut = process.lastCallTimedOut
                let currentPID = "SpringBoard".withCString {
                    find_process_pid($0)
                }
                BatteryXDiagnostics.log(
                    "native.end",
                    "op=\(operationID) result=\(result) " +
                    "elapsed=\(String(format: "%.3f", elapsed)) " +
                    "target=\(targetPID) current=\(currentPID) " +
                    "healthy=\(processHealthy) timeout=\(timedOut) " +
                    "error=\(processError ?? "none")"
                )

                DispatchQueue.main.async {
                    nativeFinished = true
                    progressWork.cancel()
                    deadlineWork.cancel()
                    mgr.endExclusiveRemoteCall(label: label)

                    lastNativeResult = result
                    lastElapsed = elapsed
                    lastTargetPID = targetPID
                    lastCurrentPID = currentPID
                    lastProcessHealthy = processHealthy
                    lastTimedOut = timedOut
                    lastProcessError = processError

                    let livePID = "SpringBoard".withCString {
                        find_process_pid($0)
                    }
                    if hardDeadlineExceeded ||
                        livePID != targetPID ||
                        currentPID != targetPID ||
                        !processHealthy ||
                        timedOut ||
                        processError?.isEmpty == false {
                        let reason = processError ??
                            (livePID != targetPID
                             ? "SpringBoard restarted during Battery X"
                             : "Battery X transport became unhealthy")
                        quarantine(reason: reason, mutationUncertain: true)
                        return
                    }

                    if palette == 0, result == 0 {
                        activePaletteRaw = 0
                        activeSpringBoardPID = 0
                        cleanupRequired = false
                        finish(message: LaraL10n.text(
                            en: "Battery X was removed. Island and Dock were not changed.",
                            es: "Battery X fue eliminada. Isla y Dock no cambiaron."
                        ))
                        return
                    }
                    if palette > 0, result == 1 {
                        activePaletteRaw = palette
                        activeSpringBoardPID = Int(targetPID)
                        cleanupRequired = false
                        finish(message: LaraL10n.text(
                            en: "Battery X was applied and verified on the live system battery. Island and Dock were not changed.",
                            es: "Battery X fue aplicada y verificada sobre la batería activa del sistema. Isla y Dock no cambiaron."
                        ))
                        return
                    }

                    if result == -7 || result == -12 || result == -23 {
                        quarantine(
                            reason: "Battery X returned unverified result \(result)",
                            mutationUncertain: true
                        )
                        return
                    }

                    finish(
                        message: message(for: result),
                        offersReport: true,
                        summary: "Battery X native result \(result)"
                    )
                }
            }
        }
    }

    private func quarantine(reason: String, mutationUncertain: Bool) {
        if mutationUncertain {
            cleanupRequired = true
            activePaletteRaw = 0
            activeSpringBoardPID = 0
        }
        mgr.quarantineRemoteCall(reason: reason)
        finish(
            message: LaraL10n.text(
                en: "Battery X stopped because the protected call could not be verified. No automatic retry will start. Fully close and reopen Eagle before another test. Island and Dock were not marked as changed.",
                es: "Battery X se detuvo porque la llamada protegida no pudo verificarse. No se iniciará otro intento automático. Cierra Eagle completamente y vuelve a abrirlo antes de otra prueba. Isla y Dock no se marcaron como cambiados."
            ),
            offersReport: true,
            summary: reason
        )
    }

    private func finish(
        message: String,
        offersReport: Bool = false,
        summary: String? = nil
    ) {
        if let summary {
            lastDiagnosticSummary = summary
        }
        guard offersReport else {
            BatteryXApplyGate.end()
            isApplying = false
            applyStage = ""
            notice = BatteryXNotice(message: message)
            return
        }

        // stdout from the target arrives through a Pipe callback. Give that
        // callback one short main-runloop turn before freezing this attempt's
        // report, so discovery/target/result are not omitted from the file.
        // Keep the local gate held until then so a second tap cannot replace
        // this attempt's operation ID/result while its report is being built.
        applyStage = LaraL10n.text(
            en: "Creating the Battery X report…",
            es: "Creando el reporte de Batería X…"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            latestReport = makeDiagnosticsReport(
                summary: lastDiagnosticSummary
            )
            BatteryXApplyGate.end()
            isApplying = false
            applyStage = ""
            notice = BatteryXNotice(
                message: message,
                offersReport: latestReport != nil
            )
        }
    }

    private func restoreLastReport() {
        guard latestReport == nil,
              !lastReportFilename.isEmpty,
              lastReportFilename == URL(fileURLWithPath: lastReportFilename).lastPathComponent else {
            return
        }
        let url = reportDirectory.appendingPathComponent(lastReportFilename)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            lastReportFilename = ""
            return
        }
        latestReport = BatteryXReport(
            url: url,
            text: text,
            summary: LaraL10n.text(
                en: "Last saved Battery X report",
                es: "Último reporte guardado de Batería X"
            )
        )
    }

    private var reportDirectory: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return documents.appendingPathComponent(
            "EagleAuraReports",
            isDirectory: true
        )
    }

    private func filteredReportLogLines(
        matching fragments: [String]
    ) -> [String] {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let logURL = documents.appendingPathComponent("lara.log")
        var sourceLines: [String] = []
        if let handle = try? FileHandle(forReadingFrom: logURL) {
            defer { try? handle.close() }
            do {
                let end = try handle.seekToEnd()
                let maximumBytes: UInt64 = 384 * 1024
                try handle.seek(toOffset: end > maximumBytes
                    ? end - maximumBytes
                    : 0)
                let data = try handle.readToEnd() ?? Data()
                sourceLines = String(decoding: data, as: UTF8.self)
                    .components(separatedBy: .newlines)
            } catch {
                sourceLines = []
            }
        }
        if sourceLines.isEmpty {
            sourceLines = globallogger.logs.flatMap {
                $0.components(separatedBy: .newlines)
            }
        }
        return Array(sourceLines.filter { line in
            fragments.contains { fragment in
                line.localizedCaseInsensitiveContains(fragment)
            }
        }.suffix(900))
    }

    private func makeDiagnosticsReport(summary: String) -> BatteryXReport? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let relevantFragments = [
            "eagle.battery-x",
            "eagle.battery.native",
            "(rc)",
            "remote call",
            "RemoteCall",
        ]
        let lines = filteredReportLogLines(matching: relevantFragments)
        let paletteName = BatteryXPalette(rawValue: lastRequestedPalette)?.title
            ?? (lastRequestedPalette == 0 ? "remove" : "unknown")
        let header = [
            EagleSupportSnapshot.makeText(),
            "",
            "Eagle Battery X diagnostics",
            "timestamp=\(timestamp)",
            "summary=\(summary)",
            "operation=\(lastOperationID)",
            "request=palette:\(lastRequestedPalette) name:\(paletteName)",
            "nativeResult=\(lastNativeResult.map(String.init) ?? "none")",
            "elapsed=\(String(format: "%.3f", lastElapsed))",
            "targetSpringBoardPID=\(lastTargetPID)",
            "currentSpringBoardPID=\(lastCurrentPID)",
            "liveSpringBoardPID=\("SpringBoard".withCString { find_process_pid($0) })",
            "processHealthy=\(lastProcessHealthy)",
            "processTimedOut=\(lastTimedOut)",
            "processError=\(lastProcessError ?? "none")",
            "dsready=\(mgr.dsready)",
            "rcrunning=\(mgr.rcrunning)",
            "rcready=\(mgr.rcready)",
            "rcSafetyLocked=\(mgr.rcSafetyLocked)",
            "rcSafetyReason=\(mgr.rcSafetyReason ?? "none")",
            "activePalette=\(activePaletteRaw)",
            "activeSpringBoardPID=\(activeSpringBoardPID)",
            "cleanupRequired=\(cleanupRequired)",
            "--- filtered log ---",
        ]
        let text = (header + lines).joined(separator: "\n") + "\n"
        let filename = "Eagle-Battery-X-Diagnostics-" +
            timestamp.replacingOccurrences(of: ":", with: "-") + ".txt"
        let url = reportDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.createDirectory(
                at: reportDirectory,
                withIntermediateDirectories: true,
                attributes: [
                    .protectionKey:
                        FileProtectionType.completeUntilFirstUserAuthentication,
                ]
            )
            try text.write(to: url, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes(
                [
                    .protectionKey:
                        FileProtectionType.completeUntilFirstUserAuthentication,
                ],
                ofItemAtPath: url.path
            )
            lastReportFilename = filename
            BatteryXDiagnostics.log(
                "diagnostics.ready",
                "path=\(filename) lines=\(lines.count)"
            )
            return BatteryXReport(
                url: url,
                text: text,
                summary: summary
            )
        } catch {
            BatteryXDiagnostics.log(
                "diagnostics.failed",
                "error=\(error.localizedDescription)"
            )
            return nil
        }
    }

    private func message(for result: Int32) -> String {
        switch result {
        case -2:
            return LaraL10n.text(
                en: "SpringBoard did not expose a live battery glyph. Visit the Home Screen, reopen Eagle, and try again.",
                es: "SpringBoard no mostró un icono activo de batería. Visita la pantalla de inicio, vuelve a abrir Eagle e inténtalo otra vez."
            )
        case -3:
            return LaraL10n.text(
                en: "The selected Battery X color is invalid. Nothing was changed.",
                es: "El color seleccionado para Battery X no es válido. No se cambió nada."
            )
        case -4:
            return LaraL10n.text(
                en: "The protected session did not provide an isolated thread. Nothing was changed.",
                es: "La sesión protegida no proporcionó un hilo aislado. No se cambió nada."
            )
        case -5:
            return LaraL10n.text(
                en: "Battery X currently supports only the verified iOS 17/18 native contract.",
                es: "Battery X solo admite por ahora el contrato nativo verificado de iOS 17/18."
            )
        case -6:
            return LaraL10n.text(
                en: "SpringBoard could not create the selected system color. Nothing was changed.",
                es: "SpringBoard no pudo crear el color del sistema seleccionado. No se cambió nada."
            )
        case -8:
            return LaraL10n.text(
                en: "Eagle found battery structures but no visible drawable glyph with safe geometry. Nothing was changed.",
                es: "Eagle encontró estructuras de batería, pero ningún icono visible con geometría segura. No se cambió nada."
            )
        case -9:
            return LaraL10n.text(
                en: "The existing Battery X state could not be read safely. The previous appearance was preserved.",
                es: "No se pudo leer con seguridad el estado existente de Battery X. Se conservó la apariencia anterior."
            )
        case -10:
            return LaraL10n.text(
                en: "The new Battery X candidate did not verify and was removed. The previous appearance was preserved.",
                es: "La nueva candidata de Battery X no se verificó y fue eliminada. Se conservó la apariencia anterior."
            )
        case -11:
            return LaraL10n.text(
                en: "Battery X rejected the update and verified its rollback. You may retry with a fresh session.",
                es: "Battery X rechazó la actualización y verificó la reversión. Puedes intentarlo de nuevo con una sesión nueva."
            )
        case -13:
            return LaraL10n.text(
                en: "Battery discovery reached its safe call limit before changing anything. Open the report and share it so Eagle can identify the remaining host.",
                es: "El descubrimiento de la batería alcanzó su límite seguro antes de cambiar nada. Abre y comparte el reporte para que Eagle pueda identificar el host restante."
            )
        default:
            return LaraL10n.text(
                en: "SpringBoard rejected Battery X before a verified commit. Nothing was reported as active.",
                es: "SpringBoard rechazó Battery X antes de una confirmación verificada. No se marcó como activa."
            )
        }
    }
}
