import SwiftUI
import PhotosUI
import Combine
import CoreTransferable
import UniformTypeIdentifiers
import AVFoundation
import UIKit

private enum LaraMatchSourceKind: String, Codable, Sendable {
    case photo = "Foto"
    case video = "Video"

    var localizedTitle: String {
        switch self {
        case .photo: return LaraL10n.text(en: "Photo", es: "Foto")
        case .video: return LaraL10n.text(en: "Video", es: "Video")
        }
    }
}

private struct LaraMatchStoredTone: Codable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    init(_ tone: CompleteStyleTone) {
        red = tone.red
        green = tone.green
        blue = tone.blue
    }

    var tone: CompleteStyleTone {
        CompleteStyleTone(red: red, green: green, blue: blue)
    }
}

private struct LaraSavedMatch: Codable, Identifiable, Sendable {
    let id: UUID
    let createdAt: Date
    let name: String
    let sourceKind: LaraMatchSourceKind
    let matchedPackID: String
    let tones: [LaraMatchStoredTone]
    let thumbnail: Data
}

private struct LaraMatchAnalysis {
    let sourceImage: UIImage
    let sourceKind: LaraMatchSourceKind
    let tones: [CompleteStyleTone]
    let matchedPack: CompleteStylePack

    var cardPack: CompleteStylePack {
        CompleteStylePack(
            id: matchedPack.id,
            name: "Eagle Match",
            tagline: "Creado desde tus colores.",
            summary: "Una combinación generada localmente a partir de tu imagen.",
            symbol: "camera.filters",
            tones: tones,
            motif: matchedPack.motif,
            wallpaperName: matchedPack.wallpaperName,
            wallpaperFile: matchedPack.wallpaperFile,
            wallpaperPreview: matchedPack.wallpaperPreview,
            wallpaperAuthor: matchedPack.wallpaperAuthor,
            passcodeName: matchedPack.passcodeName,
            passcodeFile: matchedPack.passcodeFile,
            passcodePreview: matchedPack.passcodePreview,
            passcodeAuthor: matchedPack.passcodeAuthor
        )
    }
}

private enum LaraMatchError: LocalizedError {
    case unsupportedSelection
    case videoFrameFailed
    case paletteFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedSelection:
            return LaraL10n.text(en: "Eagle could not read that photo or video. Try another item.", es: "Eagle no pudo leer esa foto o video. Prueba con otro elemento.")
        case .videoFrameFailed:
            return LaraL10n.text(en: "A frame could not be extracted from the video.", es: "No se pudo obtener un fotograma del video.")
        case .paletteFailed:
            return LaraL10n.text(en: "The image does not contain enough color information.", es: "La imagen no contiene suficiente información de color.")
        }
    }
}

private struct LaraMatchMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("EagleMatch-\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: destination)
            return LaraMatchMovie(url: destination)
        }
    }
}

@MainActor
private final class LaraMatchStore: ObservableObject {
    static let shared = LaraMatchStore()

    @Published private(set) var matches: [LaraSavedMatch] = []
    private let storageURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaraMatches", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        storageURL = directory.appendingPathComponent("Matches.plist")
        load()
    }

    func save(_ analysis: LaraMatchAnalysis) throws {
        guard let thumbnail = analysis.sourceImage.laraMatchThumbnailData else {
            throw LaraMatchError.paletteFailed
        }
        let match = LaraSavedMatch(
            id: UUID(),
            createdAt: Date(),
            name: LaraL10n.text(
                en: "Match · \(analysis.matchedPack.localizedName)",
                es: "Match · \(analysis.matchedPack.localizedName)"
            ),
            sourceKind: analysis.sourceKind,
            matchedPackID: analysis.matchedPack.id,
            tones: analysis.tones.map(LaraMatchStoredTone.init),
            thumbnail: thumbnail
        )
        matches.insert(match, at: 0)
        matches = Array(matches.prefix(8))
        try persist()
    }

    func delete(_ match: LaraSavedMatch) {
        matches.removeAll { $0.id == match.id }
        try? persist()
    }

    func analysis(from match: LaraSavedMatch) -> LaraMatchAnalysis? {
        guard let image = UIImage(data: match.thumbnail),
              let pack = CompleteStylePack.all.first(where: { $0.id == match.matchedPackID }),
              match.tones.count >= 3 else { return nil }
        return LaraMatchAnalysis(
            sourceImage: image,
            sourceKind: match.sourceKind,
            tones: Array(match.tones.prefix(3)).map(\.tone),
            matchedPack: pack
        )
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? PropertyListDecoder().decode([LaraSavedMatch].self, from: data) else {
            return
        }
        matches = decoded
    }

    private func persist() throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try encoder.encode(matches).write(to: storageURL, options: .atomic)
    }
}

