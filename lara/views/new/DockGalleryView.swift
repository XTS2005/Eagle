import SwiftUI
import UIKit

private enum DockGalleryStyle: Int, CaseIterable, Identifiable {
    case bubblegum = 15
    case springfield = 16
    case bikiniBottom = 17

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .bubblegum:
            return LaraL10n.text(en: "Bubblegum", es: "Chicle")
        case .springfield:
            return "Springfield"
        case .bikiniBottom:
            return LaraL10n.text(en: "Bikini Bottom", es: "Fondo de Bikini")
        }
    }
    var subtitle: String {
        switch self {
        case .bubblegum:
            return LaraL10n.text(
                en: "Pink and yellow bubbles",
                es: "Burbujas rosas y amarillas"
            )
        case .springfield:
            return LaraL10n.text(
                en: "Bright blue animated city",
                es: "Ciudad animada azul brillante"
            )
        case .bikiniBottom:
            return LaraL10n.text(
                en: "Colorful underwater neighborhood",
                es: "Vecindario submarino colorido"
            )
        }
    }
    var assetName: String {
        switch self {
        case .bubblegum: return "DockGalleryBubblegum"
        case .springfield: return "DockGallerySpringfield"
        case .bikiniBottom: return "DockGalleryBikiniBottom"
        }
    }
    var accent: Color {
        switch self {
        case .bubblegum:
            return Color(red: 1.0, green: 0.18, blue: 0.62)
        case .springfield:
            return Color(red: 0.0, green: 0.64, blue: 1.0)
        case .bikiniBottom:
            return Color(red: 0.0, green: 0.75, blue: 0.92)
        }
    }
    var rgb: (Int32, Int32, Int32) {
        switch self {
        case .bubblegum: return (255, 45, 158)
        case .springfield: return (0, 164, 255)
        case .bikiniBottom: return (0, 191, 235)
        }
    }
}

private final class DockGalleryRemoteCallBox: @unchecked Sendable {
    let value: RemoteCall

    init(_ value: RemoteCall) {
        self.value = value
    }
}

private struct DockGalleryNativeResponse: @unchecked Sendable {
    let result: Int32
    let targetPID: Int32
    let springBoardPID: Int32
    let healthy: Bool
    let timedOut: Bool
    let error: String?
}

private struct DockGalleryApplyResult {
    let succeeded: Bool
    let message: String
}

@MainActor
private final class DockGalleryExecutor {
    static let shared = DockGalleryExecutor()

    private let manager = laramgr.shared
    private let dockFlag: UInt32 = 1 << 5
    private let supportedFlags: UInt32 = 1 | (1 << 5)

    private init() {}

    func apply(_ style: DockGalleryStyle) async -> DockGalleryApplyResult {
        await run(style: style, restoring: false)
    }

    func restore() async -> DockGalleryApplyResult {
        await run(style: nil, restoring: true)
    }

