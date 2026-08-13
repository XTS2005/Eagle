import SwiftUI
import PhotosUI
import AVKit
import AVFoundation
import Combine
import CoreTransferable
import UniformTypeIdentifiers

struct LaraMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let fm = FileManager.default
            let folder = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Wallpaper Drafts", isDirectory: true)
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = folder.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            try fm.copyItem(at: received.file, to: destination)
            return LaraMovie(url: destination)
        }
    }
}

struct AnimatedWallpapersView: View {
    @ObservedObject private var mgr = laramgr.shared
    @StateObject private var installer = AnimatedWallpaperInstaller()

    @State private var pickerItem: PhotosPickerItem?
    @State private var movieURL: URL?
    @State private var player: AVPlayer?
    @State private var autoReverses = false
    @State private var loadingSelection = false
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                intro
                preview

                if !mgr.sbxready {
                    LaraAccessView(compact: true)
                }

                if movieURL != nil {
                    options
                }

                actionArea
                attribution
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Fondos animados")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            load(item)
        }
        .onDisappear {
            player?.pause()
        }
        .alert("Fondos animados", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            if installer.didInstall {
                Button("Abrir Fondos") {
                    message = nil
                    installer.openWallpaperPicker()
                }
                Button("Después", role: .cancel) { message = nil }
            } else {
                Button("Aceptar", role: .cancel) { message = nil }
            }
        } message: {
            Text(message ?? "")
        }
        .onChange(of: installer.resultMessage) { result in
            if let result { message = result }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Tu video, en la pantalla de bloqueo")
                .font(.title2.weight(.bold))
            Text("Elige un clip corto. Lara lo adapta y lo agrega a la colección de fondos de iOS.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.black)

            if let player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .onAppear {
                        player.isMuted = true
                        player.play()
                    }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "play.rectangle.on.rectangle.fill")
                        .font(.system(size: 38, weight: .medium))
                    Text("Selecciona un video")
                        .font(.headline)
                }
                .foregroundStyle(.white.opacity(0.82))
            }

            VStack(spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.caption.weight(.medium))
                Text("9:41")
                    .font(.system(size: 60, weight: .semibold, design: .rounded))
                Spacer()
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
            .padding(.top, 38)
            .allowsHitTesting(false)
        }
        .aspectRatio(9.0 / 17.5, contentMode: .fit)
        .frame(maxWidth: 286)
        .frame(maxWidth: .infinity)
        .shadow(color: .black.opacity(0.13), radius: 20, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(movieURL == nil ? "Vista previa vacía" : "Vista previa del fondo animado")
    }

    private var options: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $autoReverses) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Repetición suave")
                        .font(.body.weight(.medium))
                    Text("El video vuelve hacia atrás antes de comenzar otra vez.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.blue)
            .padding(18)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var actionArea: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .videos) {
                Label(movieURL == nil ? "Elegir video" : "Elegir otro video", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(installer.isWorking || loadingSelection)

            if let movieURL {
                Button {
                    installer.install(video: movieURL, autoReverses: autoReverses)
                } label: {
                    HStack {
                        if installer.isWorking {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(installer.isWorking ? "Preparando fondo…" : "Agregar a Fondos")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!mgr.sbxready || installer.isWorking)
            }

            if installer.isWorking {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(installer.progressLabel)
                            .font(.footnote.weight(.medium))
                        Spacer()
                        Text("\(Int(installer.progress * 100))%")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: installer.progress)

                    Button("Cancelar", role: .cancel) {
                        installer.cancel()
                    }
                    .font(.footnote.weight(.medium))
                }
                .padding(.top, 4)
            }
        }
    }

    private var attribution: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Hasta 12 segundos. El audio no se incluye.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Link("Tecnología basada en Pocket Poster", destination: URL(string: "https://github.com/leminlimez/Pocket-Poster")!)
                .font(.footnote.weight(.medium))
        }
        .padding(.top, 4)
    }

    private func load(_ item: PhotosPickerItem) {
        loadingSelection = true
        Task {
            do {
                guard let movie = try await item.loadTransferable(type: LaraMovie.self) else {
                    throw AnimatedWallpaperError.invalidVideo
                }
                let duration = CMTimeGetSeconds(AVURLAsset(url: movie.url).duration)
                guard duration.isFinite, duration > 0 else {
                    throw AnimatedWallpaperError.invalidVideo
                }
                guard duration <= AnimatedWallpaperBuilder.maximumDuration else {
                    throw AnimatedWallpaperError.videoTooLong
                }

                await MainActor.run {
                    player?.pause()
                    movieURL = movie.url
                    player = AVPlayer(url: movie.url)
                    player?.isMuted = true
                    player?.play()
                    loadingSelection = false
                    pickerItem = nil
                }
            } catch {
                await MainActor.run {
                    loadingSelection = false
                    pickerItem = nil
                    message = error.localizedDescription
                }
            }
        }
    }
}

