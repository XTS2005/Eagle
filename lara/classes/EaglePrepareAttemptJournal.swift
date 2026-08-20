import Darwin
import Foundation

/// A tiny, crash-resilient breadcrumb written only at broad Prepare boundaries.
/// It never observes progress and never performs I/O inside DarkSword's race.
enum EaglePrepareAttemptJournal {
    enum BeginResult {
        case started(String)
        case alreadyRecorded
        case unavailable
    }

    enum Stage: String, Codable {
        case armed
        case offsetsInitialized
        case darkSwordRunning
        case darkSwordReady
        case compatibilityDataRunning
        case compatibilityDataReady
        case sandboxOpening
        case completed
        case failed
    }

    private struct Record: Codable {
        let schemaVersion: Int
        let attemptID: String
        let startedAt: String
        let bootIdentifier: String
        let machine: String
        let systemVersion: String
        let systemBuild: String
        let appBuild: String
        let route: String
        var stage: Stage
        var detail: String?
        var updatedAt: String
        var completedAt: String?
    }

    private static let lock = NSLock()
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static func begin(
        route: String,
        machine: String,
        systemBuild: String
    ) -> BeginResult {
        lock.lock()
        defer { lock.unlock() }

        let now = timestamp()
        let os = ProcessInfo.processInfo.operatingSystemVersion
        if let url = journalURL(),
           FileManager.default.fileExists(atPath: url.path) {
            guard let existing = load() else { return .unavailable }
            if existing.route == route,
               existing.machine == machine,
               existing.systemBuild == systemBuild {
                return .alreadyRecorded
            }
        }
        let record = Record(
            schemaVersion: 1,
            attemptID: UUID().uuidString,
            startedAt: now,
            bootIdentifier: bootIdentifier(),
            machine: machine,
            systemVersion: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            systemBuild: systemBuild,
            appBuild: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String ?? "unknown",
            route: route,
            stage: .armed,
            detail: nil,
            updatedAt: now,
            completedAt: nil
        )

        guard write(record) else { return .unavailable }
        return .started(record.attemptID)
    }

    static func mark(
        _ attemptID: String?,
        stage: Stage,
        detail: String? = nil
    ) {
        guard let attemptID else { return }
        lock.lock()
        defer { lock.unlock() }

        guard var record = load(), record.attemptID == attemptID else { return }
        record.stage = stage
        record.detail = detail
        record.updatedAt = timestamp()
        _ = write(record)
    }

    static func finish(
        _ attemptID: String?,
        succeeded: Bool,
        detail: String? = nil
    ) {
        guard let attemptID else { return }
        lock.lock()
        defer { lock.unlock() }

        guard var record = load(), record.attemptID == attemptID else { return }
        let now = timestamp()
        record.stage = succeeded ? .completed : .failed
        record.detail = detail
        record.updatedAt = now
        record.completedAt = now
        _ = write(record)
    }

    /// A kernel-stage lab attempt is deliberately one-shot for an exact
    /// device/build. Even a completed attempt stays locked: another physical
    /// kernel test requires a separately prepared research build.
    static func hasRecordedAttempt(
        route: String,
        machine: String,
        systemBuild: String
    ) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let record = load() else { return false }
        return record.route == route &&
            record.machine == machine &&
            record.systemBuild == systemBuild
    }

    static func diagnosticText() -> String {
        lock.lock()
        defer { lock.unlock() }

        guard let record = load() else {
            return "Last Prepare checkpoint: none"
        }

        let currentBootIdentifier = bootIdentifier()
        let storedBootKnown = record.bootIdentifier != "unknown"
        let currentBootKnown = currentBootIdentifier != "unknown"
        let outcome: String
        if record.completedAt != nil {
            outcome = "finished"
        } else if !storedBootKnown || !currentBootKnown {
            outcome = "unfinished; boot comparison unavailable"
        } else if record.bootIdentifier != currentBootIdentifier {
            outcome = "interrupted after this checkpoint across a boot change"
        } else {
            outcome = "unfinished-on-current-boot"
        }

        return """
        Last Prepare checkpoint:
          attempt: \(record.attemptID)
          route: \(record.route)
          device/build: \(record.machine) / \(record.systemBuild)
          app build: \(record.appBuild)
          last checkpoint: \(record.stage.rawValue)
          outcome: \(outcome)
          started: \(record.startedAt)
          updated: \(record.updatedAt)
          detail: \(record.detail ?? "none")
        """
    }

    private static func load() -> Record? {
        guard let url = journalURL(),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(Record.self, from: data)
    }

    private static func write(_ record: Record) -> Bool {
        guard let url = journalURL(createDirectory: true),
              let data = try? encoder.encode(record) else {
            return false
        }

        do {
            try data.write(to: url, options: .atomic)
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.synchronize()
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
            return true
        } catch {
            return false
        }
    }

    private static func journalURL(createDirectory: Bool = false) -> URL? {
        let manager = FileManager.default
        guard let documents = try? manager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: createDirectory
        ) else {
            return nil
        }

        let folder = documents.appendingPathComponent(
            "EaglePrepareState",
            isDirectory: true
        )
        if createDirectory {
            try? manager.createDirectory(
                at: folder,
                withIntermediateDirectories: true,
                attributes: [
                    .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
                ]
            )
        }
        return folder.appendingPathComponent("last-attempt.json")
    }

    private static func bootIdentifier() -> String {
        var bootTime = timeval()
        var size = MemoryLayout<timeval>.size
        let result = withUnsafeMutablePointer(to: &bootTime) { pointer in
            sysctlbyname("kern.boottime", pointer, &size, nil, 0)
        }
        guard result == 0 else { return "unknown" }
        return "\(bootTime.tv_sec).\(bootTime.tv_usec)"
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