private enum LaraMatchPaletteExtractor {
    private struct Bucket {
        var count = 0
        var red = 0.0
        var green = 0.0
        var blue = 0.0

        var tone: CompleteStyleTone {
            let divisor = Double(max(count, 1))
            return CompleteStyleTone(
                red: red / divisor,
                green: green / divisor,
                blue: blue / divisor
            )
        }
    }

    static func analyze(_ image: UIImage, sourceKind: LaraMatchSourceKind) throws -> LaraMatchAnalysis {
        let sampled = try sample(image)
        let tones = curatedTones(from: sampled)
        guard tones.count == 3 else { throw LaraMatchError.paletteFailed }
        let match = CompleteStylePack.all.min { left, right in
            distance(tones, from: left.tones) < distance(tones, from: right.tones)
        } ?? CompleteStylePack.all[0]
        return LaraMatchAnalysis(
            sourceImage: image,
            sourceKind: sourceKind,
            tones: tones,
            matchedPack: match
        )
    }

    private static func sample(_ image: UIImage) throws -> [(tone: CompleteStyleTone, weight: Int)] {
        guard let cgImage = image.cgImage else { throw LaraMatchError.paletteFailed }
        let width = 48
        let height = 48
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw LaraMatchError.paletteFailed }
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var buckets: [Int: Bucket] = [:]
        for index in stride(from: 0, to: pixels.count, by: 4) {
            guard pixels[index + 3] > 180 else { continue }
            let red = Double(pixels[index]) / 255
            let green = Double(pixels[index + 1]) / 255
            let blue = Double(pixels[index + 2]) / 255
            let key = (Int(red * 7) << 8) | (Int(green * 7) << 4) | Int(blue * 7)
            var bucket = buckets[key] ?? Bucket()
            bucket.count += 1
            bucket.red += red
            bucket.green += green
            bucket.blue += blue
            buckets[key] = bucket
        }

