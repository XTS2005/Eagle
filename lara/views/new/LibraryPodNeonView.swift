import SwiftUI
import Darwin
import UIKit

private struct LibraryNeonNotice: Identifiable {
    let id = UUID()
    let message: String
    let offersReport: Bool

    init(message: String, offersReport: Bool = false) {
        self.message = message
        self.offersReport = offersReport
    }
}

private struct LibraryNeonReport: Identifiable {
    let id = UUID()
    let url: URL
    let text: String
    let summary: String
}

private struct LibraryNeonReportView: View {
    @Environment(\.dismiss) private var dismiss
    let report: LibraryNeonReport
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Label(
                        LaraL10n.text(
                            en: "App Library Neon diagnostic report",
                            es: "Reporte de diagnóstico de App Library Neon"
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
            .navigationTitle(LaraL10n.text(
                en: "Library Neon Report",
                es: "Reporte Library Neon"
            ))
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
                        en: "Share App Library Neon report",
                        es: "Compartir reporte de App Library Neon"
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

private enum LibraryNeonPalette: Int, CaseIterable, Identifiable {
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

private enum LibraryNeonDiagnostics {
    static func log(_ stage: String, _ detail: String = "") {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let suffix = detail.isEmpty ? "" : " \(detail)"
        globallogger.log(
            "[\(formatter.string(from: Date()))] " +
            "(eagle.library-neon.apply) stage=\(stage)\(suffix)"
        )
    }
}

@MainActor
private enum LibraryNeonApplyGate {
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

struct LibraryPodNeonView: View {
    @ObservedObject private var mgr = laramgr.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("eagle.libraryNeon.palette")
    private var selectedPaletteRaw = LibraryNeonPalette.orange.rawValue
    @AppStorage("eagle.libraryNeon.activePalette")
    private var activePaletteRaw = 0
    @AppStorage("eagle.libraryNeon.activeSpringBoardPID")
    private var activeSpringBoardPID = 0
    @AppStorage("eagle.libraryNeon.cleanupRequired")
    private var cleanupRequired = false
    @AppStorage("eagle.libraryNeon.lastReportFilename")
    private var lastReportFilename = ""

    @State private var isApplying = false
    @State private var applyStage = ""
    @State private var notice: LibraryNeonNotice?
    @State private var latestReport: LibraryNeonReport?
    @State private var showingReport = false
    @State private var lastDiagnosticSummary = "Manual App Library Neon report"
    @State private var lastOperationID = "none"
    @State private var lastRequestedPalette = 0
    @State private var lastNativeResult: Int32?
    @State private var lastElapsed = 0.0
    @State private var lastTargetPID: Int32 = 0
    @State private var lastCurrentPID: Int32 = 0
    @State private var lastProcessHealthy = true
    @State private var lastTimedOut = false
    @State private var lastProcessError: String?

    private var selectedPalette: LibraryNeonPalette {
        get { LibraryNeonPalette(rawValue: selectedPaletteRaw) ?? .orange }
        nonmutating set { selectedPaletteRaw = newValue.rawValue }
    }

    private var activePalette: LibraryNeonPalette? {
        LibraryNeonPalette(rawValue: activePaletteRaw)
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
        guard result == 0 else { return "" }
        return String(cString: buffer)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                previewCard
                preparationCard
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
        .navigationTitle(LaraL10n.text(
            en: "App Library Neon",
            es: "App Library Neon"
        ))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isApplying)
        .alert(item: $notice) { notice in
            if notice.offersReport {
                Alert(
                    title: Text("App Library Neon"),
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
                    title: Text("App Library Neon"),
                    message: Text(notice.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showingReport) {
            if let latestReport {
                LibraryNeonReportView(report: latestReport)
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
                                en: "Preparing the App Library surfaces safely…",
                                es: "Preparando las superficies de App Library de forma segura…"
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
                    en: "Neon around every App Library category.",
                    es: "Neón alrededor de cada categoría de App Library."
                ))
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(LaraL10n.text(
                    en: "The bright edge follows each rounded pod without changing its icons or background.",
                    es: "El borde luminoso sigue cada recuadro redondeado sin cambiar sus iconos ni su fondo."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.035, green: 0.025, blue: 0.055),
                        selectedPalette.color.opacity(0.19),
                        Color(red: 0.015, green: 0.018, blue: 0.03),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(0..<4, id: \.self) { index in
                        HStack(spacing: 7) {
                            ForEach(0..<4, id: \.self) { icon in
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(previewIconColor(index: index, icon: icon))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                        .padding(11)
                        .background(.black.opacity(0.34))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(selectedPalette.color, lineWidth: 2.4)
                                .shadow(color: selectedPalette.color, radius: 9)
                        }
                    }
                }
                .padding(18)
            }
            .frame(height: 216)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LaraL10n.text(
                en: "App Library Neon preview in \(selectedPalette.title)",
                es: "Vista previa de App Library Neon en \(selectedPalette.title)"
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
                        en: "No verified App Library Neon",
                        es: "Sin App Library Neon verificado"
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

    private func previewIconColor(index: Int, icon: Int) -> Color {
        let colors: [Color] = [.blue, .pink, .orange, .green, .purple, .cyan]
        return colors[(index * 2 + icon) % colors.count].opacity(0.88)
    }

    private var preparationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                LaraL10n.text(
                    en: "Load the real App Library first",
                    es: "Carga primero la App Library real"
                ),
                systemImage: "square.grid.2x2.fill"
            )
            .font(.headline)

            Text(LaraL10n.text(
                en: "1. Visit App Library once after a respring.\n2. Return to Eagle and tap Apply.\n3. Return to App Library to verify every category.",
                es: "1. Visita App Library una vez después de un respring.\n2. Regresa a Eagle y toca Aplicar.\n3. Vuelve a App Library para verificar cada categoría."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(LaraL10n.text(
                en: "If SpringBoard has not created the category views yet, Eagle changes nothing and creates a report.",
                es: "Si SpringBoard todavía no creó las vistas de categorías, Eagle no cambia nada y crea un reporte."
            ))
            .font(.caption)
            .foregroundStyle(.orange)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var paletteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LaraL10n.text(en: "Neon color", es: "Color neón"))
                .font(.headline)

            LazyVGrid(columns: paletteColumns, spacing: 10) {
                ForEach(LibraryNeonPalette.allCases) { palette in
                    Button {
                        selectedPalette = palette
                    } label: {
                        VStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.black.opacity(0.62))
                                .frame(width: 48, height: 34)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(palette.color, lineWidth: 2.2)
                                        .shadow(color: palette.color, radius: 6)
                                }
                            Text(palette.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 78)
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
                    .disabled(isApplying || activePalette != nil || cleanupRequired)
                    .accessibilityLabel(palette.title)
                    .accessibilityAddTraits(
                        palette == selectedPalette ? .isSelected : []
                    )
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var isolationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(LaraL10n.text(
                    en: "Independent App Library surface",
                    es: "Superficie independiente de App Library"
                ))
                .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "This call accepts only SBHLibraryCategoryPodBackgroundView. Dock, Island, Battery X, and Prepare are outside this transaction.",
                    es: "Esta llamada acepta únicamente SBHLibraryCategoryPodBackgroundView. Dock, Isla, Battery X y Preparar quedan fuera de esta transacción."
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
        Button {
            run(palette: selectedPalette.rawValue)
        } label: {
            Label(
                LaraL10n.text(
                    en: "Apply App Library Neon",
                    es: "Aplicar App Library Neon"
                ),
                systemImage: "sparkles.rectangle.stack.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.borderedProminent)
        .tint(selectedPalette.color)
        .disabled(
            isApplying || !mgr.dsready || mgr.rcSafetyLocked ||
            activePalette != nil || cleanupRequired || !isFieldTestDevice
        )
    }

    private var restoreButton: some View {
        Button(role: .destructive) {
            run(palette: 0)
        } label: {
            Label(
                LaraL10n.text(
                    en: "Restore App Library",
                    es: "Restaurar App Library"
                ),
                systemImage: "arrow.counterclockwise"
            )
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.bordered)
        .disabled(
            isApplying || !mgr.dsready || mgr.rcSafetyLocked ||
            !isFieldTestDevice ||
            (activePalette == nil && !cleanupRequired)
        )
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                LaraL10n.text(
                    en: "App Library Neon diagnostics",
                    es: "Diagnóstico de App Library Neon"
                ),
                systemImage: "waveform.path.ecg.rectangle"
            )
            .font(.headline)

            Text(LaraL10n.text(
                en: "Errors automatically create a focused report containing discovery, geometry, verification, and protected-call health.",
                es: "Los errores crean automáticamente un reporte enfocado con descubrimiento, geometría, verificación y salud de la llamada protegida."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack {
                Button(latestReport == nil
                       ? LaraL10n.text(en: "Create Report", es: "Crear reporte")
                       : LaraL10n.text(en: "View Report", es: "Ver reporte")) {
                    if latestReport == nil {
                        latestReport = makeDiagnosticsReport(
                            summary: lastDiagnosticSummary)
                    }
                    showingReport = latestReport != nil
                }
                .buttonStyle(.bordered)

                if let latestReport {
                    ShareLink(item: latestReport.url) {
                        Label(
                            LaraL10n.text(en: "Share", es: "Compartir"),
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func reconcileActiveState() {
        let currentPID = "SpringBoard".withCString { find_process_pid($0) }
        if activePaletteRaw != 0, activePalette == nil {
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
            cleanupRequired = true
            return
        }
        guard currentPID == Int32(activeSpringBoardPID) else {
            LibraryNeonDiagnostics.log(
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
            ? "App Library Neon restore requested"
            : "App Library Neon apply requested"
        LibraryNeonDiagnostics.log(
            "request",
            "op=\(operationID) palette=\(palette) device=\(devicemachine()) " +
            "cleanup=\(cleanupRequired) dsready=\(mgr.dsready) " +
            "safety=\(mgr.rcSafetyLocked)"
        )

        guard !isApplying, LibraryNeonApplyGate.begin() else {
            notice = LibraryNeonNotice(message: LaraL10n.text(
                en: "App Library Neon is still finishing the previous operation.",
                es: "App Library Neon todavía está terminando la operación anterior."
            ))
            return
        }
        guard palette == 0 || (activePalette == nil && !cleanupRequired) else {
            finish(message: LaraL10n.text(
                en: "Restore the current or uncertain Library Neon before applying another color.",
                es: "Restaura el Library Neon actual o incierto antes de aplicar otro color."
            ))
            return
        }
        guard isFieldTestDevice else {
            finish(message: LaraL10n.text(
                en: "App Library Neon sent nothing because this device/build is not in the first field-test allowlist.",
                es: "App Library Neon no envió nada porque este dispositivo y versión no están en la primera lista de prueba."
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
                en: "Prepare Eagle access before applying App Library Neon.",
                es: "Prepara el acceso de Eagle antes de aplicar App Library Neon."
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
                    reason: "App Library Neon fresh session identity check failed " +
                        "(target \(targetPID), current \(currentPID), " +
                        "isolated \(process.creatingExtraThread))",
                    mutationUncertain: false
                )
                return
            }

            let label = "App Library Neon \(operationID)"
            guard mgr.beginExclusiveRemoteCall(label: label) else {
                finish(message: LaraL10n.text(
                    en: "Another protected system operation is still running. Nothing was changed.",
                    es: "Otra operación protegida del sistema todavía está activa. No se cambió nada."
                ))
                return
            }

            applyStage = palette == 0
                ? LaraL10n.text(
                    en: "Restoring only App Library categories…",
                    es: "Restaurando únicamente las categorías de App Library…"
                )
                : LaraL10n.text(
                    en: "Discovering and verifying App Library categories…",
                    es: "Descubriendo y verificando las categorías de App Library…"
                )
            let started = Date()
            var nativeFinished = false
            var hardDeadlineExceeded = false

            let deadlineWork = DispatchWorkItem {
                guard isApplying, !nativeFinished else { return }
                hardDeadlineExceeded = true
                let reason = "App Library Neon exceeded the 60-second safety deadline"
                LibraryNeonDiagnostics.log(
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

            // Persist uncertainty before the native mutation begins. If Eagle
            // is terminated while SpringBoard is being styled, the next
            // launch still exposes Restore instead of showing a false idle
            // state. Verified success or a verified no-mutation result clears
            // this marker below.
            if palette > 0 {
                cleanupRequired = true
            }

            DispatchQueue.global(qos: .userInitiated).async {
                let result = autoreleasepool {
                    eagle_set_library_pod_neon(process, Int32(palette))
                }
                let elapsed = Date().timeIntervalSince(started)
                let processError = process.lastError
                let processHealthy = process.isHealthy
                let timedOut = process.lastCallTimedOut
                let currentPID = "SpringBoard".withCString {
                    find_process_pid($0)
                }
                LibraryNeonDiagnostics.log(
                    "native.end",
                    "op=\(operationID) result=\(result) " +
                    "elapsed=\(String(format: "%.3f", elapsed)) " +
                    "target=\(targetPID) current=\(currentPID) " +
                    "healthy=\(processHealthy) timeout=\(timedOut) " +
                    "error=\(processError ?? "none")"
                )

                DispatchQueue.main.async {
                    nativeFinished = true
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
                             ? "SpringBoard restarted during App Library Neon"
                             : "App Library Neon transport became unhealthy")
                        quarantine(reason: reason, mutationUncertain: true)
                        return
                    }

                    if palette == 0, result == 0 {
                        activePaletteRaw = 0
                        activeSpringBoardPID = 0
                        cleanupRequired = false
                        finish(message: LaraL10n.text(
                            en: "App Library Neon was restored. Dock, Island, Battery X, and Prepare were not changed.",
                            es: "App Library Neon fue restaurado. Dock, Isla, Battery X y Preparar no fueron modificados."
                        ))
                        return
                    }
                    if palette > 0, result == 1 {
                        activePaletteRaw = palette
                        activeSpringBoardPID = Int(targetPID)
                        cleanupRequired = false
                        finish(message: LaraL10n.text(
                            en: "The current App Library category surfaces were styled and verified. Return to App Library to inspect them.",
                            es: "Las superficies actuales de categorías de App Library fueron estilizadas y verificadas. Regresa a App Library para revisarlas."
                        ))
                        return
                    }

                    if result == -7 || result == -12 || result == -23 {
                        quarantine(
                            reason: "App Library Neon returned unverified result \(result)",
                            mutationUncertain: true
                        )
                        return
                    }
                    if palette > 0 {
                        // All remaining native results are either pre-mutation
                        // refusals or a verified visual rollback (-10).
                        cleanupRequired = false
                    }
                    finish(
                        message: message(for: result),
                        offersReport: true,
                        summary: "App Library Neon native result \(result)"
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
                en: "App Library Neon stopped because the protected call could not be verified. No automatic retry will start. Fully close and reopen Eagle before another test. Dock, Island, Battery X, and Prepare were not marked as changed.",
                es: "App Library Neon se detuvo porque la llamada protegida no pudo verificarse. No se iniciará otro intento automático. Cierra Eagle completamente y vuelve a abrirlo antes de otra prueba. Dock, Isla, Battery X y Preparar no se marcaron como modificados."
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
        if let summary { lastDiagnosticSummary = summary }
        guard offersReport else {
            LibraryNeonApplyGate.end()
            isApplying = false
            applyStage = ""
            notice = LibraryNeonNotice(message: message)
            return
        }

        applyStage = LaraL10n.text(
            en: "Creating the App Library Neon report…",
            es: "Creando el reporte de App Library Neon…"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            latestReport = makeDiagnosticsReport(summary: lastDiagnosticSummary)
            LibraryNeonApplyGate.end()
            isApplying = false
            applyStage = ""
            notice = LibraryNeonNotice(
                message: message,
                offersReport: latestReport != nil
            )
        }
    }

    private func message(for result: Int32) -> String {
        switch result {
        case -2:
            return LaraL10n.text(
                en: "SpringBoard did not expose any App Library category backgrounds. Visit App Library, return to Eagle, and try once more. Nothing was changed.",
                es: "SpringBoard no expuso fondos de categorías de App Library. Visita App Library, regresa a Eagle e inténtalo una vez más. No se cambió nada."
            )
        case -3:
            return LaraL10n.text(
                en: "The selected neon color is invalid. Nothing was changed.",
                es: "El color neón seleccionado no es válido. No se cambió nada."
            )
        case -4:
            return LaraL10n.text(
                en: "The protected SpringBoard thread was not isolated. Nothing was changed.",
                es: "El hilo protegido de SpringBoard no estaba aislado. No se cambió nada."
            )
        case -5:
            return LaraL10n.text(
                en: "This first App Library Neon build is limited to iPhone17,1 on iOS 18.6.2 (22G100).",
                es: "Esta primera versión de App Library Neon está limitada a iPhone17,1 con iOS 18.6.2 (22G100)."
            )
        case -6:
            return LaraL10n.text(
                en: "SpringBoard could not create the selected system color. Nothing was changed.",
                es: "SpringBoard no pudo crear el color de sistema seleccionado. No se cambió nada."
            )
        case -8:
            return LaraL10n.text(
                en: "The App Library category hierarchy was missing, too broad, or geometrically ambiguous. Eagle refused to style a partial set. Share the report.",
                es: "La jerarquía de categorías de App Library estaba ausente, era demasiado amplia o geométricamente ambigua. Eagle rechazó estilizar un conjunto parcial. Comparte el reporte."
            )
        case -9:
            return LaraL10n.text(
                en: "At least one category already has a border or shadow. Use Restore before applying another color.",
                es: "Al menos una categoría ya tiene borde o sombra. Usa Restaurar antes de aplicar otro color."
            )
        case -10:
            return LaraL10n.text(
                en: "A category did not verify the neon style. Eagle turned off every attempted border and verified the rollback.",
                es: "Una categoría no verificó el estilo neón. Eagle apagó todos los bordes intentados y verificó la reversión."
            )
        case -13:
            return LaraL10n.text(
                en: "Discovery reached the safe call budget before any visible mutation. Nothing was changed; share the report.",
                es: "El descubrimiento alcanzó el límite seguro de llamadas antes de cualquier mutación visible. No se cambió nada; comparte el reporte."
            )
        default:
            return LaraL10n.text(
                en: "SpringBoard rejected App Library Neon before a verified commit (result \(result)). Nothing was reported as active.",
                es: "SpringBoard rechazó App Library Neon antes de una confirmación verificada (resultado \(result)). No se marcó como activo."
            )
        }
    }

    private var reportDirectory: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("EagleAuraReports", isDirectory: true)
    }

    private func restoreLastReport() {
        guard latestReport == nil,
              !lastReportFilename.isEmpty,
              lastReportFilename == URL(
                fileURLWithPath: lastReportFilename).lastPathComponent else {
            return
        }
        let url = reportDirectory.appendingPathComponent(lastReportFilename)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            lastReportFilename = ""
            return
        }
        latestReport = LibraryNeonReport(
            url: url,
            text: text,
            summary: LaraL10n.text(
                en: "Last saved App Library Neon report",
                es: "Último reporte guardado de App Library Neon"
            )
        )
    }

    private func filteredLogLines() -> [String] {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let logURL = documents.appendingPathComponent("lara.log")
        guard let handle = try? FileHandle(forReadingFrom: logURL) else {
            return []
        }
        defer { try? handle.close() }
        do {
            let end = try handle.seekToEnd()
            let maximumBytes: UInt64 = 384 * 1024
            try handle.seek(toOffset: end > maximumBytes
                            ? end - maximumBytes
                            : 0)
            let text = String(decoding: try handle.readToEnd() ?? Data(), as: UTF8.self)
            let fragments = [
                "(eagle.library-neon.apply)",
                "(eagle.library-neon.native)",
                "RemoteCall",
                "remote call",
                "(rc)",
            ]
            return text.split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { line in
                    fragments.contains { line.localizedCaseInsensitiveContains($0) }
                }
                .suffix(900)
                .map { $0 }
        } catch {
            return ["<log read failed: \(error.localizedDescription)>"]
        }
    }

    private func makeDiagnosticsReport(summary: String) -> LibraryNeonReport? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let logLines = filteredLogLines()
        let report = [
            "Eagle App Library Neon diagnostics",
            "timestamp=\(timestamp)",
            "summary=\(summary)",
            "operationID=\(lastOperationID)",
            "requestedPalette=\(lastRequestedPalette)",
            "nativeResult=\(lastNativeResult.map(String.init) ?? "none")",
            "elapsed=\(String(format: "%.3f", lastElapsed))",
            "device=\(devicemachine())",
            "system=\(UIDevice.current.systemVersion)",
            "build=\(operatingSystemBuild)",
            "targetPID=\(lastTargetPID)",
            "currentPID=\(lastCurrentPID)",
            "processHealthy=\(lastProcessHealthy)",
            "timedOut=\(lastTimedOut)",
            "processError=\(lastProcessError ?? "none")",
            "dsready=\(mgr.dsready)",
            "rcready=\(mgr.rcready)",
            "rcrunning=\(mgr.rcrunning)",
            "safetyLocked=\(mgr.rcSafetyLocked)",
            "safetyReason=\(mgr.rcSafetyReason ?? "none")",
            "activePalette=\(activePaletteRaw)",
            "activeSpringBoardPID=\(activeSpringBoardPID)",
            "cleanupRequired=\(cleanupRequired)",
            "",
            "Filtered App Library Neon / protected-call log:",
            logLines.isEmpty ? "<no matching lines>" : logLines.joined(separator: "\n"),
            "",
        ].joined(separator: "\n")

        do {
            try FileManager.default.createDirectory(
                at: reportDirectory,
                withIntermediateDirectories: true
            )
            let safeTimestamp = timestamp
                .replacingOccurrences(of: ":", with: "-")
            let filename = "Eagle-App-Library-Neon-Diagnostics-\(safeTimestamp).txt"
            let url = reportDirectory.appendingPathComponent(filename)
            try report.write(to: url, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
            lastReportFilename = filename
            pruneReports(keeping: 8)
            return LibraryNeonReport(url: url, text: report, summary: summary)
        } catch {
            LibraryNeonDiagnostics.log(
                "report.error", "value=\(error.localizedDescription)"
            )
            return nil
        }
    }

    private func pruneReports(keeping limit: Int) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: reportDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let matching = files.filter {
            $0.lastPathComponent.hasPrefix(
                "Eagle-App-Library-Neon-Diagnostics-")
        }
        let sorted = matching.sorted { left, right in
            let leftDate = (try? left.resourceValues(
                forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let rightDate = (try? right.resourceValues(
                forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return leftDate > rightDate
        }
        for file in sorted.dropFirst(limit) {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