enum AnimatedWallpaperError: LocalizedError {
    case invalidVideo
    case videoTooLong
    case cancelled
    case noFrames
    case posterBoardNotFound
    case posterBoardUnavailable
    case installationFailed

    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "No se pudo leer ese video. Prueba con otro archivo."
        case .videoTooLong:
            return "El video debe durar 12 segundos o menos."
        case .cancelled:
            return "La preparación fue cancelada."
        case .noFrames:
            return "No se pudieron extraer imágenes del video."
        case .posterBoardNotFound:
            return "Lara no pudo encontrar la colección de fondos del sistema."
        case .posterBoardUnavailable:
            return "La colección de fondos todavía no está preparada en este dispositivo."
        case .installationFailed:
            return "El fondo no pudo instalarse. No se modificó la colección existente."
        }
    }
}

final class AnimatedWallpaperInstaller: ObservableObject {
    @Published private(set) var isWorking = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var progressLabel = "Preparando"
    @Published private(set) var resultMessage: String?
    @Published private(set) var didInstall = false

    private let cancellationLock = NSLock()
    private var cancellationRequested = false

    func install(video: URL, autoReverses: Bool) {
        guard !isWorking, laramgr.shared.sbxready else { return }

        cancellationLock.lock()
        cancellationRequested = false
        cancellationLock.unlock()

        didInstall = false
        resultMessage = nil
        isWorking = true
        progress = 0
        progressLabel = "Analizando video"

        let screenSize = AnimatedWallpaperBuilder.recommendedPixelSize()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var buildRoot: URL?
            do {
                let build = try AnimatedWallpaperBuilder.build(
                    video: video,
                    autoReverses: autoReverses,
                    targetSize: screenSize,
                    isCancelled: { self.isCancelled },
                    progress: { value, label in
                        DispatchQueue.main.async {
                            self.progress = value * 0.88
                            self.progressLabel = label
                        }
                    }
                )
                buildRoot = build.workingRoot

                if self.isCancelled { throw AnimatedWallpaperError.cancelled }
                DispatchQueue.main.async {
                    self.progress = 0.92
                    self.progressLabel = "Agregando a Fondos"
                }

                try PosterBoardWriter.install(descriptor: build.descriptorURL)

                DispatchQueue.main.async {
                    self.progress = 1
                    self.progressLabel = "Listo"
                    self.isWorking = false
                    self.didInstall = true
                    self.resultMessage = "El fondo se agregó correctamente. Ahora puedes seleccionarlo en la colección de Fondos de iOS."
                }
            } catch {
                DispatchQueue.main.async {
                    self.isWorking = false
                    self.didInstall = false
                    self.resultMessage = error.localizedDescription
                }
            }

            if let buildRoot {
                try? FileManager.default.removeItem(at: buildRoot)
            }
        }
    }

    func cancel() {
        cancellationLock.lock()
        cancellationRequested = true
        cancellationLock.unlock()
        progressLabel = "Cancelando"
    }

    func openWallpaperPicker() {
        _ = "com.apple.PosterBoard".withCString { launch_app($0) }
    }

    private var isCancelled: Bool {
        cancellationLock.lock()
        defer { cancellationLock.unlock() }
        return cancellationRequested
    }
}