    private func run(
        style: DockGalleryStyle?,
        restoring: Bool
    ) async -> DockGalleryApplyResult {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        guard manager.dsready else {
            return failure(
                en: "Prepare Eagle access before changing the Dock.",
                es: "Prepara el acceso de Eagle antes de cambiar el Dock."
            )
        }
        guard !manager.rcSafetyLocked else {
            return failure(
                en: "Fully close and reopen Eagle before retrying the protected Dock call.",
                es: "Cierra Eagle completamente y vuelve a abrirlo antes de reintentar la llamada protegida del Dock."
            )
        }
        guard !isdebugged() else {
            return failure(
                en: "Open Eagle manually from the Home Screen before applying a Dock theme.",
                es: "Abre Eagle manualmente desde Inicio antes de aplicar un tema del Dock."
            )
        }
        guard version.majorVersion == 17 || version.majorVersion == 18 else {
            return failure(
                en: "Dock Gallery is available only on iOS 17 and iOS 18.",
                es: "Galería Dock está disponible solo en iOS 17 y iOS 18."
            )
        }
        let preparation: (RemoteCall?, String?) = await withCheckedContinuation { continuation in
            manager.prepareFreshRemoteCall(process: "SpringBoard", timeout: 20) { process, error in
                continuation.resume(returning: (process, error))
            }
        }
        guard let process = preparation.0 else {
            return failure(
                en: "A fresh SpringBoard session could not be prepared. Nothing changed. \(preparation.1 ?? "")",
                es: "No se pudo preparar una sesión nueva de SpringBoard. Nada cambió. \(preparation.1 ?? "")"
            )
        }
        let targetPID = process.pid
        let currentPID = Self.readSpringBoardPID()
        guard targetPID > 0,
              targetPID == currentPID,
              process.creatingExtraThread else {
            return failure(
                en: "The SpringBoard identity changed before Apply. Nothing was sent.",
                es: "La identidad de SpringBoard cambió antes de Aplicar. No se envió nada."
            )
        }

        let operationID = String(UUID().uuidString.prefix(8))
        let label = "Dock Gallery \(operationID)"
        guard manager.beginExclusiveRemoteCall(label: label) else {
            return failure(
                en: "Another protected SpringBoard operation is still active.",
                es: "Otra operación protegida de SpringBoard sigue activa."
            )
        }

        let processBox = DockGalleryRemoteCallBox(process)
        let rgb = style?.rgb ?? (0, 0, 0)
        let mode = Int32(style?.rawValue ?? 0)
        let response: DockGalleryNativeResponse = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = autoreleasepool {
                    eagle_set_aura_studio(
                        processBox.value,
                        rgb.0,
                        rgb.1,
                        rgb.2,
                        mode,
                        self.dockFlag
                    )
                }
                continuation.resume(returning: DockGalleryNativeResponse(
                    result: result,
                    targetPID: targetPID,
                    springBoardPID: Self.readSpringBoardPID(),
                    healthy: processBox.value.isHealthy,
                    timedOut: processBox.value.lastCallTimedOut,
                    error: processBox.value.lastError
                ))
            }
        }
        manager.endExclusiveRemoteCall(label: label)

        guard response.targetPID == response.springBoardPID else {
            clearVerifiedDock()
            manager.quarantineRemoteCall(
                reason: "SpringBoard restarted during Dock Gallery verification"
            )
            return failure(
                en: "SpringBoard restarted during verification. The theme was not marked as applied.",
                es: "SpringBoard se reinició durante la verificación. El tema no se marcó como aplicado."
            )
        }
        guard response.healthy,
              !response.timedOut,
              response.error?.isEmpty != false else {
            clearVerifiedDock()
            manager.quarantineRemoteCall(
                reason: response.error ?? "Dock Gallery transport became unhealthy"
            )
            return failure(
                en: "The protected Dock call became unhealthy. Fully close and reopen Eagle.",
                es: "La llamada protegida del Dock dejó de estar disponible. Cierra Eagle completamente y vuelve a abrirlo."
            )
        }
        guard response.result >= 0 else {
            return failure(
                en: "The Dock theme returned result \(response.result) and was not applied.",
                es: "El tema del Dock devolvió el resultado \(response.result) y no se aplicó."
            )
        }
        let flags = UInt32(bitPattern: response.result)
        guard flags & dockFlag == dockFlag else {
            clearVerifiedDock()
            return failure(
                en: "SpringBoard returned without verifying the Dock surface.",
                es: "SpringBoard terminó sin verificar la superficie del Dock."
            )
        }

        if restoring {
            clearVerifiedDock(springBoardPID: response.springBoardPID)
            return DockGalleryApplyResult(
                succeeded: true,
                message: LaraL10n.text(
                    en: "The Dock artwork was removed.",
                    es: "Se quitó el arte del Dock."
                )
            )
        }
        guard let style else {
            return failure(en: "No theme was selected.", es: "No se seleccionó ningún tema.")
        }
        persistVerified(style, springBoardPID: response.springBoardPID)
        return DockGalleryApplyResult(
            succeeded: true,
            message: LaraL10n.text(
                en: "\(style.title) was applied behind the Dock apps at 382 × 106 points.",
                es: "\(style.title) se aplicó detrás de las apps del Dock a 382 × 106 puntos."
            )
        )
    }

    private func persistVerified(
        _ style: DockGalleryStyle,
        springBoardPID: Int32
    ) {
        let defaults = UserDefaults.standard
        let savedPID = defaults.integer(forKey: "eagle.auraStudio.activeSpringBoardPID")
        var flags = savedPID == Int(springBoardPID)
            ? UInt32(max(defaults.integer(forKey: "eagle.auraStudio.activeFlags"), 0)) & supportedFlags
            : 0
        flags |= dockFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(Int(springBoardPID), forKey: "eagle.auraStudio.activeSpringBoardPID")
        defaults.set(style.rawValue, forKey: "eagle.auraStudio.activeDockMode")
        defaults.set(style.rawValue, forKey: "eagle.dockGallery.activeStyle")
        defaults.set(style.rawValue, forKey: "eagle.dockGallery.selectedStyle")
        defaults.set(Int(style.rgb.0), forKey: "eagle.auraStudio.activeDockRed")
        defaults.set(Int(style.rgb.1), forKey: "eagle.auraStudio.activeDockGreen")
        defaults.set(Int(style.rgb.2), forKey: "eagle.auraStudio.activeDockBlue")
    }

    private func clearVerifiedDock(springBoardPID: Int32? = nil) {
        let defaults = UserDefaults.standard
        var flags = UInt32(max(defaults.integer(forKey: "eagle.auraStudio.activeFlags"), 0)) & supportedFlags
        flags &= ~dockFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(0, forKey: "eagle.auraStudio.activeDockMode")
        defaults.set(0, forKey: "eagle.dockGallery.activeStyle")
        if flags == 0 {
            defaults.set(0, forKey: "eagle.auraStudio.activeSpringBoardPID")
        } else if let springBoardPID {
            defaults.set(Int(springBoardPID), forKey: "eagle.auraStudio.activeSpringBoardPID")
        }
    }

    private func failure(en: String, es: String) -> DockGalleryApplyResult {
        DockGalleryApplyResult(
            succeeded: false,
            message: LaraL10n.text(en: en, es: es)
        )
    }

    nonisolated private static func readSpringBoardPID() -> Int32 {
        "SpringBoard".withCString { find_process_pid($0) }
    }
}