        return buckets.values
            .sorted { score($0) > score($1) }
            .map { ($0.tone, $0.count) }
    }

    private static func curatedTones(
        from sampled: [(tone: CompleteStyleTone, weight: Int)]
    ) -> [CompleteStyleTone] {
        guard let first = sampled.first?.tone else { return [] }
        var selected = [first]
        for candidate in sampled.dropFirst() {
            guard selected.allSatisfy({ colorDistance($0, candidate.tone) > 0.18 }) else { continue }
            selected.append(candidate.tone)
            if selected.count == 3 { break }
        }
        while selected.count < 3 {
            let base = selected.last ?? first
            selected.append(shifted(base, amount: Double(selected.count) * 0.16))
        }

        selected.sort { luminance($0) < luminance($1) }
        return [
            adjusted(selected[0], saturation: 0.38, brightness: 0.30),
            adjusted(selected[1], saturation: 0.48, brightness: 0.68),
            adjusted(selected[2], saturation: 0.56, brightness: 0.92)
        ]
    }

    private static func score(_ bucket: Bucket) -> Double {
        let tone = bucket.tone
        let maximum = max(tone.red, tone.green, tone.blue)
        let minimum = min(tone.red, tone.green, tone.blue)
        let saturation = maximum == 0 ? 0 : (maximum - minimum) / maximum
        return Double(bucket.count) * (0.72 + saturation * 0.55)
    }

    private static func adjusted(
        _ tone: CompleteStyleTone,
        saturation minimumSaturation: CGFloat,
        brightness targetBrightness: CGFloat
    ) -> CompleteStyleTone {
        let color = UIColor(red: tone.red, green: tone.green, blue: tone.blue, alpha: 1)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        let result = UIColor(
            hue: hue,
            saturation: max(saturation, minimumSaturation),
            brightness: targetBrightness,
            alpha: 1
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        result.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return CompleteStyleTone(red: red, green: green, blue: blue)
    }

    private static func shifted(_ tone: CompleteStyleTone, amount: Double) -> CompleteStyleTone {
        CompleteStyleTone(
            red: min(1, tone.red + amount * 0.45),
            green: min(1, tone.green + amount * 0.25),
            blue: min(1, tone.blue + amount * 0.55)
        )
    }

    private static func distance(_ tones: [CompleteStyleTone], from reference: [CompleteStyleTone]) -> Double {
        tones.reduce(0) { total, tone in
            total + (reference.map { colorDistance(tone, $0) }.min() ?? 1)
        }
    }

    private static func colorDistance(_ lhs: CompleteStyleTone, _ rhs: CompleteStyleTone) -> Double {
        let red = lhs.red - rhs.red
        let green = lhs.green - rhs.green
        let blue = lhs.blue - rhs.blue
        return sqrt(red * red + green * green + blue * blue)
    }

    private static func luminance(_ tone: CompleteStyleTone) -> Double {
        tone.red * 0.2126 + tone.green * 0.7152 + tone.blue * 0.0722
    }
}

struct LaraMatchView: View {
    @ObservedObject private var manager = CompleteStyleManager.shared
    @ObservedObject private var mgr = laramgr.shared
    @ObservedObject private var store = LaraMatchStore.shared
    @State private var pickerItem: PhotosPickerItem?
    @State private var analysis: LaraMatchAnalysis?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var savedMessage: String?
    @State private var includeWallpaper = true
    @State private var includePasscode = true
    @State private var includeCard = true
    @State private var showPreview = false
    @State private var showComparison = false
    @State private var showComponents = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                intro

