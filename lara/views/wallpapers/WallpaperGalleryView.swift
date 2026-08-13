import SwiftUI
import Combine
import WebKit

private let nuggetWallpaperBaseURL = URL(
    string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/"
)!

enum WallpaperCatalogKind: String, CaseIterable, Identifiable {
    case community
    case apple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .community: return "Comunidad"
        case .apple: return "Apple"
        }
    }

    var manifestURL: URL {
        let name = self == .community ? "wallpapers-custom.json" : "wallpapers-apple.json"
        return nuggetWallpaperBaseURL.appendingPathComponent(name)
    }
}

struct NuggetWallpaper: Decodable, Identifiable, Hashable {
    let name: String
    let description: String?
    let url: String
    let preview: String
    let authors: String?
    let contest: String?

    var id: String { url }

    var authorLine: String {
        guard let authors, !authors.isEmpty else { return "Colección de Nugget" }
        return authors
    }

    var requiresIOS26: Bool {
        let details = "\(name) \(description ?? "")".lowercased()
        return details.contains("ios 26")
    }

    var previewURL: URL? {
        URL(string: preview, relativeTo: nuggetWallpaperBaseURL)?.absoluteURL
    }

    var downloadURL: URL? {
        URL(string: url, relativeTo: nuggetWallpaperBaseURL)?.absoluteURL
    }
}

enum CommunityWallpaperError: LocalizedError {
    case invalidResponse
    case invalidPackage
    case packageTooLarge
    case noDescriptors
    case tooManyDescriptors
    case requiresIOS26

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "No se pudo obtener el catálogo en este momento."
        case .invalidPackage:
            return "El archivo de este fondo no tiene una estructura compatible."
        case .packageTooLarge:
            return "El archivo supera el límite seguro de tamaño para procesarlo en el iPhone."
        case .noDescriptors:
            return "Este paquete no contiene fondos que Lara pueda instalar."
        case .tooManyDescriptors:
            return "El paquete contiene demasiados fondos para una sola instalación."
        case .requiresIOS26:
            return "Este fondo requiere iOS 26 por las animaciones que utiliza."
        }
    }
}

private enum NuggetWallpaperService {
    static func fetch(_ kind: WallpaperCatalogKind, forceRefresh: Bool) async throws -> [NuggetWallpaper] {
        var request = URLRequest(url: kind.manifestURL)
        request.timeoutInterval = 30
        if forceRefresh {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CommunityWallpaperError.invalidResponse
        }
        return try JSONDecoder().decode([NuggetWallpaper].self, from: data)
    }

    static func download(_ wallpaper: NuggetWallpaper) async throws -> Data {
        guard let url = wallpaper.downloadURL else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 120
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CommunityWallpaperError.invalidResponse
        }
        guard data.count <= TendiesInstaller.maximumCompressedSize else {
            throw CommunityWallpaperError.packageTooLarge
        }
        return data
    }
}

@MainActor
final class WallpaperCatalogManager: ObservableObject {
    static let shared = WallpaperCatalogManager()

    @Published private(set) var community: [NuggetWallpaper] = []
    @Published private(set) var apple: [NuggetWallpaper] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var installingID: String?
    @Published private(set) var resultMessage: String?
    @Published private(set) var didInstall = false

    func items(for kind: WallpaperCatalogKind) -> [NuggetWallpaper] {
        kind == .community ? community : apple
    }

    func load(forceRefresh: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            async let communityItems = NuggetWallpaperService.fetch(.community, forceRefresh: forceRefresh)
            async let appleItems = NuggetWallpaperService.fetch(.apple, forceRefresh: forceRefresh)
            let loaded = try await (communityItems, appleItems)
            community = loaded.0
            apple = loaded.1
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func install(_ wallpaper: NuggetWallpaper) async {
        guard installingID == nil else { return }
        guard laramgr.shared.sbxready else {
            resultMessage = "Prepara el acceso de Lara antes de instalar un fondo."
            return
        }
        if wallpaper.requiresIOS26,
           ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 26 {
            resultMessage = CommunityWallpaperError.requiresIOS26.localizedDescription
            return
        }

        installingID = wallpaper.id
        resultMessage = nil
        didInstall = false

        do {
            let data = try await NuggetWallpaperService.download(wallpaper)
            let count = try await Task.detached(priority: .userInitiated) {
                try TendiesInstaller.install(data: data)
            }.value
            didInstall = true
            resultMessage = count == 1
                ? "\(wallpaper.name) se agregó a Fondos."
                : "Se agregaron \(count) fondos de \(wallpaper.name)."
        } catch {
            didInstall = false
            resultMessage = error.localizedDescription
        }
        installingID = nil
    }

    func openWallpaperPicker() {
        _ = "com.apple.PosterBoard".withCString { launch_app($0) }
    }

    func clearResult() {
        resultMessage = nil
        didInstall = false
    }
}

struct WallpaperGalleryView: View {
    @ObservedObject private var gallery = WallpaperCatalogManager.shared
    @ObservedObject private var mgr = laramgr.shared