enum PosterBoardWriter {
    static func install(descriptor: URL) throws {
        let fm = FileManager.default
        guard let containerID = posterBoardContainerID() else {
            throw AnimatedWallpaperError.posterBoardNotFound
        }

        let version = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 17 ? "61" : "59"
        let target = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application")
            .appendingPathComponent(containerID, isDirectory: true)
            .appendingPathComponent("Library/Application Support/PRBPosterExtensionDataStore", isDirectory: true)
            .appendingPathComponent(version, isDirectory: true)
            .appendingPathComponent("Extensions/com.apple.WallpaperKit.CollectionsPoster/descriptors", isDirectory: true)

        guard fm.fileExists(atPath: target.deletingLastPathComponent().path) else {
            throw AnimatedWallpaperError.posterBoardUnavailable
        }

        try fm.createDirectory(at: target, withIntermediateDirectories: true)
        let destination = target.appendingPathComponent(descriptor.lastPathComponent, isDirectory: true)
        guard !fm.fileExists(atPath: destination.path) else {
            throw AnimatedWallpaperError.installationFailed
        }

        do {
            try fm.copyItem(at: descriptor, to: destination)
            let marker = destination.appendingPathComponent("com.apple.posterkit.provider.descriptor.identifier")
            guard fm.fileExists(atPath: marker.path) else {
                try? fm.removeItem(at: destination)
                throw AnimatedWallpaperError.installationFailed
            }
        } catch {
            try? fm.removeItem(at: destination)
            throw error
        }
    }

    private static func posterBoardContainerID() -> String? {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application", isDirectory: true)
        guard let containers = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return nil
        }

        for container in containers {
            let metadata = container.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            guard let dict = NSDictionary(contentsOf: metadata),
                  let identifier = dict["MCMMetadataIdentifier"] as? String else { continue }
            if identifier == "com.apple.PosterBoard" {
                return container.lastPathComponent
            }
        }
        return nil
    }
}

enum AnimatedWallpaperBuilder {
    static let maximumDuration = 12.0
    static let maximumFrames = 300

    struct BuildResult {
        let workingRoot: URL
        let descriptorURL: URL
    }

    static func recommendedPixelSize() -> CGSize {
        let native = UIScreen.main.nativeBounds.size
        let shortEdge = min(native.width, native.height)
        let longEdge = max(native.width, native.height)
        let targetShort = min(shortEdge, 1080)
        let scale = targetShort / shortEdge
        return CGSize(width: targetShort, height: floor(longEdge * scale))
    }

    static func build(
        video: URL,
        autoReverses: Bool,
        targetSize: CGSize,
        isCancelled: () -> Bool,
        progress: (Double, String) -> Void
    ) throws -> BuildResult {
        let fm = FileManager.default
        let workingRoot = fm.temporaryDirectory.appendingPathComponent("LaraPoster-\(UUID().uuidString)", isDirectory: true)
        let descriptorURL = workingRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: descriptorURL, withIntermediateDirectories: true)

        do {
            let identifier = Int.random(in: 10_000...99_999)
            let wallpaperName = "9183.Custom-810w-1080h@2x~ipad.wallpaper"
            let contents = descriptorURL.appendingPathComponent("versions/1/contents", isDirectory: true)
            let wallpaper = contents.appendingPathComponent(wallpaperName, isDirectory: true)
            let backgroundName = "9183.Custom_Background-810w-1080h@2x~ipad.ca"
            let floatingName = "9183.Custom_Floating-810w-1080h@2x~ipad.ca"
            let background = wallpaper.appendingPathComponent(backgroundName, isDirectory: true)
            let floating = wallpaper.appendingPathComponent(floatingName, isDirectory: true)
            let assets = background.appendingPathComponent("assets", isDirectory: true)
            try fm.createDirectory(at: assets, withIntermediateDirectories: true)
            try fm.createDirectory(at: floating, withIntermediateDirectories: true)

            try Data("\(identifier)".utf8).write(to: descriptorURL.appendingPathComponent("com.apple.posterkit.provider.descriptor.identifier"))
            try Data("PRPosterRoleLockScreen".utf8).write(to: descriptorURL.appendingPathComponent("com.apple.posterkit.role.identifier"))
            guard let providerInfo = Data(base64Encoded: providerInfoBase64) else {
                throw AnimatedWallpaperError.installationFailed
            }
            try providerInfo.write(to: descriptorURL.appendingPathComponent("providerInfo.plist"))

            let userInfo: [String: Any] = [
                "posterEnvironmentOverrides": Data("{}".utf8),
                "wallpaperRepresentingFileName": wallpaperName,
                "wallpaperRepresentingIdentifier": identifier
            ]
            try plistData(userInfo).write(to: contents.appendingPathComponent("com.apple.posterkit.provider.contents.userInfo"))

            let wallpaperPlist: [String: Any] = [
                "appearanceAware": true,
                "assets": [
                    "lockAndHome": [
                        "default": [
                            "backgroundAnimationFileName": backgroundName,
                            "floatingAnimationFileNameKey": floatingName,
                            "identifier": identifier,
                            "name": "Lara Motion",
                            "type": "LayeredAnimation"
                        ]
                    ]
                ],
                "contentVersion": 2.01,
                "family": "Lara Motion",
                "identifier": identifier,
                "logicalScreenClass": "810w-1080h@2x~ipad",
                "name": "Lara Motion",
                "preferredProminentColor": ["dark": "#000000", "default": "#FFFFFF"],
                "version": 1
            ]
            try plistData(wallpaperPlist).write(to: wallpaper.appendingPathComponent("Wallpaper.plist"))

            let width = max(1, Int(targetSize.width.rounded()))
            let height = max(1, Int(targetSize.height.rounded()))
            try emptyFloatingCAML(width: width, height: height).data(using: .utf8)!.write(to: floating.appendingPathComponent("main.caml"))
            try indexXML(width: width, height: height).data(using: .utf8)!.write(to: floating.appendingPathComponent("index.xml"))

            progress(0.03, "Leyendo el video")
            let asset = AVURLAsset(url: video)
            let duration = CMTimeGetSeconds(asset.duration)
            guard duration.isFinite, duration > 0 else { throw AnimatedWallpaperError.invalidVideo }
            guard duration <= maximumDuration else { throw AnimatedWallpaperError.videoTooLong }
            guard let track = asset.tracks(withMediaType: .video).first else { throw AnimatedWallpaperError.invalidVideo }

            let sourceFPS = track.nominalFrameRate > 0 ? Double(track.nominalFrameRate) : 30
            let requestedFPS = min(30, max(15, sourceFPS))
            let frameCount = min(maximumFrames, max(2, Int(floor(duration * requestedFPS))))
            let effectiveFPS = Double(frameCount) / duration
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: targetSize.width * 1.15, height: targetSize.height * 1.15)

