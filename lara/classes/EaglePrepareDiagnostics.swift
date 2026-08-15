import Combine
import Darwin
import Foundation
import SwiftUI
import UIKit

/// A small, independent flight recorder for the high-risk Prepare operation.
///
/// Its pending marker is written synchronously when `dsrunning` changes to true.
/// `@Published` delivers that change before `laramgr.run` dispatches `ds_run`, so
/// the marker is durable before native execution starts. The native engine also
/// maintains its own journal; when that journal reports an interrupted attempt,
/// this reporter creates a shareable incident even if Swift never wrote a marker.
final class EaglePrepareDiagnostics: ObservableObject {
    struct Incident: Equatable {
        let attemptID: String
        let stage: String
        let reportURL: URL
        let interrupted: Bool
    }

    static let shared = EaglePrepareDiagnostics()

    @Published private(set) var latestIncident: Incident?

    var latestReportURL: URL? { latestIncident?.reportURL }

    private struct AttemptMarker: Codable {
        var schema = 1
        let attemptID: String
        let launchID: String
        let startedAt: String
        var updatedAt: String
        var stage: String
        var progress: Double?
        let appVersion: String
        let appBuild: String
        let deviceModel: String
        let systemVersion: String
        var nativeJournalInterrupted: Bool
    }

    private struct JournalEvent: Codable {
        let timestamp: String
        let attemptID: String
        let stage: String
        let progress: Double?
        let detail: String?
    }

    private struct IncidentIndex: Codable {
        let attemptID: String
        let stage: String
        let reportFilename: String
        let interrupted: Bool
    }

    private let fileManager = FileManager.default
    private let launchID = UUID().uuidString
    private let lock = NSLock()
    private var subscriptions = Set<AnyCancellable>()
    private var isObserving = false
    private var activeAttempt: AttemptMarker?
    private var lastProgressBucket = -1

    private lazy var diagnosticsDirectory: URL = {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("EaglePrepareDiagnostics", isDirectory: true)
    }()

    private lazy var reportsDirectory: URL = {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Eagle Diagnostics", isDirectory: true)
    }()

    private lazy var pendingMarkerURL = diagnosticsDirectory.appendingPathComponent("prepare-pending.json")
    private lazy var journalURL = diagnosticsDirectory.appendingPathComponent("prepare-events.ndjson")
    private lazy var incidentIndexURL = diagnosticsDirectory.appendingPathComponent("unacknowledged-incident.json")

    private init() {
        createDirectoryIfNeeded(diagnosticsDirectory)
        createDirectoryIfNeeded(reportsDirectory)
        recoverInterruptedAttemptIfPresent()
        restoreUnacknowledgedIncidentIfPresent()
    }

    /// Installs synchronous observations once. This is intentionally called from
    /// `App.init`, before a user can reach any Prepare button.
    func startObserving(manager: laramgr) {
        lock.lock()
        guard !isObserving else {
            lock.unlock()
            return
        }
        isObserving = true
        lock.unlock()

        manager.$dsrunning
            .removeDuplicates()
            .sink { [weak self] running in
                if running {
                    self?.beginAttemptIfNeeded()
                } else {
                    self?.markStage("kernel.returned")
                }
            }
            .store(in: &subscriptions)

        manager.$dsready
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in self?.markStage("kernel.ready") }
            .store(in: &subscriptions)

