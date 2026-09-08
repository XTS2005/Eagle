import Foundation
import UIKit
import CryptoKit

nonisolated struct IslandLiveManifest: Codable, Sendable {
    let schemaVersion: Int
    let id: String
    let version: Int
    let packageURL: URL
    let sha256: String
    let byteCount: Int
    let frameCount: Int
    let fps: Double
    let width: Int
    let height: Int
    let frameSHA256: [String]

    var isSupported: Bool {
        let validID = id.range(of: "^[a-z0-9][a-z0-9-]{0,79}$", options: .regularExpression) != nil
        let release = id == "singularity-live" ? "island-v1" : "island-gifs-v1"
        return schemaVersion == 1 && validID && version == 1 &&
        packageURL.absoluteString == "https://github.com/leonardob8777-bit/Eagle-Gallery/releases/download/\(release)/\(id)-v1.zip" &&
        frameCount == 17 && fps == 6 && width == 1200 && height == 500 &&
        byteCount > 0 && byteCount <= 34 * 1024 * 1024 &&
        frameSHA256.count == 17 && ([sha256] + frameSHA256).allSatisfy {
            $0.count == 64 && $0.allSatisfy { "0123456789abcdef".contains($0) }
        }
    }
}

nonisolated struct IslandLiveTheme: Decodable, Identifiable, Sendable {
    let manifest: IslandLiveManifest
    let title: String
    let titleES: String
    let accent: String
    let previewURL: URL
    let posterURL: URL
    var id: String { manifest.id }

    private enum CodingKeys: String, CodingKey { case title, titleES, accent, previewURL, posterURL }
    init(from decoder: Decoder) throws {
        manifest = try IslandLiveManifest(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        titleES = try values.decode(String.self, forKey: .titleES)
        accent = try values.decode(String.self, forKey: .accent)
        previewURL = try values.decode(URL.self, forKey: .previewURL)
        posterURL = try values.decode(URL.self, forKey: .posterURL)
    }
    var isSupported: Bool {
        let base = "https://raw.githubusercontent.com/leonardob8777-bit/Eagle-Gallery/main/previews/island/"
        return manifest.isSupported && !title.isEmpty && title.count <= 80 &&
            !titleES.isEmpty && titleES.count <= 80 &&
            accent.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil &&
            previewURL.absoluteString == "\(base)\(id).gif" &&
            posterURL.absoluteString == "\(base)\(id).png"
    }
    var rgb: (red: Int32, green: Int32, blue: Int32) {
        let value = UInt32(accent.dropFirst(), radix: 16) ?? 0xD9D9D9
        return (Int32((value >> 16) & 255), Int32((value >> 8) & 255), Int32(value & 255))
    }
}

private nonisolated struct IslandLiveCatalog: Decodable {
    let schemaVersion: Int
    let themes: [IslandLiveTheme]
    var isSupported: Bool {
        schemaVersion == 1 && !themes.isEmpty && themes.count <= 500 &&
            themes.allSatisfy(\.isSupported) && Set(themes.map(\.id)).count == themes.count
    }
}

/// An isolated, on-demand Island package. Dock caches and configuration are
/// never reused or overwritten. The frame alpha is Vortex's original mask.
nonisolated enum IslandLiveMedia {
    static let previewURL = URL(string: "https://raw.githubusercontent.com/leonardob8777-bit/Eagle-Gallery/main/previews/island/singularity-live.gif")!
    static let posterURL = URL(string: "https://raw.githubusercontent.com/leonardob8777-bit/Eagle-Gallery/main/previews/island/singularity-live.png")!

    static func loadCatalog(force: Bool = false) async throws -> [IslandLiveTheme] {
        let fm = FileManager.default
        let root = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("EagleGallery/Island", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let saved = root.appendingPathComponent("island-gallery-v1.json")
        var request = URLRequest(url: URL(string: "https://raw.githubusercontent.com/leonardob8777-bit/Eagle-Gallery/main/catalogs/island-gallery-v1.json")!)
        request.timeoutInterval = 25
        request.cachePolicy = force ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200, data.count <= 2 * 1024 * 1024 else { throw URLError(.badServerResponse) }
            let catalog = try JSONDecoder().decode(IslandLiveCatalog.self, from: data)
            guard catalog.isSupported else { throw URLError(.cannotParseResponse) }
            try data.write(to: saved, options: .atomic)
            return catalog.themes
        } catch {
            let data = try Data(contentsOf: saved)
            guard data.count <= 2 * 1024 * 1024 else { throw URLError(.cannotParseResponse) }
            let catalog = try JSONDecoder().decode(IslandLiveCatalog.self, from: data)
            guard catalog.isSupported else { throw URLError(.cannotParseResponse) }
            return catalog.themes
        }
    }

    static func prepare(theme: IslandLiveTheme? = nil) async throws -> URL {
        // PNG validation and ZIP extraction must not stall the gallery UI.
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let fm = FileManager.default
            let root = try fm.url(for: .cachesDirectory, in: .userDomainMask,
                                  appropriateFor: nil, create: true)
                .appendingPathComponent("EagleGallery/Island", isDirectory: true)
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            if let theme, !theme.isSupported { throw URLError(.cannotParseResponse) }
            let themeID = theme?.id ?? "singularity-live"
            let savedManifest = root.appendingPathComponent("\(themeID)-v1.json")
            let manifestURL = URL(string: "https://raw.githubusercontent.com/leonardob8777-bit/Eagle-Gallery/main/catalogs/island-live-v1.json")!
            var request = URLRequest(url: manifestURL)
            request.timeoutInterval = 20
            let manifestData: Data
            if let theme {
                manifestData = try JSONEncoder().encode(theme.manifest)
            } else { do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200, data.count <= 32 * 1024 else {
                    throw URLError(.badServerResponse)
                }
                manifestData = data
            } catch {
                manifestData = try Data(contentsOf: savedManifest)
            } }
            let manifest = try JSONDecoder().decode(IslandLiveManifest.self, from: manifestData)
            try Task.checkCancellation()
            guard manifest.isSupported, manifest.id == themeID else { throw URLError(.cannotParseResponse) }
            let destination = root.appendingPathComponent("\(manifest.id)-v\(manifest.version)", isDirectory: true)
            if validFrames(in: destination, manifest: manifest) { return destination }

            request = URLRequest(url: manifest.packageURL)
            request.timeoutInterval = 90
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (download, response) = try await URLSession.shared.download(for: request)
            defer { try? fm.removeItem(at: download) }
            try Task.checkCancellation()
            let size = try download.resourceValues(forKeys: [.fileSizeKey]).fileSize
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200, size == manifest.byteCount else {
                throw URLError(.badServerResponse)
            }
            let data = try Data(contentsOf: download, options: .mappedIfSafe)
            guard digest(data) == manifest.sha256 else { throw URLError(.secureConnectionFailed) }
            let archive = try ZipArchive(data: data)
            let expected = Set((1...17).map { String(format: "frame%02d.png", $0) })
            let entries = archive.entries
            guard entries.count == 17, Set(entries.map(\.path)) == expected,
                  entries.allSatisfy({ !$0.isDirectory && $0.uncompressedSize > 0 && $0.uncompressedSize <= 2 * 1024 * 1024 }) else {
                throw URLError(.cannotDecodeContentData)
            }
            let staging = root.appendingPathComponent(".island-\(UUID().uuidString)", isDirectory: true)
            try fm.createDirectory(at: staging, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: staging) }
            for entry in entries {
                try Task.checkCancellation()
                try autoreleasepool {
                    try archive.extract(entry).write(to: staging.appendingPathComponent(entry.path), options: .atomic)
                }
            }
            guard validFrames(in: staging, manifest: manifest) else { throw URLError(.cannotDecodeContentData) }
            try Task.checkCancellation()
            if fm.fileExists(atPath: destination.path) { try fm.removeItem(at: destination) }
            try fm.moveItem(at: staging, to: destination)
            try manifestData.write(to: savedManifest, options: .atomic)
            return destination
        }
        return try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
    }

    private static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func validFrames(in directory: URL, manifest: IslandLiveManifest) -> Bool {
        (1...17).allSatisfy { index in
            autoreleasepool {
            let file = directory.appendingPathComponent(String(format: "frame%02d.png", index))
            guard let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  size > 0, size <= 2 * 1024 * 1024,
                  let data = try? Data(contentsOf: file, options: .mappedIfSafe),
                  digest(data) == manifest.frameSHA256[index - 1],
                  let image = UIImage(data: data)?.cgImage else { return false }
            return image.width == 1200 && image.height == 500
            }
        }
    }
}