            var frameValues = ""
            for index in 0..<frameCount {
                if isCancelled() { throw AnimatedWallpaperError.cancelled }
                try autoreleasepool {
                    let seconds = min(duration - 0.001, Double(index) / effectiveFPS)
                    let time = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    guard let data = jpegAspectFill(cgImage, size: targetSize) else {
                        throw AnimatedWallpaperError.noFrames
                    }
                    try data.write(to: assets.appendingPathComponent("\(index).jpg"))
                    frameValues += "\t\t\t<CGImage src=\"assets/\(index).jpg\"/>\n"
                }
                progress(Double(index + 1) / Double(frameCount), "Procesando cuadro \(index + 1) de \(frameCount)")
            }

            guard !frameValues.isEmpty else { throw AnimatedWallpaperError.noFrames }
            let animationDuration = Double(frameCount) / effectiveFPS
            let main = animatedCAML(
                width: width,
                height: height,
                duration: animationDuration,
                autoReverses: autoReverses,
                values: frameValues
            )
            try main.data(using: .utf8)!.write(to: background.appendingPathComponent("main.caml"))
            try indexXML(width: width, height: height).data(using: .utf8)!.write(to: background.appendingPathComponent("index.xml"))

            return BuildResult(workingRoot: workingRoot, descriptorURL: descriptorURL)
        } catch {
            try? fm.removeItem(at: workingRoot)
            throw error
        }
    }

    private static func plistData(_ object: Any) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: object, format: .xml, options: 0)
    }

    private static func jpegAspectFill(_ image: CGImage, size: CGSize) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let rendered = renderer.image { _ in
            let source = UIImage(cgImage: image)
            let sourceSize = source.size
            let scale = max(size.width / sourceSize.width, size.height / sourceSize.height)
            let drawSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
            let origin = CGPoint(x: (size.width - drawSize.width) / 2, y: (size.height - drawSize.height) / 2)
            source.draw(in: CGRect(origin: origin, size: drawSize))
        }
        return rendered.jpegData(compressionQuality: 0.72)
    }

    private static func indexXML(width: Int, height: Int) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>assetManifest</key><string>assetManifest.caml</string>
            <key>documentHeight</key><real>\(height)</real>
            <key>documentResizesToView</key><true/>
            <key>documentWidth</key><real>\(width)</real>
            <key>dynamicGuidesEnabled</key><true/>
            <key>geometryFlipped</key><false/>
            <key>guidesEnabled</key><true/>
            <key>interactiveMouseEventsEnabled</key><true/>
            <key>interactiveShowsCursor</key><true/>
            <key>interactiveTouchEventsEnabled</key><false/>
            <key>loopEnd</key><real>0.0</real>
            <key>loopStart</key><real>0.0</real>
            <key>loopingEnabled</key><false/>
            <key>multitouchDisablesMouse</key><false/>
            <key>multitouchEnabled</key><false/>
            <key>presentationMouseEventsEnabled</key><true/>
            <key>presentationShowsCursor</key><true/>
            <key>presentationTouchEventsEnabled</key><false/>
            <key>rootDocument</key><string>main.caml</string>
            <key>savesWindowFrame</key><false/>
            <key>scalesToFitInPlayer</key><true/>
            <key>showsTouches</key><true/>
            <key>snappingEnabled</key><true/>
            <key>timelineMarkers</key><string>[(null)]</string>
            <key>touchesColor</key><string>1 1 0 0.8</string>
            <key>unitsInPixelsInPlayer</key><true/>
        </dict>
        </plist>
        """
    }

    private static func emptyFloatingCAML(width: Int, height: Int) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <CALayer allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" hidden="0" name="_BACKGROUND" position="\(width / 2) \(height / 2)">
            <sublayers>
              <CALayer allowsEdgeAntialiasing="1" allowsGroupOpacity="1" anchorPoint="0 0" bounds="0 0 0 0" contentsFormat="RGBA8" cornerCurve="circular" name="_CENTER_BACKGROUND" position="\(width / 2) \(height / 2)"/>
            </sublayers>
            \(stateMarkup)
          </CALayer>
        </caml>
        """
    }

    private static func animatedCAML(width: Int, height: Int, duration: Double, autoReverses: Bool, values: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <CALayer allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" hidden="0" name="_FLOATING" position="\(width / 2) \(height / 2)">
            <sublayers>
              <CATransformLayer allowsEdgeAntialiasing="1" allowsGroupOpacity="1" allowsHitTesting="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" name="Lara Motion" position="\(width / 2) \(height / 2)">
                <sublayers>
                  <CALayer allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" name="Lara Video" position="\(width / 2) \(height / 2)">
                    <contents type="CGImage" src="assets/0.jpg"/>
                    <animations>
                      <animation type="CAKeyframeAnimation" calculationMode="linear" keyPath="contents" beginTime="1e-100" duration="\(duration)" removedOnCompletion="0" repeatCount="inf" repeatDuration="0" speed="1" timeOffset="0" autoreverses="\(autoReverses ? 1 : 0)">
                        <values>
        \(values)                        </values>
                      </animation>
                    </animations>
                  </CALayer>
                </sublayers>
              </CATransformLayer>
            </sublayers>
            \(stateMarkup)
          </CALayer>
        </caml>
        """
    }

    private static let stateMarkup = """
    <states>
      <LKState name="Locked"><elements/></LKState>
      <LKState name="Unlock"><elements/></LKState>
      <LKState name="Sleep"><elements/></LKState>
    </states>
    <stateTransitions>
      <LKStateTransition fromState="*" toState="Unlock"><elements/></LKStateTransition>
      <LKStateTransition fromState="Unlock" toState="*"><elements/></LKStateTransition>
      <LKStateTransition fromState="*" toState="Locked"><elements/></LKStateTransition>
      <LKStateTransition fromState="Locked" toState="*"><elements/></LKStateTransition>
      <LKStateTransition fromState="*" toState="Sleep"><elements/></LKStateTransition>
      <LKStateTransition fromState="Sleep" toState="*"><elements/></LKStateTransition>
    </stateTransitions>
    """

    private static let providerInfoBase64 = "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGmCwwVFhogVSRudWxs0w0ODxASFFdOUy5rZXlzWk5TLm9iamVjdHNWJGNsYXNzoRGAAqETgAOABV8QHGtDb25maWd1cmF0aW9uTGFzdFVzZURhdGVLZXnSFw8YGVdOUy50aW1lI0HGwARI1HUUgATSGxwdHlokY2xhc3NuYW1lWCRjbGFzc2VzVk5TRGF0ZaIdH1hOU09iamVjdNIbHCEiXxATTlNNdXRhYmxlRGljdGlvbmFyeaMjJB9fEBNOU011dGFibGVEaWN0aW9uYXJ5XE5TRGljdGlvbmFyeQAIABEAGgAkACkAMgA3AEkATABRAFMAWgBgAGcAbwB6AIEAgwCFAIcAiQCLAKoArwC3AMAAwgDHANIA2wDiAOUA7gDzAQkBDQEjAAAAAAAAAgEAAAAAAAAAJQAAAAAAAAAAAAAAAAAAATA="
}
