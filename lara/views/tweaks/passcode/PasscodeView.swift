//
//  PasscodeView.swift
//  lara
//
//  Created by ruter on 29.03.26.
//

import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import Compression
import Combine

private let passcodeThemeStorageRoot = URL(
    fileURLWithPath: "/var/mobile/.DO-NOT-DELETE-lara/PasscodeThemes",
    isDirectory: true
)

private let passcodeBackupDir = passcodeThemeStorageRoot
    .appendingPathComponent("Originals", isDirectory: true)

struct PasscodeKey: Identifiable {
    let id: String
    let digit: String
    let displayName: String
    
    var sourceFilename: String { "\(id).png" }
}

final class PasscodeThemeManager: ObservableObject {
    static let shared = PasscodeThemeManager()

    @Published var isApplying = false
    @Published var progress: Double = 0
    @Published var message = ""

    private let fm = FileManager.default

    func createDirectoriesIfNeeded() {
        try? fm.createDirectory(
            at: passcodeBackupDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    func backupIfNeeded(targetPath: String) {
        createDirectoriesIfNeeded()
        let targetURL = URL(fileURLWithPath: targetPath)
        let backupURL = backupURLFor(targetPath: targetPath)

        guard fm.fileExists(atPath: targetPath) else { return }
        
        if !fm.fileExists(atPath: backupURL.path) {
            try? fm.copyItem(at: targetURL, to: backupURL)
        }
    }

    func hasBackup(targetPath: String) -> Bool {
        fm.fileExists(atPath: backupURLFor(targetPath: targetPath).path)
    }

    func restoreBackup(targetPath: String) throws {
        let backupURL = backupURLFor(targetPath: targetPath)
        guard fm.fileExists(atPath: backupURL.path) else { return }
        let data = try Data(contentsOf: backupURL)
        
        let overwrite = laramgr.shared.lara_overwritefile(
            target: targetPath,
            data: data
        )
        
        if !overwrite.ok {
            throw NSError(domain: "PasscodeTheme", code: 1, userInfo: [ NSLocalizedDescriptionKey: overwrite.message ]
            )
        }
    }
    
    func restoreAll(basePath: String, logmsg: ((String) -> Void)? = nil) throws {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: basePath) else {
            throw NSError(domain: "PasscodeTheme", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to enumerate cache"])
        }

        var allTargets: [String] = []
        for case let file as String in enumerator {
            guard file.lowercased().hasSuffix(".png") else { continue }
            let fullPath = "\(basePath)/\(file)"
            let lower = file.lowercased()
            for i in 0...9 {
                if lower.contains("other-2-\(i)--dark") ||
                   lower.contains("-\(i)-") ||
                   lower.contains("_\(i)_") ||
                   lower.contains("_\(i)@") {
                    allTargets.append(fullPath)
                    break
                }
            }
        }

        for path in allTargets {
            do {
                try restoreBackup(targetPath: path)
                logmsg?("restored \(path)")
            } catch {
                logmsg?("failed to restore \(path): \(error.localizedDescription)")
            }
        }
    }

    func applyImage(data: Data, to targetPath: String) throws {
        backupIfNeeded(targetPath: targetPath)
        guard hasBackup(targetPath: targetPath) else {
            throw NSError(
                domain: "PasscodeTheme",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: LaraL10n.text(
                    en: "The original digit could not be saved.",
                    es: "No se pudo guardar el número original."
                )]
            )
        }
        let overwrite = laramgr.shared.lara_overwritefile(target: targetPath, data: data)

        if !overwrite.ok { throw NSError(domain: "PasscodeTheme", code: 2, userInfo: [NSLocalizedDescriptionKey: overwrite.message]) }
    }

    private func backupURLFor(targetPath: String) -> URL {
        let sanitized = targetPath
            .replacingOccurrences(of: "/", with: "_")
        return passcodeBackupDir
            .appendingPathComponent(sanitized)
    }
}

struct PasscodeView: View {
    @ObservedObject var mgr: laramgr
    
    @State private var selectedKeys: [String: Data] = [:]
    @State private var showImagePicker: String?
    @State private var showFilePicker = false
    @State private var processing = false
    @State private var statusMessage: String = ""
    
    @ObservedObject private var themeManager = IconThemeManager.shared
    @ObservedObject private var passcodeThemeManager = PasscodeThemeManager.shared
    
    let initialImportURL: URL?
    
    init(mgr: laramgr, initialImportURL: URL? = nil) {
        self.mgr = mgr
        self.initialImportURL = initialImportURL
    }
    
    let telephonyOptions = [
        "TelephonyUI-15",
        "TelephonyUI-14",
        "TelephonyUI-13",
        "TelephonyUI-12",
        "TelephonyUI-11",
        "TelephonyUI-10",
        "TelephonyUI-9",
        "TelephonyUI-8"
    ]
    
