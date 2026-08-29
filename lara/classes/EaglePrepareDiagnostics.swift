import SwiftUI
import UIKit
import Combine
import Darwin

/// Passive, user-triggered diagnostics for Prepare.
///
/// A report is assembled only after the user asks for one. Prepare writes one
/// tiny durable checkpoint only at broad phase boundaries, never while
/// DarkSword's race is executing.
@MainActor
final class EaglePrepareDiagnostics: ObservableObject {
    static let shared = EaglePrepareDiagnostics()

    @Published private(set) var reportURL: URL?
    @Published private(set) var isCreatingReport = false
    @Published private(set) var reportError: String?

    private init() {}

    func createReport(onCreated: ((URL) -> Void)? = nil) {
        guard !isCreatingReport else { return }

        isCreatingReport = true
        reportError = nil
        reportURL = nil

        let metadata = Self.metadata()
        let attemptCheckpoint = EaglePrepareAttemptJournal.diagnosticText()
        DispatchQueue.global(qos: .utility).async {
            do {
                let url = try Self.writeReport(
                    metadata: metadata,
                    attemptCheckpoint: attemptCheckpoint
                )
                DispatchQueue.main.async {
                    self.reportURL = url
                    self.isCreatingReport = false
                    onCreated?(url)
                }
            } catch {
                DispatchQueue.main.async {
                    self.reportError = error.localizedDescription
                    self.isCreatingReport = false
                }
            }
        }
    }

    nonisolated private static func writeReport(
        metadata: String,
        attemptCheckpoint: String
    ) throws -> URL {
        let manager = FileManager.default
        let documents = try manager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let source = documents.appendingPathComponent("lara.log")
        let previousSource = documents.appendingPathComponent("lara.previous.log")
        let olderSource = documents.appendingPathComponent("lara.previous.2.log")
        let destinationFolder = documents.appendingPathComponent(
            "EaglePrepareReports",
            isDirectory: true
        )

        try manager.createDirectory(
            at: destinationFolder,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )

        let logText = readTail(source, maximumBytes: 256 * 1024)
        let previousLogText = readTail(previousSource, maximumBytes: 256 * 1024)
        let olderLogText = readTail(olderSource, maximumBytes: 256 * 1024)
        let report = """
        Eagle Prepare Diagnostic
        Generated only after the user requested this report.
        Report creation never starts automatically and adds no live Prepare observer.
        Prepare updates one small checkpoint only outside DarkSword's race.

        \(metadata)

        \(attemptCheckpoint)

        Older app session (may be unrelated; last 256 KB, addresses redacted)
        ----------------------------------------------------------------------
        \(redact(olderLogText))

        Previous app session (may be unrelated; last 256 KB, addresses redacted)
        -------------------------------------------------------------------------
        \(redact(previousLogText))

        Current app session (last 256 KB, addresses redacted)
        -----------------------------------------------------
        \(redact(logText))
        """

        let filename = "Eagle-Prepare-Diagnostic-\(filenameTimestamp()).txt"
        let destination = destinationFolder.appendingPathComponent(filename)
        try Data(report.utf8).write(to: destination, options: .atomic)
        try? manager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: destination.path
        )
        return destination
    }

    nonisolated private static func readTail(
        _ url: URL,
        maximumBytes: Int
    ) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return "<not available>"
        }
        defer { try? handle.close() }

        do {
            let end = try handle.seekToEnd()
            let limit = UInt64(max(1, maximumBytes))
            if end > limit {
                try handle.seek(toOffset: end - limit)
            } else {
                try handle.seek(toOffset: 0)
            }
            let data = try handle.readToEnd() ?? Data()
            return String(decoding: data, as: UTF8.self)
        } catch {
            return "<could not read: \(error.localizedDescription)>"
        }
    }

    private static func metadata() -> String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let machine = machineIdentifier()
        let systemBuild = sysctlString("kern.osversion") ?? "unknown"
        let support = eagleSupportAssessment(
            version: os,
            machine: machine,
            systemBuild: systemBuild == "unknown" ? nil : systemBuild
        )
        let locale = Locale.current.identifier
        let launchContext = islcruntime() ? "LiveContainer" : "native app"

        return """
        App: Eagle \(version) (\(build))
        Device: \(machine)
        iOS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion) (\(systemBuild))
        Prepare support: \(support.status.rawValue) [\(support.reason.rawValue)]
        Launch context: \(launchContext)
        Locale: \(locale)
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        """
    }

    nonisolated private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else {
            return nil
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else {
            return nil
        }
        return String(cString: buffer)
    }

    nonisolated private static func machineIdentifier() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    nonisolated private static func redact(_ input: String) -> String {
        var output = input

        let patterns = [
            #"0x[0-9a-fA-F]{6,}"#,
            #"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"#
        ]

        for pattern in patterns {
            guard let expression = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(output.startIndex..., in: output)
            output = expression.stringByReplacingMatches(
                in: output,
                range: range,
                withTemplate: pattern.hasPrefix("0x") ? "<address>" : "<uuid>"
            )
        }

        return output
    }

    nonisolated private static func filenameTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

struct EaglePrepareCrashReportCard: View {
    @ObservedObject private var diagnostics = EaglePrepareDiagnostics.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                Text(LaraL10n.text(
                    en: "Prepare diagnostics",
                    es: "Diagnóstico de preparación"
                ))
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 0)
            }

            Text(LaraL10n.text(
                en: "If Prepare fails or the iPhone restarts, create and share this report.",
                es: "Si Preparar falla o el iPhone se reinicia, crea y comparte este reporte."
            ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                diagnostics.createReport { url in
                    presentShareSheet(with: url)
                }
            } label: {
                HStack(spacing: 10) {
                    if diagnostics.isCreatingReport {
                        EagleRainbowSpinner(size: 20)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.15, green: 0.62, blue: 0.87))
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: -1, y: 1)
                        }
                        .frame(width: 25, height: 25)
                    }

                    Text(LaraL10n.text(
                        en: "Create & send to @LEONARDOPHL",
                        es: "Crear y enviar a @LEONARDOPHL"
                    ))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(red: 0.15, green: 0.62, blue: 0.87))
            .disabled(diagnostics.isCreatingReport)
            .accessibilityHint(LaraL10n.text(
                en: "Creates the diagnostic and opens the share sheet with the file attached.",
                es: "Crea el diagnóstico y abre la hoja para compartir con el archivo adjunto."
            ))

            if let error = diagnostics.reportError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.22), lineWidth: 1)
        }
    }
}
