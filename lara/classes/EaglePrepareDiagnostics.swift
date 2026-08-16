import SwiftUI
import UIKit
import Combine

/// Passive, user-triggered diagnostics for Prepare.
///
/// This type deliberately does not observe `dsrunning`, persist markers, or write
/// anything before the kernel engine starts. A report is assembled only after the
/// user asks for one, so diagnostics cannot change the exploit's timing.
@MainActor
final class EaglePrepareDiagnostics: ObservableObject {
    static let shared = EaglePrepareDiagnostics()

    @Published private(set) var reportURL: URL?
    @Published private(set) var isCreatingReport = false
    @Published private(set) var reportError: String?

    private init() {}

    func createReport() {
        guard !isCreatingReport else { return }

        isCreatingReport = true
        reportError = nil

        let metadata = Self.metadata()
        DispatchQueue.global(qos: .utility).async {
            do {
                let url = try Self.writeReport(metadata: metadata)
                DispatchQueue.main.async {
                    self.reportURL = url
                    self.isCreatingReport = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.reportError = error.localizedDescription
                    self.isCreatingReport = false
                }
            }
        }
    }

    nonisolated private static func writeReport(metadata: String) throws -> URL {
        let manager = FileManager.default
        let documents = try manager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let source = documents.appendingPathComponent("lara.log")
        let destinationFolder = documents.appendingPathComponent(
            "EaglePrepareReports",
            isDirectory: true
        )

        try manager.createDirectory(
            at: destinationFolder,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )

        let rawLog = (try? Data(contentsOf: source)) ?? Data()
        let tail = rawLog.suffix(256 * 1024)
        let logText = String(data: tail, encoding: .utf8) ?? "<lara.log is not valid UTF-8>"
        let report = """
        Eagle Prepare Diagnostic
        Generated only after the user requested this report.
        No diagnostic observer or disk write runs during Prepare.

        \(metadata)

        Recent lara.log (last 256 KB, addresses redacted)
        --------------------------------------------------
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

    nonisolated private static func metadata() -> String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let locale = Locale.current.identifier

        return """
        App: Eagle \(version) (\(build))
        Device: \(machineIdentifier())
        iOS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)
        Locale: \(locale)
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        """
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LaraL10n.text(
                        en: "Prepare diagnostics",
                        es: "Diagnóstico de preparación"
                    ))
                        .font(.headline)

                    Text(LaraL10n.text(
                        en: "If the iPhone restarted, reopen Eagle and create this report. Nothing is recorded while Prepare is running.",
                        es: "Si el iPhone se reinició, vuelve a abrir Eagle y crea este reporte. No se registra nada mientras Preparar está en ejecución."
                    ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let url = diagnostics.reportURL {
                ShareLink(item: url) {
                    Label(
                        LaraL10n.text(en: "Share Prepare Report", es: "Compartir reporte de preparación"),
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button {
                    diagnostics.createReport()
                } label: {
                    HStack {
                        if diagnostics.isCreatingReport {
                            ProgressView()
                        }
                        Text(LaraL10n.text(en: "Create Prepare Report", es: "Crear reporte de preparación"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(diagnostics.isCreatingReport)
            }

            if let error = diagnostics.reportError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.18), lineWidth: 1)
        }
    }
}