    let passcodeKeys: [PasscodeKey] = [
        PasscodeKey(id: "0", digit: "0", displayName: "0"),
        PasscodeKey(id: "1", digit: "1", displayName: "1"),
        PasscodeKey(id: "2", digit: "2", displayName: "2"),
        PasscodeKey(id: "3", digit: "3", displayName: "3"),
        PasscodeKey(id: "4", digit: "4", displayName: "4"),
        PasscodeKey(id: "5", digit: "5", displayName: "5"),
        PasscodeKey(id: "6", digit: "6", displayName: "6"),
        PasscodeKey(id: "7", digit: "7", displayName: "7"),
        PasscodeKey(id: "8", digit: "8", displayName: "8"),
        PasscodeKey(id: "9", digit: "9", displayName: "9"),
    ]

    private var passcodeKeyMap: [String: PasscodeKey] { Dictionary(uniqueKeysWithValues: passcodeKeys.map { ($0.id, $0) }) }

    private let passcodeKeyLayout: [String?] = [
        "1", "2", "3",
        "4", "5", "6",
        "7", "8", "9",
        nil, "0", nil
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Un código más personal")
                        .font(.title2.bold())
                    Text("Elige un estilo completo o cambia cada número por separado. Eagle guarda los originales antes de aplicar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                NavigationLink {
                    PasscodeExploreView(mgr: mgr) { url in
                        importPassthmFile(url: url)
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .frame(width: 46, height: 46)
                            .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Explorar estilos")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Diseños creados por la comunidad")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)

                Button { showFilePicker = true } label: {
                    Label("Importar archivo .passthm", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if !mgr.sbxready {
                    LaraAccessView(compact: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vista previa")
                                .font(.headline)
                            Text(selectedKeys.isEmpty
                                ? LaraL10n.text(en: "Choose a style to begin", es: "Elige un estilo para comenzar")
                                : LaraL10n.text(en: "Tap a digit to change it", es: "Toca un número para cambiarlo"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !selectedKeys.isEmpty {
                            Text("\(selectedKeys.count)/10")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(Array(passcodeKeyLayout.enumerated()), id: \.offset) { _, keyId in
                            if let keyId, let key = passcodeKeyMap[keyId] {
                                PasscodeKeyButton(
                                    key: key,
                                    imageData: selectedKeys[key.id],
                                    onSelect: { showImagePicker = key.id }
                                )
                            } else {
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(18)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .environment(\.colorScheme, .dark)

                if passcodeThemeManager.isApplying {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(passcodeThemeManager.message)
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Text("\(Int(passcodeThemeManager.progress * 100))%")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: passcodeThemeManager.progress, total: 1.0)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if !statusMessage.isEmpty {
                    Label(
                        statusMessage,
                        systemImage: statusMessage.hasPrefix("Error") ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(statusMessage.hasPrefix("Error") ? Color.red : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    applyTheme()
                } label: {
                    Text("Aplicar estilo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(
                    selectedKeys.isEmpty ||
                    processing ||
                    passcodeThemeManager.isApplying ||
                    !mgr.sbxready
                )

                Menu {
                    Button(role: .destructive) {
                        selectedKeys.removeAll()
                    } label: {
                        Label("Limpiar selección", systemImage: "xmark.circle")
                    }

                    Button(role: .destructive) {
                        restoreTheme()
                    } label: {
                        Label("Restaurar números originales", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(processing || passcodeThemeManager.isApplying || !mgr.sbxready)
                } label: {
                    Label("Más opciones", systemImage: "ellipsis.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Estilo del código")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showImagePicker) { keyId in
            ImagePicker(imageData: $selectedKeys[keyId])
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "passthm") ?? .zip, .zip],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .task {
            if let url = initialImportURL {
                importPassthmFile(url: url)
            }
        }
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importPassthmFile(url: url)
        case .failure(let error):
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    func importPassthmFile(url: URL) {
        processing = true
        statusMessage = LaraL10n.text(en: "Importing style…", es: "Importando estilo…")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let data = try Data(contentsOf: url)
                let tempDir =
                    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                defer {
                    try? FileManager.default.removeItem(at: tempDir)
                }
                
                let zipPath = tempDir.appendingPathComponent("theme.zip")
                try data.write(to: zipPath)
                try themeManager.unzipFile(at: zipPath, to: tempDir)
                
                let extractedKeys = try findAndExtractImages(from: tempDir)
                
                DispatchQueue.main.async {
                    for (keyId, imageData) in extractedKeys {
                        selectedKeys[keyId] = imageData
                    }
                    processing = false
                    statusMessage = LaraL10n.text(
                        en: "Imported \(extractedKeys.count) digits.",
                        es: "Se importaron \(extractedKeys.count) números."
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    processing = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    struct ZipEntry {
        let compressionMethod: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let nameLength: Int
        let extraLength: Int
    }

    func readLocalFileEntry(
        data: Data,
        offset: Int
    ) -> ZipEntry? {
        guard offset + 30 <= data.count else { return nil }
        let compressionMethod = data.subdata(in: offset + 8..<offset + 10).withUnsafeBytes { $0.load(as: UInt16.self) }
        let compressedSize = Int(data.subdata(in: offset + 18..<offset + 22).withUnsafeBytes { $0.load(as: UInt32.self) })
        let uncompressedSize = Int(data.subdata(in: offset + 22..<offset + 26).withUnsafeBytes { $0.load(as: UInt32.self) })
        let nameLength = Int(data.subdata(in: offset + 26..<offset + 28).withUnsafeBytes { $0.load(as: UInt16.self) })
        let extraLength = Int(data.subdata(in: offset + 28..<offset + 30).withUnsafeBytes { $0.load(as: UInt16.self) })

        return ZipEntry(
            compressionMethod: compressionMethod,
            compressedSize: compressedSize,
            uncompressedSize: uncompressedSize,
            nameLength: nameLength,
            extraLength: extraLength
        )
    }
    
    func decompress(
        deflate data: Data,
        originalSize: Int
    ) -> Data? {
        guard originalSize > 0 else { return Data() }
        let destinationBuffer = UnsafeMutablePointer<UInt8>
            .allocate(capacity: originalSize)
        defer { destinationBuffer.deallocate() }
        
        let result = data.withUnsafeBytes { (sourceBuffer: UnsafeRawBufferPointer) -> Int in
            guard let baseAddress = sourceBuffer.baseAddress else { return 0 }
            return compression_decode_buffer(
                destinationBuffer,
                originalSize,
                baseAddress.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil,
                COMPRESSION_ZLIB
            )
        }
        
        return result == originalSize ? Data(bytes: destinationBuffer, count: originalSize) : nil
    }
    
    func findAndExtractImages(from directory: URL) throws -> [String: Data] {
        var result: [String: Data] = [:]
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return result }
        
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard ext == "png" || ext == "jpg" || ext == "jpeg" else { continue }
            
            let filename = fileURL.lastPathComponent.lowercased()
            let fullPath = fileURL.path.lowercased()
            
            if let keyId =
                matchFilenameToKey(filename) ??
                matchFilenameToKey(fullPath) {
                if let imageData = try? Data(contentsOf: fileURL) {
                    result[keyId] = imageData
                }
            }
        }
        
        return result
    }
    
    func matchFilenameToKey(_ filename: String) -> String? {
        let lowercased = filename.lowercased()
        
        for i in 0...9 {
            if lowercased.contains("other-2-\(i)--dark") ||
                lowercased.contains("-\(i)-") ||
                lowercased.contains("-\(i)@") ||
                lowercased.contains("_\(i)_") ||
                lowercased.contains("_\(i)@") ||
                lowercased.contains("/\(i).png") ||
                lowercased.contains("/\(i).jpg") ||
                lowercased.contains("/\(i).jpeg") {
                return String(i)
            }
        }
        
        return nil
    }
    
    func applyTheme() {
        guard mgr.sbxready else {
            statusMessage = LaraL10n.text(en: "Error: prepare Eagle first.", es: "Error: prepara el acceso de Eagle primero.")
            return
        }

        processing = true
        statusMessage = ""

        DispatchQueue.global(qos: .userInitiated).async {
            guard let basePath = resolveTelephonyBasePath() else {
                DispatchQueue.main.async {
                    processing = false
                    statusMessage = LaraL10n.text(en: "Error: the passcode interface was not found on this device.", es: "Error: no se encontró la interfaz del código en este dispositivo.")
                }
                return
            }

            let fm = FileManager.default
            guard let enumerator = fm.enumerator(atPath: basePath) else {
                DispatchQueue.main.async {
                    processing = false
                    statusMessage = LaraL10n.text(en: "Error: the current digits could not be located.", es: "Error: no se pudieron localizar los números actuales.")
                }
                return
            }

            var targets: [String: [String]] = [:]

            for case let file as String in enumerator {
                let lower = file.lowercased()
                guard lower.hasSuffix(".png") else { continue }

                for i in 0...9 {
                    if lower.contains("other-2-\(i)--dark") ||
                        lower.contains("-\(i)-") ||
                        lower.contains("_\(i)_") ||
                        lower.contains("_\(i)@") {
                        targets[String(i), default: []].append("\(basePath)/\(file)")
                    }
                }
            }

            let total = max(Double(selectedKeys.count), 1.0)
            var successCount = 0
            var failCount = 0
            var errors: [String] = []

            DispatchQueue.main.async {
                passcodeThemeManager.isApplying = true
                passcodeThemeManager.progress = 0
                passcodeThemeManager.message = LaraL10n.text(en: "Preparing style…", es: "Preparando estilo…")
            }

            defer {
                DispatchQueue.main.async {
                    processing = false
                    passcodeThemeManager.isApplying = false
                }
            }

            for (index, item) in selectedKeys.enumerated() {
                autoreleasepool {
                    let keyId = item.key
                    let imageData = item.value
                    let matched = targets[keyId] ?? []

                    DispatchQueue.main.async {
                        passcodeThemeManager.progress = Double(index) / total
                        passcodeThemeManager.message = LaraL10n.text(en: "Applying digit \(keyId)", es: "Aplicando número \(keyId)")
                    }

                    if matched.isEmpty {
                        failCount += 1
                        errors.append("no target found for \(keyId)")
                        return
                    }

                    for path in matched {
                        do {
                            try passcodeThemeManager.applyImage(data: imageData, to: path)
                            successCount += 1
                            mgr.logmsg("applied \(keyId) -> \(path)")
                        } catch {
                            failCount += 1
                            errors.append("\(path): \(error.localizedDescription)")
                            mgr.logmsg("failed \(path): \(error.localizedDescription)")
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                passcodeThemeManager.progress = 1.0

                if failCount == 0 {
                    passcodeThemeManager.message = LaraL10n.text(en: "Done", es: "Listo")
                    statusMessage = LaraL10n.text(en: "The style was applied successfully.", es: "El estilo se aplicó correctamente.")
                } else {
                    passcodeThemeManager.message = LaraL10n.text(en: "Finished with errors", es: "Terminado con errores")
                    statusMessage = LaraL10n.text(
                        en: "Error: \(successCount) files were applied and \(failCount) failed.\n\n\(errors.joined(separator: "\n"))",
                        es: "Error: se aplicaron \(successCount) archivos y fallaron \(failCount).\n\n\(errors.joined(separator: "\n"))"
                    )
                }
            }
        }
    }

    func resolveTelephonyBasePath() -> String? {
        for version in telephonyOptions {
            let path = "/var/mobile/Library/Caches/\(version)"

            if sbxdirExists(path: path) {
                mgr.logmsg("TelephonyUI cache: \(path)")
                return path
            }
        }
        
        return nil
    }

    func sbxdirExists(path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(
            atPath: path,
            isDirectory: &isDir
        ) && isDir.boolValue
    }
    
    func restoreTheme() {
        guard mgr.sbxready else {
            statusMessage = LaraL10n.text(en: "Error: prepare Eagle first.", es: "Error: prepara el acceso de Eagle primero.")
            return
        }
        processing = true
        statusMessage = ""

        DispatchQueue.global(qos: .userInitiated).async {
            guard let basePath = resolveTelephonyBasePath() else {
                DispatchQueue.main.async {
                    processing = false
                    statusMessage = LaraL10n.text(en: "Error: the passcode interface was not found on this device.", es: "Error: no se encontró la interfaz del código en este dispositivo.")
                }
                return
            }

            do {
                try passcodeThemeManager.restoreAll(basePath: basePath) { msg in
                    mgr.logmsg(msg)
                }
                DispatchQueue.main.async {
                    processing = false
                    statusMessage = LaraL10n.text(en: "The original digits were restored.", es: "Se restauraron los números originales.")
                }
            } catch {
                DispatchQueue.main.async {
                    processing = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct PasscodeKeyButton: View {
    let key: PasscodeKey
    let imageData: Data?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))

                    if let data = imageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: geo.size.width,
                                height: geo.size.width
                            )
                            .clipShape(Circle())
                    } else {
                        Text(key.digit)
                            .font(.system(size: 30, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Circle()
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
                .frame(
                    width: geo.size.width,
                    height: geo.size.width
                )
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(
        context: Context
    ) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(
            configuration: config
        )
        
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: PHPickerViewController,
        context: Context
    ) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            parent.dismiss()
            guard let result = results.first else { return }
            result.itemProvider.loadObject( ofClass: UIImage.self ) {
                [weak self] object, error in
                guard let image = object as? UIImage else { return }
                guard let self else { return }
                let resized = self.resizeImage(
                    image,
                    targetHeight: 202
                )
                if let pngData = resized.pngData() {
                    DispatchQueue.main.async {
                        self.parent.imageData = pngData
                    }
                }
            }
        }

        func resizeImage(
            _ image: UIImage,
            targetHeight: CGFloat
        ) -> UIImage {
            let scale = targetHeight / image.size.height
            let newWidth = image.size.width * scale
            let newSize = CGSize(
                width: newWidth,
                height: targetHeight
            )
            
            let renderer = UIGraphicsImageRenderer( size: newSize )
            return renderer.image { _ in
                image.draw(
                    in: CGRect(
                        origin: .zero,
                        size: newSize
                    )
                )
            }
        }
    }
}