    @State private var category: WallpaperCatalogKind = .community
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var displayedItems: [NuggetWallpaper] {
        let currentMajorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        let items = gallery.items(for: category).filter {
            currentMajorVersion >= 26 || !$0.requiresIOS26
        }
        guard !searchText.isEmpty else { return items }
        let query = searchText.lowercased()
        return items.filter {
            $0.name.lowercased().contains(query) ||
            ($0.description ?? "").lowercased().contains(query) ||
            $0.authorLine.lowercased().contains(query)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Picker("Colección", selection: $category) {
                    ForEach(WallpaperCatalogKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                if !mgr.sbxready {
                    LaraAccessView(compact: true)
                }

                if gallery.isLoading && gallery.items(for: category).isEmpty {
                    loadingView
                } else if let error = gallery.errorMessage,
                          gallery.items(for: category).isEmpty {
                    errorView(error)
                } else if displayedItems.isEmpty {
                    emptyView
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayedItems) { wallpaper in
                            NavigationLink {
                                CommunityWallpaperDetail(wallpaper: wallpaper)
                            } label: {
                                CommunityWallpaperCard(wallpaper: wallpaper)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Link(
                    "Catálogo oficial de Nugget Wallpapers",
                    destination: URL(string: "https://github.com/SerStars/Nugget-Wallpapers")!
                )
                .font(.footnote.weight(.medium))
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 36)
        }
        .searchable(text: $searchText, prompt: "Buscar fondo o creador")
        .refreshable { await gallery.load(forceRefresh: true) }
        .task {
            if gallery.community.isEmpty || gallery.apple.isEmpty {
                await gallery.load()
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Cargando la colección…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No pudimos cargar la colección")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Intentar de nuevo") {
                Task { await gallery.load(forceRefresh: true) }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Sin resultados")
                .font(.headline)
            Text("Prueba con otro nombre o creador.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

private struct CommunityWallpaperCard: View {
    let wallpaper: NuggetWallpaper

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: wallpaper.previewURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    ZStack {
                        Color(uiColor: .tertiarySystemFill)
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 205)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                Text(wallpaper.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(wallpaper.authorLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if wallpaper.requiresIOS26 {
                    Text("iOS 26")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
        }
    }
}

private struct CommunityWallpaperDetail: View {
    let wallpaper: NuggetWallpaper

    @ObservedObject private var gallery = WallpaperCatalogManager.shared
    @ObservedObject private var mgr = laramgr.shared

    private var isInstalling: Bool {
        gallery.installingID == wallpaper.id
    }

    private var isIncompatible: Bool {
        wallpaper.requiresIOS26 && ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 26
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let previewURL = wallpaper.previewURL {
                    RemoteAnimatedPreview(url: previewURL)
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .frame(maxWidth: 340)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(wallpaper.name)
                        .font(.title2.bold())
                    Text(wallpaper.authorLine)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    if let description = wallpaper.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    if let contest = wallpaper.contest, !contest.isEmpty {
                        Text(contest)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                if !mgr.sbxready {
                    LaraAccessView(compact: true)
                }

                if isIncompatible {
                    Label("Requiere iOS 26", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button {
                    Task { await gallery.install(wallpaper) }
                } label: {
                    HStack {
                        if isInstalling {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isInstalling ? "Descargando e instalando…" : "Agregar a Fondos")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!mgr.sbxready || gallery.installingID != nil || isIncompatible)

                Text("Los fondos y sus vistas previas pertenecen a sus respectivos creadores. Lara instala una copia local y no modifica otros fondos.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Vista previa")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Fondos", isPresented: Binding(
            get: { gallery.resultMessage != nil },
            set: { if !$0 { gallery.clearResult() } }
        )) {
            if gallery.didInstall {
                Button("Abrir Fondos") {
                    gallery.clearResult()
                    gallery.openWallpaperPicker()
                }
                Button("Después", role: .cancel) { gallery.clearResult() }
            } else {
                Button("Aceptar", role: .cancel) { gallery.clearResult() }
            }
        } message: {
            Text(gallery.resultMessage ?? "")
        }
    }
}

private struct RemoteAnimatedPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = false
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        webView.isUserInteractionEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url == nil else { return }
        let escapedURL = url.absoluteString
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
        let html = """
        <html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"></head>
        <body style="margin:0;background:#000;overflow:hidden;display:flex;align-items:center;justify-content:center;height:100vh">
        <img src="\(escapedURL)" style="width:100%;height:100%;object-fit:cover" />
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

enum TendiesInstaller {
    static let maximumCompressedSize = 120 * 1024 * 1024
    private static let maximumExpandedSize: UInt64 = 1_200 * 1024 * 1024
    private static let maximumDescriptors = 64

    static func install(data: Data) throws -> Int {
        guard data.count <= maximumCompressedSize else {
            throw CommunityWallpaperError.packageTooLarge
        }

        let archive = try ZipArchive(data: data)
        let expandedSize = archive.entries.reduce(UInt64(0)) { partial, entry in
            partial.addingReportingOverflow(entry.uncompressedSize).overflow
                ? UInt64.max
                : partial + entry.uncompressedSize
        }
        guard expandedSize <= maximumExpandedSize else {
            throw CommunityWallpaperError.packageTooLarge
        }

        let fm = FileManager.default
        let root = fm.temporaryDirectory
            .appendingPathComponent("LaraTendies-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        try extract(archive, to: root)
        let descriptors = try findDescriptors(in: root)
        guard !descriptors.isEmpty else { throw CommunityWallpaperError.noDescriptors }
        guard descriptors.count <= maximumDescriptors else {
            throw CommunityWallpaperError.tooManyDescriptors
        }

        var installed: [URL] = []
        do {
            for descriptor in descriptors {
                try randomize(descriptor: descriptor)
                installed.append(try PosterBoardWriter.install(descriptor: descriptor))
            }
            return installed.count
        } catch {
            for destination in installed {
                try? fm.removeItem(at: destination)
            }
            throw error
        }
    }

    private static func extract(_ archive: ZipArchive, to root: URL) throws {
        let fm = FileManager.default
        let safeRoot = root.standardizedFileURL.path + "/"

        for entry in archive.entries {
            let normalized = entry.path.replacingOccurrences(of: "\\", with: "/")
            let components = normalized.split(separator: "/", omittingEmptySubsequences: true)
            guard !normalized.hasPrefix("/"), !components.contains("..") else {
                throw CommunityWallpaperError.invalidPackage
            }
            if components.contains("__MACOSX") || components.last?.hasPrefix("._") == true {
                continue
            }

            let output = root.appendingPathComponent(normalized).standardizedFileURL
            guard output.path == root.path || output.path.hasPrefix(safeRoot) else {
                throw CommunityWallpaperError.invalidPackage
            }

            if entry.isDirectory {
                try fm.createDirectory(at: output, withIntermediateDirectories: true)
            } else {
                try fm.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
                try archive.extract(entry).write(to: output, options: .atomic)
            }
        }
    }

    private static func findDescriptors(in root: URL) throws -> [URL] {
        let markerName = "com.apple.posterkit.provider.descriptor.identifier"
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw CommunityWallpaperError.invalidPackage
        }

        var descriptors: [URL] = []
        for case let file as URL in enumerator where file.lastPathComponent == markerName {
            let descriptor = file.deletingLastPathComponent()
            let versions = descriptor.appendingPathComponent("versions", isDirectory: true)
            if fm.fileExists(atPath: versions.path), !descriptors.contains(descriptor) {
                descriptors.append(descriptor)
            }
        }
        return descriptors
    }

    private static func randomize(descriptor: URL) throws {
        let identifier = Int.random(in: 10_000...99_999)
        let fm = FileManager.default
        try Data("\(identifier)".utf8).write(
            to: descriptor.appendingPathComponent("com.apple.posterkit.provider.descriptor.identifier"),
            options: .atomic
        )

        guard let enumerator = fm.enumerator(
            at: descriptor,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for case let file as URL in enumerator {
            switch file.lastPathComponent {
            case "com.apple.posterkit.provider.contents.userInfo":
                try updatePlist(at: file) { plist in
                    plist["wallpaperRepresentingIdentifier"] = identifier
                }
            case "Wallpaper.plist":
                try updatePlist(at: file) { plist in
                    plist["identifier"] = identifier
                }
            default:
                continue
            }
        }
    }

    private static func updatePlist(
        at url: URL,
        mutate: (inout [String: Any]) -> Void
    ) throws {
        let data = try Data(contentsOf: url)
        guard var plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw CommunityWallpaperError.invalidPackage
        }
        mutate(&plist)
        let updated = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        )
        try updated.write(to: url, options: .atomic)
    }
}