                if let analysis {
                    resultHero(analysis)
                    palette(analysis)
                    recommendation(analysis)

                    DisclosureGroup(isExpanded: $showComponents) {
                        VStack(spacing: 0) {
                            matchToggle(
                                .wallpaper,
                                detail: analysis.matchedPack.wallpaperName,
                                isOn: $includeWallpaper
                            )
                            Divider().padding(.leading, 52)
                            matchToggle(
                                .passcode,
                                detail: analysis.matchedPack.passcodeName,
                                isOn: $includePasscode
                            )
                            Divider().padding(.leading, 52)
                            matchToggle(
                                .card,
                                detail: LaraL10n.text(en: "Palette created by Eagle", es: "Paleta creada por Eagle"),
                                isOn: $includeCard
                            )
                        }
                        .padding(.top, 8)
                    } label: {
                        Label("Qué aplicará Eagle", systemImage: "checklist")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    if !mgr.sbxready {
                        LaraAccessView(compact: true) {
                            manager.refreshCompatibility()
                        }
                    }

                    if manager.isWorking {
                        progressCard
                    }

                    actions(analysis)
                } else {
                    pickerHero
                }

                savedMatches

                Label(
                    "El análisis ocurre en tu iPhone. Eagle no sube tu foto ni tu video.",
                    systemImage: "hand.raised.fill"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Eagle Match")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if analysis != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $pickerItem,
                        matching: .any(of: [.images, .videos]),
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                    }
                    .accessibilityLabel("Elegir otra foto o video")
                }
            }
        }
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            Task { await process(item) }
        }
        .fullScreenCover(isPresented: $showPreview) {
            if let analysis {
                CompleteStyleLivePreviewView(
                    title: "Eagle Match",
                    wallpaperPack: includeWallpaper ? analysis.matchedPack : nil,
                    passcodePack: includePasscode ? analysis.matchedPack : nil,
                    cardPack: includeCard ? analysis.cardPack : nil
                ) {
                    apply(analysis)
                }
            }
        }
        .fullScreenCover(isPresented: $showComparison) {
            if let analysis {
                CompleteStyleComparisonView(
                    title: "Eagle Match",
                    proposedCardPack: analysis.cardPack,
                    proposedPasscodePack: analysis.matchedPack
                )
            }
        }
        .alert("Eagle Match", isPresented: Binding(
            get: { errorMessage != nil || savedMessage != nil },
            set: { presented in
                if !presented {
                    errorMessage = nil
                    savedMessage = nil
                }
            }
        )) {
            Button("Aceptar") {
                errorMessage = nil
                savedMessage = nil
            }
        } message: {
            Text(errorMessage ?? savedMessage ?? "")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Tu imagen se convierte en un estilo")
                .font(.title2.bold())
            Text("Eagle encuentra una paleta, genera la tarjeta y selecciona el fondo y los números que mejor combinan.")
                .foregroundStyle(.secondary)
        }
    }

    private var pickerHero: some View {
        PhotosPicker(
            selection: $pickerItem,
            matching: .any(of: [.images, .videos]),
            photoLibrary: .shared()
        ) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.13))
                        .frame(width: 78, height: 78)
                    if isProcessing {
                        ProgressView().controlSize(.large)
                    } else {
                        Image(systemName: "camera.filters")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.indigo)
                    }
                }
                VStack(spacing: 4) {
                    Text(isProcessing
                        ? LaraL10n.text(en: "Analyzing colors…", es: "Analizando colores…")
                        : LaraL10n.text(en: "Choose photo or video", es: "Elegir foto o video"))
                        .font(.headline)
                    Text("También puedes usar un fotograma de video")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 38)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [7, 7]))
                    .foregroundStyle(Color.indigo.opacity(0.25))
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    private func resultHero(_ analysis: LaraMatchAnalysis) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: analysis.sourceImage)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()
            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 4) {
                Label(analysis.sourceKind.localizedTitle, systemImage: analysis.sourceKind == .video ? "video.fill" : "photo.fill")
                    .font(.caption.weight(.semibold))
                Text(LaraL10n.text(
                    en: "Match with \(analysis.matchedPack.localizedName)",
                    es: "Match con \(analysis.matchedPack.localizedName)"
                ))
                    .font(.title2.bold())
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func palette(_ analysis: LaraMatchAnalysis) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(analysis.tones.enumerated()), id: \.offset) { _, tone in
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(tone.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                    }
            }
        }
    }

    private func recommendation(_ analysis: LaraMatchAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Selección inteligente")
                        .font(.headline)
                    Text("La combinación más cercana a tu paleta")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(analysis.matchedPack.localizedName)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(analysis.tones[1].color.opacity(0.14), in: Capsule())
            }

            matchSummaryRow(.wallpaper, value: analysis.matchedPack.wallpaperName, color: analysis.tones[2].color)
            matchSummaryRow(.passcode, value: analysis.matchedPack.passcodeName, color: analysis.tones[1].color)
            matchSummaryRow(
                .card,
                value: LaraL10n.text(en: "Custom palette", es: "Paleta personalizada"),
                color: analysis.tones[0].color
            )
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func actions(_ analysis: LaraMatchAnalysis) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { showPreview = true } label: {
                    Label("Vista previa", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                }
                Button { showComparison = true } label: {
                    Label("Comparar", systemImage: "rectangle.split.2x1")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button { apply(analysis) } label: {
                Label("Aplicar Eagle Match", systemImage: "wand.and.sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(analysis.tones[1].color)
            .controlSize(.large)
            .disabled(
                manager.isWorking ||
                !mgr.sbxready ||
                !(includeWallpaper || includePasscode || includeCard)
            )

            Button {
                do {
                    try store.save(analysis)
                    savedMessage = LaraL10n.text(
                        en: "Match saved. You can find it under My Matches.",
                        es: "Match guardado. Puedes recuperarlo desde Mis Matches."
                    )
                } catch {
                    errorMessage = error.localizedDescription
                }
            } label: {
                Label("Guardar en Mis Matches", systemImage: "bookmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var savedMatches: some View {
        if !store.matches.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mis Matches")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(store.matches) { match in
                            Button {
                                analysis = store.analysis(from: match)
                            } label: {
                                savedMatchCard(match)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.delete(match)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func savedMatchCard(_ match: LaraSavedMatch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let image = UIImage(data: match.thumbnail) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.secondary.opacity(0.15)
                }
            }
            .frame(width: 142, height: 94)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            Text(savedMatchName(match))
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(match.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 142, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(manager.stage).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(manager.progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: manager.progress)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func savedMatchName(_ match: LaraSavedMatch) -> String {
        guard let pack = CompleteStylePack.all.first(where: { $0.id == match.matchedPackID }) else {
            return match.name
        }
        return "Match · \(pack.localizedName)"
    }

    private func matchToggle(
        _ component: CompleteStyleComponent,
        detail: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: component.systemImage)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(component.title).font(.subheadline.weight(.medium))
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 9)
    }

    private func matchSummaryRow(
        _ component: CompleteStyleComponent,
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 11) {
            Image(systemName: component.systemImage)
                .foregroundStyle(color)
                .frame(width: 30)
            Text(component.title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func apply(_ analysis: LaraMatchAnalysis) {
        manager.apply(selection: CompleteStyleSelection(
            title: "Eagle Match",
            wallpaperPack: includeWallpaper ? analysis.matchedPack : nil,
            passcodePack: includePasscode ? analysis.matchedPack : nil,
            cardPack: includeCard ? analysis.cardPack : nil
        ))
    }

    private func process(_ item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil
        defer {
            isProcessing = false
            pickerItem = nil
        }

        do {
            let supportsImage = item.supportedContentTypes.contains { $0.conforms(to: .image) }
            let supportsVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }

            if supportsImage {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw LaraMatchError.unsupportedSelection
                }
                analysis = try LaraMatchPaletteExtractor.analyze(image, sourceKind: .photo)
                return
            }

            if supportsVideo,
               let movie = try await item.loadTransferable(type: LaraMatchMovie.self) {
                defer { try? FileManager.default.removeItem(at: movie.url) }
                let frame = try await videoFrame(from: movie.url)
                analysis = try LaraMatchPaletteExtractor.analyze(frame, sourceKind: .video)
                return
            }

            throw LaraMatchError.unsupportedSelection
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func videoFrame(from url: URL) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let seconds = duration.seconds.isFinite ? max(0, min(duration.seconds * 0.25, 2)) : 0
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1600, height: 1600)

        return try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) {
                _, image, _, result, error in
                if result == .succeeded, let image {
                    continuation.resume(returning: UIImage(cgImage: image))
                } else {
                    continuation.resume(throwing: error ?? LaraMatchError.videoFrameFailed)
                }
            }
        }
    }
}

struct CompleteStyleComparisonView: View {
    let title: String
    let proposedCardPack: CompleteStylePack
    let proposedPasscodePack: CompleteStylePack

    @ObservedObject private var mgr = laramgr.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentCard: UIImage?
    @State private var currentDigits: [String: UIImage] = [:]
    @State private var reveal: CGFloat = 0.5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Actual frente a nuevo")
                            .font(.title2.bold())
                        Text("Desliza la línea para comparar el diseño de Wallet. Ningún cambio se aplica desde esta pantalla.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    cardComparison

                    VStack(alignment: .leading, spacing: 11) {
                        Text("Código")
                            .font(.headline)
                        HStack(alignment: .top, spacing: 12) {
                            comparisonPasscodeCard(title: LaraL10n.text(en: "Current", es: "Actual")) {
                                CurrentPasscodeGrid(images: currentDigits)
                            }
                            comparisonPasscodeCard(title: LaraL10n.text(en: "New", es: "Nuevo")) {
                                AsyncImage(url: proposedPasscodePack.passcodePreviewURL) { phase in
                                    if case .success(let image) = phase {
                                        image.resizable().scaledToFit()
                                    } else {
                                        ProgressView().tint(.white)
                                    }
                                }
                            }
                        }
                    }

                    Label(
                        mgr.sbxready
                            ? LaraL10n.text(en: "The comparison uses the device's current files.", es: "La comparación usa los archivos actuales del dispositivo.")
                            : LaraL10n.text(en: "Prepare Eagle so it can read the current design.", es: "Prepara el acceso de Eagle para poder leer el diseño actual."),
                        systemImage: mgr.sbxready ? "checkmark.shield.fill" : "lock.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .onAppear { loadCurrentArtwork() }
        .onChange(of: mgr.sbxready) { ready in
            if ready { loadCurrentArtwork() }
        }
    }

    private var cardComparison: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Tarjeta de Wallet")
                    .font(.headline)
                Spacer()
                Text("ACTUAL")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text("NUEVO")
                    .font(.caption2.bold())
                    .foregroundStyle(proposedCardPack.secondary.color)
            }

            GeometryReader { geometry in
                let proposed = CompleteCardStyleEngine.previewImage(pack: proposedCardPack)
                ZStack(alignment: .leading) {
                    comparisonCardImage(proposed, fallback: proposedCardPack.secondary.color)

                    comparisonCardImage(currentCard, fallback: Color(uiColor: .tertiarySystemFill))
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width * reveal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                    Rectangle()
                        .fill(.white)
                        .frame(width: 3)
                        .shadow(color: .black.opacity(0.35), radius: 4)
                        .offset(x: geometry.size.width * reveal - 1.5)

                    Circle()
                        .fill(.white)
                        .frame(width: 38, height: 38)
                        .overlay {
                            Image(systemName: "arrow.left.and.right")
                                .font(.caption.bold())
                                .foregroundStyle(.black)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
                        .offset(x: geometry.size.width * reveal - 19)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            reveal = min(0.96, max(0.04, value.location.x / geometry.size.width))
                        }
                )
            }
            .aspectRatio(1.587, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func comparisonCardImage(_ image: UIImage?, fallback: Color) -> some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    fallback
                    Image(systemName: "creditcard")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func comparisonPasscodeCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 9) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
        }
        .padding(10)
        .background(.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func loadCurrentArtwork() {
        guard mgr.sbxready else {
            currentCard = nil
            currentDigits = [:]
            return
        }
        currentCard = CompleteCardStyleEngine.currentPreviewImage()
        currentDigits = CompletePasscodeStyleEngine.currentPreviewImages()
    }
}

private struct CurrentPasscodeGrid: View {
    let images: [String: UIImage]
    private let layout = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", ""]

    var body: some View {
        if images.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                Text("No disponible")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.65))
        } else {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3),
                spacing: 5
            ) {
                ForEach(Array(layout.enumerated()), id: \.offset) { _, digit in
                    if digit.isEmpty {
                        Color.clear
                    } else if let image = images[digit] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Circle()
                            .fill(.white.opacity(0.12))
                            .overlay { Text(digit).foregroundStyle(.white) }
                    }
                }
            }
            .padding(6)
        }
    }
}

private extension UIImage {
    var laraMatchThumbnailData: Data? {
        let maximum: CGFloat = 720
        let scale = min(1, maximum / max(size.width, size.height))
        let target = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }.jpegData(compressionQuality: 0.78)
    }
}