struct DockGalleryView: View {
    @ObservedObject private var manager = laramgr.shared
    @AppStorage("eagle.dockGallery.selectedStyle")
    private var selectedRaw = DockGalleryStyle.bubblegum.rawValue
    @AppStorage("eagle.dockGallery.activeStyle") private var activeRaw = 0
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0
    @AppStorage("eagle.auraStudio.activeDockMode") private var activeDockModeRaw = 0
    @State private var isApplying = false
    @State private var notice: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                intro
                if !manager.dsready {
                    LaraAccessView(compact: true)
                }
                carousel
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(LaraL10n.text(en: "Dock Gallery", es: "Galería Dock"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            LaraL10n.text(en: "Dock Gallery", es: "Galería Dock"),
            isPresented: Binding(
                get: { notice != nil },
                set: { if !$0 { notice = nil } }
            )
        ) {
            Button("OK", role: .cancel) { notice = nil }
        } message: {
            Text(notice ?? "")
        }
        .onAppear {
            if DockGalleryStyle(rawValue: selectedRaw) == nil {
                selectedRaw = DockGalleryStyle.bubblegum.rawValue
            }
            if hasVerifiedDock,
               DockGalleryStyle(rawValue: activeRaw) != nil,
               activeDockModeRaw == 1 {
                // 1.0.2 stored Gallery artwork as generic Dock Glow. Preserve
                // the verified selection once, then use the exact style mode.
                activeDockModeRaw = activeRaw
            } else if !hasVerifiedDock || DockGalleryStyle(rawValue: activeDockModeRaw) == nil {
                activeRaw = 0
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(LaraL10n.text(
                en: "Choose art for your Dock",
                es: "Elige arte para tu Dock"
            ))
                .font(.title2.bold())
            Text(LaraL10n.text(
                en: "Every theme covers the complete 382 × 106-point Dock frame. Artwork stays behind the apps without being stretched.",
                es: "Cada tema cubre el Dock completo de 382 × 106 puntos. El arte queda detrás de las apps sin estirarse."
            ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func themeCard(_ style: DockGalleryStyle) -> some View {
        let active = hasVerifiedDock &&
            activeDockModeRaw == style.rawValue &&
            activeRaw == style.rawValue
        return VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black)
                Image(style.assetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .shadow(color: style.accent.opacity(0.95), radius: 18)
                    .padding(.horizontal, 8)
                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.90 - Double(index) * 0.08))
                            .frame(width: 43, height: 43)
                            .shadow(color: .black.opacity(0.16), radius: 3, y: 2)
                    }
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(style.title).font(.headline)
                    Text(style.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if active {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(style.accent)
                }
            }

            Button(role: active ? .destructive : nil) {
                active ? restore() : apply(style)
            } label: {
                HStack(spacing: 8) {
                    if isApplying {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: active
                            ? "arrow.counterclockwise"
                            : "sparkles")
                    }
                    Text(active
                        ? LaraL10n.text(en: "Remove", es: "Quitar")
                        : LaraL10n.text(
                            en: "Apply \(style.title)",
                            es: "Aplicar \(style.title)"
                        ))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(active ? .red : style.accent)
            .disabled(isApplying || !manager.dsready)
        }
        .padding(14)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    active ? style.accent : Color.primary.opacity(0.08),
                    lineWidth: active ? 2 : 1
                )
        }
    }

