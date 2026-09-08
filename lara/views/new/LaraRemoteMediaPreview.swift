import SwiftUI
import WebKit
import Combine
import ImageIO

private struct LaraMediaPreviewsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var laraMediaPreviewsEnabled: Bool {
        get { self[LaraMediaPreviewsEnabledKey.self] }
        set { self[LaraMediaPreviewsEnabledKey.self] = newValue }
    }
}

@MainActor
private final class LaraRemoteMediaLoader: ObservableObject {
    enum State {
        case loading
        case loaded(Data, String)
        case failed
    }

    private static let cache: NSCache<NSURL, NSData> = {
        let cache = NSCache<NSURL, NSData>()
        cache.countLimit = 24
        cache.totalCostLimit = 24 * 1024 * 1024
        return cache
    }()

    @Published private(set) var state: State = .loading
    private var loadedURL: URL?
    private var generation = UUID()

    func release() {
        generation = UUID()
        loadedURL = nil
        state = .loading
    }

    static func clearCache() { cache.removeAllObjects() }

    func load(_ url: URL, forceRefresh: Bool = false) async {
        if !forceRefresh, loadedURL == url, case .loaded = state {
            return
        }

        loadedURL = url
        let requestGeneration = UUID()
        generation = requestGeneration
        state = .loading

        if !forceRefresh, let cached = Self.cache.object(forKey: url as NSURL) {
            state = .loaded(cached as Data, Self.mimeType(for: url, response: nil))
            return
        }

        for attempt in 0..<2 {
            do {
                try Task.checkCancellation()
                guard generation == requestGeneration else { return }
                var request = URLRequest(url: url)
                request.timeoutInterval = 35
                request.cachePolicy = forceRefresh || attempt > 0
                    ? .reloadIgnoringLocalCacheData
                    : .returnCacheDataElseLoad

                let (file, response) = try await URLSession.shared.download(for: request)
                defer { try? FileManager.default.removeItem(at: file) }
                try Task.checkCancellation()
                guard generation == requestGeneration else { return }

                guard
                    let http = response as? HTTPURLResponse,
                    (200..<300).contains(http.statusCode),
                    let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                    size > 0, size <= 40 * 1024 * 1024
                else {
                    throw URLError(.cannotDecodeContentData)
                }
                let data = try Data(contentsOf: file, options: .mappedIfSafe)
                guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                      CGImageSourceGetCount(source) > 0 else {
                    throw URLError(.cannotDecodeContentData)
                }

                Self.cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
                guard generation == requestGeneration else { return }
                state = .loaded(data, Self.mimeType(for: url, response: response))
                return
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, generation == requestGeneration else { return }
                if attempt == 0 {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                }
            }
        }

        guard !Task.isCancelled, generation == requestGeneration else { return }
        state = .failed
    }

    private static func mimeType(for url: URL, response: URLResponse?) -> String {
        if let mimeType = response?.mimeType, mimeType.hasPrefix("image/") {
            return mimeType
        }

        switch url.pathExtension.lowercased() {
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "png": return "image/png"
        default: return "image/jpeg"
        }
    }
}

struct LaraRemoteMediaPreview: View {
    let url: URL?
    var animated = false
    var contentMode: ContentMode = .fill
    var showsRetry = true
    var compactPlaceholder = false
    var background = Color(uiColor: .tertiarySystemFill)
    var onReady: ((Bool) -> Void)? = nil

    @StateObject private var loader = LaraRemoteMediaLoader()
    @State private var retryID = 0
    @State private var visible = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.laraMediaPreviewsEnabled) private var previewsEnabled

    private var shouldLoad: Bool { visible && previewsEnabled && scenePhase == .active }

    var body: some View {
        ZStack {
            background

            if url != nil {
                switch loader.state {
                case .loading:
                    loadingView
                case .loaded(let data, let mimeType):
                    loadedView(data: data, mimeType: mimeType)
                case .failed:
                    unavailableView
                }
            } else {
                unavailableView
            }
        }
        .onAppear { visible = true }
        .onDisappear {
            visible = false
            loader.release()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            LaraRemoteMediaLoader.clearCache()
            if !shouldLoad { loader.release() }
        }
        .task(id: "\(url?.absoluteString ?? "missing")-\(retryID)-\(shouldLoad)") {
            guard shouldLoad else {
                loader.release()
                return
            }
            guard let url else {
                onReady?(false)
                return
            }
            onReady?(false)
            await loader.load(url, forceRefresh: retryID > 0)
            guard !Task.isCancelled else { return }
            if case .loaded = loader.state {
                onReady?(true)
            } else {
                onReady?(false)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func loadedView(data: Data, mimeType: String) -> some View {
        if animated && shouldLoad && !reduceMotion {
            LaraAnimatedDataView(data: data, mimeType: mimeType, contentMode: contentMode)
        } else if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            unavailableView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 9) {
            EagleRainbowSpinner(size: 22)
            if !compactPlaceholder {
                Text("Cargando vista previa…")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 9) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            if !compactPlaceholder {
                Text("Vista previa no disponible")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }

            if showsRetry, url != nil {
                Button("Intentar de nuevo") {
                    retryID += 1
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
            }
        }
        .multilineTextAlignment(.center)
        .padding(12)
    }
}

private struct LaraAnimatedDataView: UIViewRepresentable {
    let data: Data
    let mimeType: String
    let contentMode: ContentMode

    final class Coordinator {
        var fingerprint: Int?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.suppressesIncrementalRendering = false
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.isUserInteractionEnabled = false
        return webView
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.loadHTMLString("", baseURL: nil)
        coordinator.fingerprint = nil
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        var hasher = Hasher()
        hasher.combine(data.count)
        hasher.combine(data.prefix(64))
        hasher.combine(mimeType)
        hasher.combine(contentMode == .fill)
        let fingerprint = hasher.finalize()
        guard context.coordinator.fingerprint != fingerprint else { return }
        context.coordinator.fingerprint = fingerprint

        let encoded = data.base64EncodedString()
        let objectFit = contentMode == .fill ? "cover" : "contain"
        let html = """
        <html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <style>*{margin:0;padding:0}html,body{width:100%;height:100%;overflow:hidden;background:transparent}img{width:100%;height:100%;object-fit:\(objectFit)}</style>
        </head><body><img src="data:\(mimeType);base64,\(encoded)"></body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
