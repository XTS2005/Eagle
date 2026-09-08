import SwiftUI
import UIKit
import CryptoKit
import Combine

private enum DockGalleryStyle: Int, CaseIterable, Identifiable {
    case bubblegum = 15
    case springfield = 16
    case bikiniBottom = 17
    case duckMood = 28
    case blueScreen = 29
    case walkingFlame = 30

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .bubblegum:
            return LaraL10n.text(en: "Bubblegum", es: "Chicle")
        case .springfield:
            return "Springfield"
        case .bikiniBottom:
            return LaraL10n.text(en: "Bikini Bottom", es: "Fondo de Bikini")
        case .duckMood:
            return LaraL10n.text(en: "Duck Mood", es: "Humor de pato")
        case .blueScreen:
            return LaraL10n.text(en: "Blue Screen", es: "Pantalla azul")
        case .walkingFlame:
            return LaraL10n.text(en: "Walking Flame", es: "Llama ambulante")
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
        case .duckMood:
            return LaraL10n.text(en: "Classic animated duck close-up", es: "Primer plano de pato animado clásico")
        case .blueScreen:
            return LaraL10n.text(en: "Electric blue system portrait", es: "Retrato de sistema azul eléctrico")
        case .walkingFlame:
            return LaraL10n.text(en: "Surreal street fire portrait", es: "Retrato surrealista de fuego urbano")
        }
    }
    var assetName: String {
        switch self {
        case .bubblegum: return "DockGalleryBubblegum"
        case .springfield: return "DockGallerySpringfield"
        case .bikiniBottom: return "DockGalleryBikiniBottom"
        case .duckMood: return "DockGalleryDuckMood"
        case .blueScreen: return "DockGalleryBlueScreen"
        case .walkingFlame: return "DockGalleryWalkingFlame"
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
        case .duckMood:
            return Color(red: 1.0, green: 0.47, blue: 0.08)
        case .blueScreen:
            return Color(red: 0.10, green: 0.28, blue: 1.0)
        case .walkingFlame:
            return Color(red: 1.0, green: 0.30, blue: 0.06)
        }
    }
    var rgb: (Int32, Int32, Int32) {
        switch self {
        case .bubblegum: return (255, 45, 158)
        case .springfield: return (0, 164, 255)
        case .bikiniBottom: return (0, 191, 235)
        case .duckMood: return (255, 120, 20)
        case .blueScreen: return (26, 71, 255)
        case .walkingFlame: return (255, 77, 15)
        }
    }

    var isAnimated: Bool {
        return false
    }

    private var animationAssetPrefix: String? {
        nil
    }

    func previewAsset(at date: Date) -> String {
        guard let animationAssetPrefix else { return assetName }
        let frame = Int(date.timeIntervalSinceReferenceDate * 6.0) % 17 + 1
        return String(format: "%@%02d", animationAssetPrefix, frame)
    }
}

private struct RemoteDockGalleryCatalog: Decodable, Sendable {
    let schemaVersion: Int
    let themes: [RemoteDockGalleryTheme]
}

private struct RemoteDockGalleryTheme: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let version: Int
    let title: String
    let titleES: String
    let subtitle: String
    let subtitleES: String
    let accent: String
    let previewURL: URL
    let animatedPreviewURL: URL?
    let packageURL: URL
    let sha256: String
    let byteCount: Int
    let frameCount: Int
    let fps: Double
    let width: Int
    let height: Int

    var localizedTitle: String { LaraL10n.text(en: title, es: titleES) }
    var localizedSubtitle: String { LaraL10n.text(en: subtitle, es: subtitleES) }
    var presentationPreviewURL: URL {
        let source = frameCount > 1 ? (animatedPreviewURL ?? previewURL) : previewURL
        var components = URLComponents(url: source, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(
            name: "preview",
            value: "\(version)-\(frameCount > 1 ? "animated" : "static")"
        )]
        return components?.url ?? source
    }
    var color: Color { Color(eagleHex: accent) }
    var rgb: (Int32, Int32, Int32) {
        let hex = accent.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt32(hex, radix: 16) ?? 0xDB40E0
        return (Int32((value >> 16) & 0xff), Int32((value >> 8) & 0xff), Int32(value & 0xff))
    }
    var duration: Double { Double(frameCount) / fps }
}