        manager.$dsfailed
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.finishAttempt(success: false, stage: "kernel.failed")
            }
            .store(in: &subscriptions)

        manager.$dsprogress
            .sink { [weak self] progress in self?.recordProgress(progress) }
            .store(in: &subscriptions)

        manager.$sbxrunning
            .removeDuplicates()
            .sink { [weak self] running in
                if running { self?.markStage("sandbox.start") }
            }
            .store(in: &subscriptions)

        manager.$sbxready
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.finishAttempt(success: true, stage: "sandbox.ready")
            }
            .store(in: &subscriptions)

        manager.$sbxfailed
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.finishAttempt(success: false, stage: "sandbox.failed")
            }
            .store(in: &subscriptions)
    }

    /// Additional callers can record a bounded stage without exposing raw paths,
    /// tokens, kernel addresses, or arbitrary environment data.
    func markStage(_ stage: String, progress: Double? = nil, detail: String? = nil) {
        lock.lock()
        guard var attempt = activeAttempt else {
            lock.unlock()
            return
        }
        attempt.stage = boundedStage(stage)
        attempt.progress = progress.map { min(max($0, 0), 1) }
        attempt.updatedAt = Self.timestamp()
        activeAttempt = attempt
        lock.unlock()

        persist(marker: attempt)
        appendEvent(
            attemptID: attempt.attemptID,
            stage: attempt.stage,
            progress: attempt.progress,
            detail: detail.map(sanitize)
        )
    }

    /// Starts a marker for Prepare paths that reuse an already-open kernel
    /// session and therefore never toggle `dsrunning`.
    func beginPipelineAttempt(stage: String = "pipeline.start") {
        beginAttemptIfNeeded()
        markStage(stage)
    }

    /// Lets the coordinator close failures such as compatibility-data timeout,
    /// where laramgr has no dsfailed/sbxfailed property transition to observe.
    func finishAttemptFromPipeline(success: Bool, stage: String) {
        finishAttempt(success: success, stage: stage)
    }

    /// Records only redacted, short native messages. Full raw engine output is
    /// deliberately never copied into a shareable diagnostic.
    func recordEngineMessage(_ message: String) {
        let safeMessage = String(sanitize(message).prefix(480))
        guard !safeMessage.isEmpty else { return }
        markStage("engine.message", detail: safeMessage)
    }

    func refreshShareReport() {
        lock.lock()
        let incident = latestIncident
        lock.unlock()
        guard let incident else { return }

        // Rebuilding adds any best-effort log lines produced after recovery. It
        // never removes the existing report or the persistent event journal.
        if let marker = markerFromIncident(incident),
           let refreshedURL = createReport(
                marker: marker,
                reason: incident.interrupted ? "interrupted" : "failed",
                interrupted: incident.interrupted,
                replacing: incident.reportURL
           ) {
            publishIncident(
                Incident(
                    attemptID: incident.attemptID,
                    stage: incident.stage,
                    reportURL: refreshedURL,
                    interrupted: incident.interrupted
                )
            )
        }
    }

    /// Hides the incident card after the user has had an opportunity to save or
    /// share it. Reports and journals remain on disk, and retries are never gated.
    func acknowledgeIncident() {
        lock.lock()
        let incident = latestIncident
        lock.unlock()
        if let incident {
            appendEvent(
                attemptID: incident.attemptID,
                stage: "review.dismissed",
                progress: nil,
                detail: "report-preserved"
            )
        }
        nativeClearInterruptedAttempt()
        removeUnacknowledgedIncidentIndex()
        if Thread.isMainThread {
            latestIncident = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.latestIncident = nil
            }
        }
    }

    private func beginAttemptIfNeeded() {
        lock.lock()
        guard activeAttempt == nil else {
            lock.unlock()
            return
        }

        let now = Self.timestamp()
        let attempt = AttemptMarker(
            attemptID: UUID().uuidString,
            launchID: launchID,
            startedAt: now,
            updatedAt: now,
            stage: "kernel.dispatch",
            progress: 0,
            appVersion: Self.appVersion,
            appBuild: Self.appBuild,
            deviceModel: Self.deviceModel,
            systemVersion: UIDevice.current.systemVersion,
            nativeJournalInterrupted: nativePreviousAttemptInterrupted()
        )
        activeAttempt = attempt
        lastProgressBucket = 0
        lock.unlock()

        // This synchronous durable write happens before laramgr can dispatch
        // ds_run to its worker queue.
        persist(marker: attempt)
        appendEvent(
            attemptID: attempt.attemptID,
            stage: attempt.stage,
            progress: 0,
            detail: nil
        )
    }

    private func recordProgress(_ progress: Double) {
        guard progress.isFinite else { return }
        let normalized = min(max(progress, 0), 1)
        let bucket = Int((normalized * 10).rounded(.down))

        lock.lock()
        guard activeAttempt != nil, bucket > lastProgressBucket else {
            lock.unlock()
            return
        }
        lastProgressBucket = bucket
        lock.unlock()
        markStage("kernel.progress", progress: normalized)
    }

    private func finishAttempt(success: Bool, stage: String) {
        lock.lock()
        guard var attempt = activeAttempt else {
            lock.unlock()
            return
        }
        attempt.stage = boundedStage(stage)
        attempt.progress = success ? 1 : attempt.progress
        attempt.updatedAt = Self.timestamp()
        activeAttempt = nil
        lastProgressBucket = -1
        lock.unlock()

        persist(marker: attempt)
        appendEvent(
            attemptID: attempt.attemptID,
            stage: attempt.stage,
            progress: attempt.progress,
            detail: success ? "completed" : "returned-error"
        )

        if success {
            removePendingMarkerAfterDurableCompletion()
        } else if let reportURL = createReport(marker: attempt, reason: "failed", interrupted: false) {
            publishIncident(
                Incident(
                    attemptID: attempt.attemptID,
                    stage: attempt.stage,
                    reportURL: reportURL,
                    interrupted: false
                )
            )
            removePendingMarkerAfterDurableCompletion()
        }
    }

    private func recoverInterruptedAttemptIfPresent() {
        var recoveredMarker: AttemptMarker?
        if let data = try? Data(contentsOf: pendingMarkerURL),
           let marker = try? JSONDecoder().decode(AttemptMarker.self, from: data) {
            recoveredMarker = marker
        }

        let nativeInterrupted = nativePreviousAttemptInterrupted()
        if recoveredMarker == nil, nativeInterrupted {
            let now = Self.timestamp()
            recoveredMarker = AttemptMarker(
                attemptID: "native-" + UUID().uuidString,
                launchID: launchID,
                startedAt: now,
                updatedAt: now,
                stage: "native.interrupted",
                progress: nil,
                appVersion: Self.appVersion,
                appBuild: Self.appBuild,
                deviceModel: Self.deviceModel,
                systemVersion: UIDevice.current.systemVersion,
                nativeJournalInterrupted: true
            )
        }

        guard var marker = recoveredMarker else { return }
        marker.nativeJournalInterrupted = marker.nativeJournalInterrupted || nativeInterrupted
        appendEvent(
            attemptID: marker.attemptID,
            stage: "relaunch.detected-interruption",
            progress: marker.progress,
            detail: marker.stage
        )

        guard let reportURL = createReport(marker: marker, reason: "interrupted", interrupted: true) else {
            return
        }
        publishIncident(
            Incident(
                attemptID: marker.attemptID,
                stage: marker.stage,
                reportURL: reportURL,
                interrupted: true
            )
        )

        // The report and append-only journal now contain the marker evidence.
        // Removing only the transient pending file prevents duplicate incidents;
        // neither the report nor any previous event/log is deleted.
        removePendingMarkerAfterDurableCompletion()
    }

    private func restoreUnacknowledgedIncidentIfPresent() {
        guard latestIncident == nil,
              let data = try? Data(contentsOf: incidentIndexURL),
              let index = try? JSONDecoder().decode(IncidentIndex.self, from: data),
              (index.reportFilename as NSString).lastPathComponent == index.reportFilename
        else { return }

        let reportURL = reportsDirectory.appendingPathComponent(index.reportFilename)
        guard fileManager.fileExists(atPath: reportURL.path) else { return }
        publishIncident(
            Incident(
                attemptID: index.attemptID,
                stage: index.stage,
                reportURL: reportURL,
                interrupted: index.interrupted
            )
        )
    }

    private func persist(marker: AttemptMarker) {
        guard let data = try? JSONEncoder().encode(marker) else { return }
        atomicDurableWrite(data, to: pendingMarkerURL)
    }

    private func appendEvent(
        attemptID: String,
        stage: String,
        progress: Double?,
        detail: String?
    ) {
        let event = JournalEvent(
            timestamp: Self.timestamp(),
            attemptID: attemptID,
            stage: boundedStage(stage),
            progress: progress,
            detail: detail
        )
        guard var data = try? JSONEncoder().encode(event) else { return }
        data.append(0x0A)

        createDirectoryIfNeeded(diagnosticsDirectory)
        if !fileManager.fileExists(atPath: journalURL.path) {
            fileManager.createFile(
                atPath: journalURL.path,
                contents: nil,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
        }
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: journalURL.path
        )
        guard let handle = try? FileHandle(forWritingTo: journalURL) else { return }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.synchronize()
            try handle.close()
            synchronizeParentDirectory(of: journalURL)
        } catch {
            try? handle.close()
        }
    }

    private func createReport(
        marker: AttemptMarker,
        reason: String,
        interrupted: Bool,
        replacing existingURL: URL? = nil
    ) -> URL? {
        createDirectoryIfNeeded(reportsDirectory)
        let reportURL: URL
        if let existingURL,
           existingURL.deletingLastPathComponent().standardizedFileURL == reportsDirectory.standardizedFileURL,
           (existingURL.lastPathComponent as NSString).pathExtension == "txt" {
            // Refresh the existing report in place. Creating a new report every
            // time Home appears would leak an unbounded number of diagnostics.
            reportURL = existingURL
        } else {
            let shortID = String(marker.attemptID.prefix(8))
            let revision = String(UUID().uuidString.prefix(4))
            let filename = "Eagle-Prepare-Diagnostic-\(Self.filenameTimestamp())-\(shortID)-\(revision).txt"
            reportURL = reportsDirectory.appendingPathComponent(filename)
        }

        let events = journalLines(for: marker.attemptID)
        let currentLog = sanitizedCurrentLog()
        let nativeState = marker.nativeJournalInterrupted ? "interrupted marker present" : "no interrupted marker reported"
        let text = """
        Eagle Prepare Diagnostic
        ========================
        Generated: \(Self.timestamp())
        Result: \(interrupted ? "interrupted before a verified completion" : reason)
        Attempt: \(marker.attemptID)
        Last verified stage: \(marker.stage)
        Last progress: \(marker.progress.map { String(format: "%.0f%%", $0 * 100) } ?? "unavailable")
        Started: \(marker.startedAt)
        Last update: \(marker.updatedAt)

        App: Eagle \(marker.appVersion) (\(marker.appBuild))
        Device model: \(marker.deviceModel)
        iOS: \(marker.systemVersion)
        Native Prepare journal: \(nativeState)

        Persistent Prepare events
        -------------------------
        \(events.isEmpty ? "No Swift events were recoverable." : events)

        Sanitized lara.log (best effort)
        --------------------------------
        \(currentLog.isEmpty ? "No current log lines were available after relaunch." : currentLog)

        Privacy
        -------
        File-system paths, access tokens, sandbox extensions, long identifiers,
        and memory/kernel addresses are redacted before this file is created.
        """

        guard let data = sanitize(text).data(using: .utf8) else { return nil }
        atomicDurableWrite(data, to: reportURL)
        return fileManager.fileExists(atPath: reportURL.path) ? reportURL : nil
    }

    private func journalLines(for attemptID: String) -> String {
        guard let text = readTail(of: journalURL, maximumBytes: 192 * 1024) else { return "" }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        let matching = lines.filter { $0.contains(attemptID) }.suffix(80)
        return sanitize(matching.joined(separator: "\n"))
    }

    private func sanitizedCurrentLog() -> String {
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lara.log")
        guard let text = readTail(of: url, maximumBytes: 96 * 1024) else { return "" }
        return sanitize(text)
    }

    private func readTail(of url: URL, maximumBytes: UInt64) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        do {
            let end = try handle.seekToEnd()
            let start = end > maximumBytes ? end - maximumBytes : 0
            try handle.seek(toOffset: start)
            guard let data = try handle.readToEnd(), !data.isEmpty else { return nil }
            return String(decoding: data, as: UTF8.self)
        } catch {
            return nil
        }
    }

    private func markerFromIncident(_ incident: Incident) -> AttemptMarker? {
        guard let text = try? String(contentsOf: incident.reportURL, encoding: .utf8) else { return nil }
        func value(after label: String) -> String? {
            text.split(separator: "\n", omittingEmptySubsequences: false)
                .first { $0.hasPrefix(label) }
                .map { String($0.dropFirst(label.count)).trimmingCharacters(in: .whitespaces) }
        }
        let now = Self.timestamp()
        let progress = value(after: "Last progress:").flatMap { text -> Double? in
            guard text != "unavailable" else { return nil }
            return Double(text.replacingOccurrences(of: "%", with: "")).map { $0 / 100 }
        }
        return AttemptMarker(
            attemptID: incident.attemptID,
            launchID: launchID,
            startedAt: value(after: "Started:") ?? now,
            updatedAt: value(after: "Last update:") ?? now,
            stage: incident.stage,
            progress: progress,
            appVersion: Self.appVersion,
            appBuild: Self.appBuild,
            deviceModel: Self.deviceModel,
            systemVersion: UIDevice.current.systemVersion,
            nativeJournalInterrupted: text.contains("Native Prepare journal: interrupted")
        )
    }

    private func publishIncident(_ incident: Incident) {
        persistUnacknowledgedIncident(incident)
        if Thread.isMainThread {
            latestIncident = incident
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.latestIncident = incident
            }
        }
    }

    private func persistUnacknowledgedIncident(_ incident: Incident) {
        let index = IncidentIndex(
            attemptID: incident.attemptID,
            stage: incident.stage,
            reportFilename: incident.reportURL.lastPathComponent,
            interrupted: incident.interrupted
        )
        guard let data = try? JSONEncoder().encode(index) else { return }
        atomicDurableWrite(data, to: incidentIndexURL)
    }

    private func removeUnacknowledgedIncidentIndex() {
        guard fileManager.fileExists(atPath: incidentIndexURL.path) else { return }
        _ = unlink(incidentIndexURL.path)
        synchronizeParentDirectory(of: incidentIndexURL)
    }

    private func atomicDurableWrite(_ data: Data, to url: URL) {
        createDirectoryIfNeeded(url.deletingLastPathComponent())
        let temporaryURL = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        do {
            fileManager.createFile(
                atPath: temporaryURL.path,
                contents: nil,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
            let handle = try FileHandle(forWritingTo: temporaryURL)
            try handle.write(contentsOf: data)
            try handle.synchronize()
            try handle.close()
            guard rename(temporaryURL.path, url.path) == 0 else {
                _ = unlink(temporaryURL.path)
                return
            }
            try? fileManager.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
            synchronizeParentDirectory(of: url)
        } catch {
            _ = unlink(temporaryURL.path)
        }
    }

    private func removePendingMarkerAfterDurableCompletion() {
        guard fileManager.fileExists(atPath: pendingMarkerURL.path) else { return }
        _ = unlink(pendingMarkerURL.path)
        synchronizeParentDirectory(of: pendingMarkerURL)
    }

    private func synchronizeParentDirectory(of url: URL) {
        let descriptor = open(url.deletingLastPathComponent().path, O_RDONLY)
        guard descriptor >= 0 else { return }
        _ = fsync(descriptor)
        _ = close(descriptor)
    }

    private func createDirectoryIfNeeded(_ url: URL) {
        try? fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }

    private func sanitize(_ value: String) -> String {
        var safe = value
        let patterns: [(String, String)] = [
            (#"(?i)\b(?:authorization|bearer|token|password|secret|sandbox[-_ ]?extension)\b\s*[:=]?\s*[^\s,;]+"#, "<redacted-credential>"),
            (#"(?:file:/{2,3})?/(?:[^\s/\"']+/)+[^\s\"']*"#, "<redacted-path>"),
            (#"\b0x[0-9a-fA-F]{8,}\b"#, "<redacted-address>"),
            (#"\b[0-9a-fA-F]{32,}\b"#, "<redacted-identifier>"),
            (#"\b[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\b"#, "<redacted-token>"),
            (#"\b[A-Za-z0-9_+\-/=]{64,}\b"#, "<redacted-long-value>")
        ]
        for (pattern, replacement) in patterns {
            safe = safe.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }
        return safe
    }

    private func boundedStage(_ stage: String) -> String {
        let filtered = stage.filter { $0.isLetter || $0.isNumber || ".-_".contains($0) }
        return String(filtered.prefix(80)).isEmpty ? "unknown" : String(filtered.prefix(80))
    }

    private func nativePreviousAttemptInterrupted() -> Bool {
        typealias NativeCheck = @convention(c) () -> Bool
        guard let handle = dlopen(nil, RTLD_NOW) else { return false }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "ds_previous_attempt_interrupted") else { return false }
        let function = unsafeBitCast(symbol, to: NativeCheck.self)
        return function()
    }

    private func nativeClearInterruptedAttempt() {
        typealias NativeClear = @convention(c) () -> Void
        guard let handle = dlopen(nil, RTLD_NOW) else { return }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "ds_clear_interrupted_attempt") else { return }
        let function = unsafeBitCast(symbol, to: NativeClear.self)
        function()
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private static var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    private static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    private static func filenameTimestamp() -> String {
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
        if let incident = diagnostics.latestIncident {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: incident.interrupted ? "exclamationmark.shield.fill" : "waveform.badge.exclamationmark")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LaraL10n.text(
                            en: "Prepare did not finish",
                            es: "La preparación no terminó"
                        ))
                            .font(.headline)
                        Text(LaraL10n.text(
                            en: "Eagle preserved a private diagnostic from the last attempt. You can share it without delaying another Prepare attempt.",
                            es: "Eagle conservó un diagnóstico privado del último intento. Puedes compartirlo sin retrasar otro intento de preparación."
                        ))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ShareLink(item: incident.reportURL) {
                    Label(
                        LaraL10n.text(en: "Share Crash Report", es: "Compartir reporte del fallo"),
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint(LaraL10n.text(
                    en: "Shares a redacted Prepare diagnostic without deleting it.",
                    es: "Comparte un diagnóstico redactado sin eliminarlo."
                ))

                Button {
                    diagnostics.acknowledgeIncident()
                } label: {
                    Text(LaraL10n.text(
                        en: "Dismiss Report",
                        es: "Ocultar reporte"
                    ))
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityHint(LaraL10n.text(
                    en: "Hides this card while keeping the diagnostic file and journal.",
                    es: "Oculta esta tarjeta y conserva el archivo de diagnóstico y el registro."
                ))
            }
            .padding(16)
            .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.22), lineWidth: 1)
            }
            .onAppear { diagnostics.refreshShareReport() }
        }
    }
}