    // MARK: - Carousel

    private var currentStyle: DockGalleryStyle {
        DockGalleryStyle(rawValue: selectedRaw) ?? .bubblegum
    }

    private var hasVerifiedDock: Bool {
        UInt32(max(activeFlagsRaw, 0)) & (1 << 5) != 0
    }

    private var currentIndex: Int {
        DockGalleryStyle.allCases.firstIndex(of: currentStyle) ?? 0
    }

    private var carousel: some View {
        VStack(spacing: 16) {
            themeCard(currentStyle)
                .id(currentStyle.rawValue)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            navigationRow
        }
    }

    private var navigationRow: some View {
        HStack(spacing: 16) {
            arrowButton(symbol: "chevron.left", step: -1)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                ForEach(DockGalleryStyle.allCases) { style in
                    let isCurrent = style == currentStyle
                    Circle()
                        .fill(isCurrent ? Color.primary : Color.primary.opacity(0.22))
                        .frame(width: isCurrent ? 8 : 6, height: isCurrent ? 8 : 6)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: currentStyle)

            Spacer(minLength: 8)

            arrowButton(symbol: "chevron.right", step: 1)
        }
        .padding(.horizontal, 4)
    }

    private func arrowButton(symbol: String, step delta: Int) -> some View {
        Button {
            step(delta)
        } label: {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 52, height: 52)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: Circle()
                )
                .overlay {
                    Circle().strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
        .accessibilityLabel(delta < 0
            ? LaraL10n.text(en: "Previous theme", es: "Tema anterior")
            : LaraL10n.text(en: "Next theme", es: "Tema siguiente"))
    }

    private func step(_ delta: Int) {
        let all = DockGalleryStyle.allCases
        guard !all.isEmpty else { return }
        let next = (currentIndex + delta + all.count) % all.count
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedRaw = all[next].rawValue
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func apply(_ style: DockGalleryStyle) {
        guard !isApplying else { return }
        selectedRaw = style.rawValue
        isApplying = true
        Task { @MainActor in
            let result = await DockGalleryExecutor.shared.apply(style)
            isApplying = false
            if result.succeeded {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            notice = result.message
        }
    }

    private func restore() {
        guard !isApplying else { return }
        isApplying = true
        Task { @MainActor in
            let result = await DockGalleryExecutor.shared.restore()
            isApplying = false
            if result.succeeded {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            notice = result.message
        }
    }
}