private extension Color {
    init(eagleHex: String) {
        let hex = eagleHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt32(hex, radix: 16) ?? 0xDB40E0
        self.init(
            red: Double((value >> 16) & 0xff) / 255.0,
            green: Double((value >> 8) & 0xff) / 255.0,
            blue: Double(value & 0xff) / 255.0
        )
    }
}

@MainActor
private final class RemoteDockGalleryStore: ObservableObject {
    static let shared = RemoteDockGalleryStore()
    @Published private(set) var themes: [RemoteDockGalleryTheme] = []
    @Published private(set) var loading = false
    @Published private(set) var downloadingID: String?
    @Published private(set) var errorMessage: String?

    private let catalogURL = URL(string: "https://raw.githubusercontent.com/leonardob8777-bit/Eagle-Gallery/main/catalogs/dock-v1.json?catalog=21")!

    func load(force: Bool = false) async {
        if loading || (!force && !themes.isEmpty) { return }
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            var request = URLRequest(url: catalogURL)
            request.timeoutInterval = 25
            request.cachePolicy = force ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  data.count <= 512 * 1024 else { throw URLError(.badServerResponse) }
            let catalog = try JSONDecoder().decode(RemoteDockGalleryCatalog.self, from: data)
            guard catalog.schemaVersion == 1 else { throw URLError(.cannotParseResponse) }
            themes = catalog.themes.filter(Self.isSupported)
        } catch {
            errorMessage = LaraL10n.text(
                en: "The online collection could not be loaded.",
                es: "No se pudo cargar la colección en línea."
            )
        }
    }

    func prepare(_ theme: RemoteDockGalleryTheme) async throws -> URL {
        let destination = try cacheDirectory(for: theme)
        if Self.validFrames(in: destination, theme: theme) { return destination }
        downloadingID = theme.id
        defer { downloadingID = nil }

        var request = URLRequest(url: theme.packageURL)
        request.timeoutInterval = 90
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              data.count == theme.byteCount,
              data.count <= 30 * 1024 * 1024 else { throw URLError(.badServerResponse) }
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest.caseInsensitiveCompare(theme.sha256) == .orderedSame else {
            throw URLError(.secureConnectionFailed)
        }

        let archive = try ZipArchive(data: data)
        let expected = Set((1...theme.frameCount).map { String(format: "frame%02d.png", $0) })
        let files = archive.entries.filter { !$0.isDirectory }
        guard Set(files.map(\.path)) == expected else { throw URLError(.cannotDecodeContentData) }

        let fm = FileManager.default
        let staging = destination.deletingLastPathComponent()
            .appendingPathComponent(".\(theme.id)-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        do {
            for entry in files {
                let frameData = try archive.extract(entry)
                guard let image = UIImage(data: frameData),
                      image.cgImage?.width == theme.width,
                      image.cgImage?.height == theme.height else {
                    throw URLError(.cannotDecodeContentData)
                }
                try frameData.write(to: staging.appendingPathComponent(entry.path), options: .atomic)
            }
            guard Self.validFrames(in: staging, theme: theme) else {
                throw URLError(.cannotDecodeContentData)
            }
            if fm.fileExists(atPath: destination.path) { try fm.removeItem(at: destination) }
            try fm.moveItem(at: staging, to: destination)
        } catch {
            try? fm.removeItem(at: staging)
            throw error
        }
        return destination
    }

    private func cacheDirectory(for theme: RemoteDockGalleryTheme) throws -> URL {
        let root = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("EagleGallery/Dock", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("\(theme.id)-v\(theme.version)", isDirectory: true)
    }

    private static func isSupported(_ theme: RemoteDockGalleryTheme) -> Bool {
        ((theme.frameCount == 17 && theme.fps == 6) ||
         (theme.frameCount == 1 && theme.fps == 1)) &&
            theme.width == 1146 && theme.height == 318 &&
            theme.byteCount > 0 && theme.byteCount <= 30 * 1024 * 1024
    }

    private static func validFrames(in directory: URL, theme: RemoteDockGalleryTheme) -> Bool {
        guard isSupported(theme) else { return false }
        return (1...theme.frameCount).allSatisfy { index in
            let url = directory.appendingPathComponent(String(format: "frame%02d.png", index))
            guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                  let image = UIImage(data: data) else { return false }
            return image.cgImage?.width == theme.width && image.cgImage?.height == theme.height
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

    func apply(_ style: DockGalleryStyle, intensity: Double) async -> DockGalleryApplyResult {
        await run(style: style, remote: nil, directory: nil, intensity: intensity, restoring: false)
    }

    func applyRemote(
        _ theme: RemoteDockGalleryTheme,
        directory: URL,
        intensity: Double
    ) async -> DockGalleryApplyResult {
        await run(style: nil, remote: theme, directory: directory, intensity: intensity, restoring: false)
    }

    func restore() async -> DockGalleryApplyResult {
        await run(style: nil, remote: nil, directory: nil, restoring: true)
    }

    private func run(
        style: DockGalleryStyle?,
        remote: RemoteDockGalleryTheme?,
        directory: URL?,
        intensity: Double = 0.72,
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
        let operationID = String(UUID().uuidString.prefix(8))
        let label = "Dock Gallery \(operationID)"
        guard !Task.isCancelled,
              manager.beginExclusiveRemoteCall(label: label, expectedSession: process) else {
            return failure(
                en: "Another protected SpringBoard operation is still active.",
                es: "Otra operación protegida de SpringBoard sigue activa."
            )
        }
        defer { manager.endExclusiveRemoteCall(label: label) }

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

        let processBox = DockGalleryRemoteCallBox(process)
        let rgb = style?.rgb ?? remote?.rgb ?? (0, 0, 0)
        let mode = Int32(remote == nil ? (style?.rawValue ?? 0) : 35)
        let remoteDirectory = directory?.path
        let remoteDuration = remote?.duration ?? 0
        let appliedIntensity = EagleStoredThemeValues.intensity(intensity)
        let response: DockGalleryNativeResponse = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = autoreleasepool {
                    eagle_set_dock_gallery_intensity(Int32((appliedIntensity * 100).rounded()))
                    if let remoteDirectory {
                        return remoteDirectory.withCString { path in
                            eagle_configure_remote_dock_gallery(path, Int32(remote?.frameCount ?? 0), remoteDuration)
                            defer { eagle_configure_remote_dock_gallery(nil, 0, 0) }
                            return eagle_set_aura_studio(
                                processBox.value, rgb.0, rgb.1, rgb.2,
                                mode, self.dockFlag
                            )
                        }
                    }
                    eagle_configure_remote_dock_gallery(nil, 0, 0)
                    return eagle_set_aura_studio(
                        processBox.value, rgb.0, rgb.1, rgb.2,
                        mode, self.dockFlag
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
        guard style != nil || remote != nil else {
            return failure(en: "No theme was selected.", es: "No se seleccionó ningún tema.")
        }
        if let style {
            persistVerified(style, springBoardPID: response.springBoardPID)
        } else if let remote {
            persistVerified(remote, springBoardPID: response.springBoardPID)
        }
        UserDefaults.standard.set(appliedIntensity, forKey: "eagle.dockGallery.appliedGlowIntensity")
        let title = style?.title ?? remote?.localizedTitle ?? ""
        return DockGalleryApplyResult(
            succeeded: true,
            message: LaraL10n.text(
                en: "\(title) was applied behind the Dock apps.",
                es: "\(title) se aplicó detrás de las apps del Dock."
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
            ? EagleStoredThemeValues.flags(defaults.integer(forKey: "eagle.auraStudio.activeFlags")) & supportedFlags
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
        defaults.removeObject(forKey: "eagle.dockGallery.activeRemoteID")
    }

    private func persistVerified(
        _ theme: RemoteDockGalleryTheme,
        springBoardPID: Int32
    ) {
        let defaults = UserDefaults.standard
        let savedPID = defaults.integer(forKey: "eagle.auraStudio.activeSpringBoardPID")
        var flags = savedPID == Int(springBoardPID)
            ? EagleStoredThemeValues.flags(defaults.integer(forKey: "eagle.auraStudio.activeFlags")) & supportedFlags
            : 0
        flags |= dockFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(Int(springBoardPID), forKey: "eagle.auraStudio.activeSpringBoardPID")
        defaults.set(35, forKey: "eagle.auraStudio.activeDockMode")
        defaults.set(0, forKey: "eagle.dockGallery.activeStyle")
        defaults.set(theme.id, forKey: "eagle.dockGallery.activeRemoteID")
        defaults.set(Int(theme.rgb.0), forKey: "eagle.auraStudio.activeDockRed")
        defaults.set(Int(theme.rgb.1), forKey: "eagle.auraStudio.activeDockGreen")
        defaults.set(Int(theme.rgb.2), forKey: "eagle.auraStudio.activeDockBlue")
    }

    private func clearVerifiedDock(springBoardPID: Int32? = nil) {
        let defaults = UserDefaults.standard
        var flags = EagleStoredThemeValues.flags(defaults.integer(forKey: "eagle.auraStudio.activeFlags")) & supportedFlags
        flags &= ~dockFlag
        defaults.set(Int(flags), forKey: "eagle.auraStudio.activeFlags")
        defaults.set(0, forKey: "eagle.auraStudio.activeDockMode")
        defaults.set(0, forKey: "eagle.dockGallery.activeStyle")
        defaults.removeObject(forKey: "eagle.dockGallery.activeRemoteID")
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
    private enum MediaFilter: String, CaseIterable {
        case still = "Static"
        case live = "Live"
        case favorites = "Favorites"

        var title: String {
            self == .favorites ? "Saves" : rawValue
        }

        var icon: String {
            switch self {
            case .still: return "photo.fill"
            case .live: return "play.fill"
            case .favorites: return "heart.fill"
            }
        }

        func includes(_ theme: RemoteDockGalleryTheme, favorites: Set<String>) -> Bool {
            switch self {
            case .still: return theme.frameCount == 1
            case .live: return theme.frameCount > 1
            case .favorites: return favorites.contains(theme.id)
            }
        }
    }

    @ObservedObject private var manager = laramgr.shared
    @StateObject private var remoteGallery = RemoteDockGalleryStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("eagle.dockGallery.selectedStyle")
    private var selectedRaw = DockGalleryStyle.bubblegum.rawValue
    @AppStorage("eagle.dockGallery.activeStyle") private var activeRaw = 0
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0
    @AppStorage("eagle.auraStudio.activeDockMode") private var activeDockModeRaw = 0
    @AppStorage("eagle.dockGallery.activeRemoteID") private var activeRemoteID = ""
    @AppStorage("eagle.dockGallery.glowIntensity") private var glowIntensity = 0.72
    @AppStorage("eagle.dockGallery.favoriteIDs") private var favoriteIDsJSON = "[]"
    @AppStorage("eagle.dockGallery.lastViewedStaticID") private var lastViewedStaticID = ""
    @AppStorage("eagle.dockGallery.lastViewedLiveID") private var lastViewedLiveID = ""
    @State private var isApplying = false
    @State private var notice: String?
    @State private var selectedRemoteID = ""
    @State private var mediaFilter: MediaFilter = .still
    @State private var rememberedSelections: [MediaFilter: String] = [:]
    @State private var shuffledRemoteIDs: [String] = []
    @State private var visitStarted = false
    @State private var needsNewVisitOnResume = false
    @State private var readyRemotePreviewID = ""
    @State private var showAccessSetup = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                onlineCollection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .navigationTitle(LaraL10n.text(en: "Dock Gallery", es: "Galería Dock"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .overlay(alignment: .top) {
            if let notice {
                noticeToast(notice)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .sheet(isPresented: $showAccessSetup) {
            NavigationStack {
                ScrollView {
                    LaraAccessView(compact: true) {
                        showAccessSetup = false
                    }
                    .padding(20)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle(LaraL10n.text(en: "Prepare Eagle", es: "Preparar Eagle"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(LaraL10n.text(en: "Done", es: "Listo")) {
                            showAccessSetup = false
                        }
                    }
                }
            }
        }
        .onAppear {
            if !visitStarted { beginGalleryVisit() }
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
            if hasVerifiedDock, activeRemoteID.isEmpty,
               let legacyID = Self.remoteID(forLegacyMode: activeDockModeRaw) {
                activeRemoteID = legacyID
            }
        }
        .onDisappear {
            // Returning from access setup must keep the theme being prepared.
            if !showAccessSetup { visitStarted = false }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background, visitStarted {
                needsNewVisitOnResume = true
            } else if phase == .active, needsNewVisitOnResume {
                needsNewVisitOnResume = false
                if visitStarted, !showAccessSetup, !isApplying, remoteGallery.downloadingID == nil {
                    beginGalleryVisit()
                }
            }
        }
        .task {
            await remoteGallery.load()
            synchronizeRemoteSelection()
        }
        .onChange(of: remoteGallery.themes) { _ in
            synchronizeRemoteSelection()
        }
        .onChange(of: favoriteIDsJSON) { _ in
            synchronizeRemoteSelection()
        }
        .onChange(of: notice) { message in
            guard let message else { return }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_500_000_000)
                guard notice == message else { return }
                withAnimation(.easeOut(duration: 0.2)) { notice = nil }
            }
        }
    }

    private func noticeToast(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .padding(.top, 1)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                withAnimation(.easeOut(duration: 0.2)) { notice = nil }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }

    private func themeCard(_ style: DockGalleryStyle) -> some View {
        let active = hasVerifiedDock &&
            activeDockModeRaw == style.rawValue &&
            activeRaw == style.rawValue
        return VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black)
                artworkPreview(style)
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

    @ViewBuilder
    private var onlineCollection: some View {
        if remoteGallery.loading && remoteGallery.themes.isEmpty {
            HStack(spacing: 10) {
                ProgressView()
                Text(LaraL10n.text(en: "Loading online collection…", es: "Cargando colección en línea…"))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        } else if let error = remoteGallery.errorMessage, remoteGallery.themes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(error).foregroundStyle(.secondary)
                Button(LaraL10n.text(en: "Try again", es: "Reintentar")) {
                    Task { await remoteGallery.load(force: true) }
                }
                .buttonStyle(.bordered)
            }
        } else if !remoteGallery.themes.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                collectionHeader
                mediaFilterControl

                if let theme = selectedRemoteTheme {
                    remoteThemeCard(theme)
                    remoteActionButton(theme)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: mediaFilter == .favorites ? "heart" : "photo")
                            .font(.title2)
                        Text(mediaFilter == .favorites
                            ? LaraL10n.text(en: "Save your favorites with ♡", es: "Guarda tus favoritos con ♡")
                            : LaraL10n.text(en: "No styles in this category yet.", es: "Aún no hay estilos en esta categoría."))
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
        }
    }

    private var glowIntensityControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(LaraL10n.text(en: "Dock light", es: "Luz del Dock"), systemImage: "sun.max.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int((glowIntensity * 100).rounded()))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $glowIntensity, in: 0...1, step: 0.01)
                .tint(.primary)
                .disabled(isApplying || remoteGallery.downloadingID != nil)
                .accessibilityLabel(LaraL10n.text(en: "Dock light intensity", es: "Intensidad de luz del Dock"))
        }
        .padding(.horizontal, 2)
    }

    private func remoteThemeCard(_ theme: RemoteDockGalleryTheme) -> some View {
        let active = hasVerifiedDock && activeRemoteID == theme.id &&
            (activeDockModeRaw == 35 || Self.remoteID(forLegacyMode: activeDockModeRaw) == theme.id)
        return VStack(alignment: .center, spacing: 14) {
            GeometryReader { proxy in
                let availableWidth = max(proxy.size.width - 16, 1)
                let actualDockWidth = max(UIScreen.main.bounds.width - 30, 250)
                let actualDockHeight: CGFloat = 102.333333
                let aspectRatio = actualDockWidth / actualDockHeight
                let dockHeight = min(proxy.size.height, availableWidth / aspectRatio)
                let dockWidth = min(availableWidth, dockHeight * aspectRatio)
                let intensity = CGFloat(min(max(glowIntensity, 0), 1))
                let lightScale = dockHeight / actualDockHeight
                let lightPadding = CGFloat(eagle_dock_gallery_glow_padding()) * lightScale

                ZStack {
                    if readyRemotePreviewID == theme.id,
                       let halo = eagle_dock_gallery_glow_image(
                           theme.rgb.0, theme.rgb.1, theme.rgb.2,
                           Double(actualDockWidth), Double(actualDockHeight)) {
                        Image(uiImage: halo)
                            .resizable()
                            .frame(width: dockWidth + 2 * lightPadding, height: dockHeight + 2 * lightPadding)
                            .opacity(Double(intensity))
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    LaraRemoteMediaPreview(
                        url: theme.presentationPreviewURL,
                        animated: theme.frameCount > 1,
                        contentMode: .fill,
                        showsRetry: true,
                        background: .clear,
                        onReady: { ready in
                            guard selectedRemoteTheme?.id == theme.id else { return }
                            if ready {
                                readyRemotePreviewID = theme.id
                            } else if readyRemotePreviewID == theme.id {
                                readyRemotePreviewID = ""
                            }
                        }
                    )
                    .id("dock-preview-\(theme.id)")
                    .frame(width: dockWidth, height: dockHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 40 * lightScale, style: .circular))

                    if readyRemotePreviewID == theme.id {
                        HStack(spacing: 14) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.90 - Double(index) * 0.08))
                                    .frame(width: 43, height: 43)
                                    .shadow(color: .black.opacity(0.16), radius: 3, y: 2)
                            }
                        }
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(height: 212)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        stepRemote(value.translation.width < 0 ? 1 : -1)
                    }
            )

            HStack(spacing: 8) {
                Text(theme.localizedTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Label(
                    theme.frameCount > 1 ? "Live" : "Static",
                    systemImage: theme.frameCount > 1 ? "play.fill" : "photo.fill"
                )
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(theme.color)
                }
                Button {
                    toggleFavorite(theme)
                } label: {
                    Image(systemName: favoriteIDs.contains(theme.id) ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isApplying || remoteGallery.downloadingID != nil)
                .accessibilityLabel(favoriteIDs.contains(theme.id)
                    ? LaraL10n.text(en: "Remove from favorites", es: "Quitar de favoritos")
                    : LaraL10n.text(en: "Add to favorites", es: "Añadir a favoritos"))
                .accessibilityValue(theme.localizedTitle)
            }

            HStack(spacing: 28) {
                remoteArrowButton(symbol: "chevron.left", step: -1)
                Text(remotePositionText)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 46)
                remoteArrowButton(symbol: "chevron.right", step: 1)
            }
            .frame(maxWidth: .infinity)

            glowIntensityControl
        }
        .animation(.easeOut(duration: 0.16), value: glowIntensity)
    }

    private func remoteActionButton(_ theme: RemoteDockGalleryTheme) -> some View {
        let active = hasVerifiedDock && activeRemoteID == theme.id &&
            (activeDockModeRaw == 35 || Self.remoteID(forLegacyMode: activeDockModeRaw) == theme.id)
        let downloading = remoteGallery.downloadingID == theme.id
        return HStack(spacing: 10) {
            Button {
                if !manager.dsready {
                    showAccessSetup = true
                } else {
                    applyRemote(theme)
                }
            } label: {
                HStack(spacing: 8) {
                    if downloading || isApplying {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: !manager.dsready
                            ? "lock.shield.fill"
                            : (active ? "arrow.clockwise" : "arrow.down.circle.fill"))
                    }
                    Text(!manager.dsready
                        ? LaraL10n.text(en: "Prepare to apply", es: "Preparar para aplicar")
                        : (active
                            ? LaraL10n.text(en: "Reapply \(theme.localizedTitle)", es: "Reaplicar \(theme.localizedTitle)")
                            : LaraL10n.text(en: "Apply \(theme.localizedTitle)", es: "Aplicar \(theme.localizedTitle)")))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(!manager.dsready ? .blue : theme.color)

            if active && manager.dsready {
                Button(role: .destructive) {
                    restore()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.headline)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel(LaraL10n.text(
                    en: "Remove Dock theme",
                    es: "Quitar tema del Dock"
                ))
            }
        }
        .disabled(isApplying || remoteGallery.downloadingID != nil)
        .animation(.none, value: theme.id)
    }

    private var selectedRemoteTheme: RemoteDockGalleryTheme? {
        visibleRemoteThemes.first(where: { $0.id == selectedRemoteID }) ??
            visibleRemoteThemes.first
    }

    private var visibleRemoteThemes: [RemoteDockGalleryTheme] {
        let favorites = favoriteIDs
        let themesByID = Dictionary(remoteGallery.themes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return shuffledRemoteIDs.compactMap { themesByID[$0] }
            .filter { mediaFilter.includes($0, favorites: favorites) }
    }

    private var favoriteIDs: Set<String> {
        guard let data = favoriteIDsJSON.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(ids)
    }

    private func toggleFavorite(_ theme: RemoteDockGalleryTheme) {
        var ids = favoriteIDs
        if !ids.insert(theme.id).inserted { ids.remove(theme.id) }
        guard let data = try? JSONEncoder().encode(ids.sorted()),
              let json = String(data: data, encoding: .utf8) else { return }
        // Store catalog IDs, so favorites survive app restarts and asset updates.
        favoriteIDsJSON = json
        synchronizeRemoteSelection()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func selectMediaFilter(_ filter: MediaFilter) {
        guard mediaFilter != filter, !isApplying, remoteGallery.downloadingID == nil else { return }
        rememberedSelections[mediaFilter] = selectedRemoteTheme?.id
        readyRemotePreviewID = ""
        mediaFilter = filter
        selectedRemoteID = rememberedSelections[filter] ?? ""
        synchronizeRemoteSelection()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private var mediaFilterControl: some View {
        HStack(spacing: 4) {
            ForEach(MediaFilter.allCases, id: \.self) { filter in
                let selected = mediaFilter == filter
                Button {
                    selectMediaFilter(filter)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: filter.icon)
                        Text(filter.title)
                    }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
                        .background(
                            selected ? Color.primary : Color.clear,
                            in: Capsule()
                        )
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .center)
        .disabled(isApplying || remoteGallery.downloadingID != nil)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(LaraL10n.text(en: "Dock style type", es: "Tipo de estilo del Dock"))
    }

    private func beginGalleryVisit() {
        visitStarted = true
        shuffledRemoteIDs = []
        selectedRemoteID = ""
        readyRemotePreviewID = ""
        rememberedSelections = [:]
        mediaFilter = .still
        synchronizeRemoteSelection()
    }

    private func synchronizeRemoteSelection() {
        let catalogIDs = Set(remoteGallery.themes.map(\.id))
        let retainedIDs = shuffledRemoteIDs.filter { catalogIDs.contains($0) }
        let retainedSet = Set(retainedIDs)
        let additions = Array(catalogIDs.subtracting(retainedSet)).shuffled()
        var order = retainedIDs + additions
        if retainedIDs.isEmpty {
            // Avoid opening either category on the last theme seen there.
            for (filter, lastID) in [(MediaFilter.still, lastViewedStaticID), (.live, lastViewedLiveID)] {
                let categoryIDs = Set(remoteGallery.themes.filter {
                    filter.includes($0, favorites: [])
                }.map(\.id))
                let indices = order.indices.filter { categoryIDs.contains(order[$0]) }
                if indices.count > 1, let first = indices.first, order[first] == lastID {
                    order.swapAt(first, indices[1])
                }
            }
        }
        if shuffledRemoteIDs != order { shuffledRemoteIDs = order }
        if !visibleRemoteThemes.contains(where: { $0.id == selectedRemoteID }) {
            readyRemotePreviewID = ""
            selectedRemoteID = visibleRemoteThemes.first?.id ?? ""
        }
        rememberViewedTheme()
    }

    private func rememberViewedTheme() {
        guard let theme = selectedRemoteTheme else { return }
        if theme.frameCount > 1 {
            lastViewedLiveID = theme.id
        } else {
            lastViewedStaticID = theme.id
        }
    }

    private var collectionHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.fill.on.rectangle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(LaraL10n.text(en: "Choose your Dock", es: "Elige tu Dock"))
                    .font(.headline)
                Text(LaraL10n.text(
                    en: "\(remoteGallery.themes.count) styles available",
                    es: "\(remoteGallery.themes.count) estilos disponibles"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button {
                Task { await remoteGallery.load(force: true) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(remoteGallery.loading)
            .accessibilityLabel(LaraL10n.text(en: "Refresh collection", es: "Actualizar colección"))
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
    }

    private var remotePositionText: String {
        let themes = visibleRemoteThemes
        let current = themes.firstIndex(where: { $0.id == selectedRemoteID }) ?? 0
        return "\(current + 1) / \(themes.count)"
    }

    private func remoteArrowButton(symbol: String, step: Int) -> some View {
        Button {
            stepRemote(step)
        } label: {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isApplying || remoteGallery.downloadingID != nil || visibleRemoteThemes.count < 2)
        .accessibilityLabel(step < 0
            ? LaraL10n.text(en: "Previous theme", es: "Tema anterior")
            : LaraL10n.text(en: "Next theme", es: "Tema siguiente"))
    }

    private func stepRemote(_ step: Int) {
        guard !isApplying, remoteGallery.downloadingID == nil else { return }
        let themes = visibleRemoteThemes
        guard themes.count > 1 else { return }
        let current = themes.firstIndex(where: { $0.id == selectedRemoteID }) ?? 0
        let next = (current + step + themes.count) % themes.count
        readyRemotePreviewID = ""
        selectedRemoteID = themes[next].id
        rememberViewedTheme()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    @ViewBuilder
    private func artworkPreview(_ style: DockGalleryStyle) -> some View {
        if style.isAnimated {
            TimelineView(.animation(
                minimumInterval: 1.0 / 6.0,
                paused: reduceMotion
            )) { context in
                Image(reduceMotion ? style.assetName : style.previewAsset(at: context.date))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            }
        } else {
            Image(style.assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        }
    }

    // MARK: - Carousel

    private var currentStyle: DockGalleryStyle {
        DockGalleryStyle(rawValue: selectedRaw) ?? .bubblegum
    }

    private var hasVerifiedDock: Bool {
        EagleStoredThemeValues.flags(activeFlagsRaw) & (1 << 5) != 0
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
            let result = await DockGalleryExecutor.shared.apply(style, intensity: glowIntensity)
            isApplying = false
            if result.succeeded {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            notice = result.message
        }
    }

    private func applyRemote(_ theme: RemoteDockGalleryTheme) {
        guard !isApplying, remoteGallery.downloadingID == nil else { return }
        let requestedIntensity = glowIntensity
        isApplying = true
        Task { @MainActor in
            do {
                let directory = try await remoteGallery.prepare(theme)
                let result = await DockGalleryExecutor.shared.applyRemote(theme, directory: directory, intensity: requestedIntensity)
                if result.succeeded {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                notice = result.message
            } catch {
                notice = LaraL10n.text(
                    en: "The original theme package could not be downloaded or verified. Nothing changed.",
                    es: "No se pudo descargar o verificar el paquete original. Nada cambió."
                )
            }
            isApplying = false
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

    private static func remoteID(forLegacyMode mode: Int) -> String? {
        [
            15: "bubblegum", 16: "springfield", 17: "bikini-bottom",
            18: "neon-chase", 19: "neon-drift", 20: "glitch-orbit",
            21: "pop-glasses", 22: "inferno-wings", 23: "cool-cat",
            24: "cyber-love", 25: "padded-room", 26: "noir-vision",
            27: "thirsty-cat", 28: "duck-mood", 29: "blue-screen",
            30: "walking-flame", 31: "prism-blur"
        ][mode]
    }
}
