import Foundation
import CoreImage

/// Same material-recipe transformation as the public release, with durable
/// originals and verified, reversible writes. No SpringBoard RemoteCall.
nonisolated struct EagleDockRecipes {
    static let names = ["dockDark.materialrecipe", "dockLight.materialrecipe"]
    static let systemDirectory = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/CoreMaterial.framework")
    struct Entry: Codable { let name: String; let original: Data; let transparent: Data }
    struct Snapshot: Codable { let identity: String; let entries: [Entry] }
    enum State { case original, hidden, mixed }
    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
    let directory: URL
    let backupDirectory: URL
    let identity: String
    var snapshotURL: URL { backupDirectory.appendingPathComponent("v2-\(identity).plist") }

    static func fail(_ message: String) -> Failure { Failure(message: message) }
    static func read(_ url: URL) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 1024 * 1024 + 1) ?? Data()
        guard !data.isEmpty, data.count <= 1024 * 1024 else {
            throw fail("Empty or oversized Dock file: \(url.lastPathComponent)")
        }
        return data
    }
    static func plist(_ data: Data) throws -> [String: Any] {
        guard let value = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              value["baseMaterial"] is [String: Any] else {
            throw fail("Invalid Dock material recipe")
        }
        return value
    }
    static func transparent(_ original: Data) throws -> Data {
        let value = try plist(original)
        let updated = ColorSwapManager.setColor(list: value, color: CIColor(red: 0, green: 0, blue: 0, alpha: 0), blur: 0)
        let output = try addEmptyData(matchingSize: original.count, to: updated)
        guard output.count == original.count else { throw fail("Dock recipe size mismatch") }
        _ = try plist(output)
        return output
    }
    static func equivalent(_ lhs: Data, _ rhs: Data) throws -> Bool {
        var a = try plist(lhs), b = try plist(rhs)
        a.removeValue(forKey: "MdC"); b.removeValue(forKey: "MdC")
        return NSDictionary(dictionary: a).isEqual(to: b)
    }
    func load() throws -> Snapshot? {
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else { return nil }
        let snapshot = try PropertyListDecoder().decode(Snapshot.self, from: Self.read(snapshotURL))
        guard snapshot.identity == identity, snapshot.entries.map(\.name) == Self.names else {
            throw Self.fail("Dock backup does not match this device/build")
        }
        for entry in snapshot.entries {
            _ = try Self.plist(entry.original); _ = try Self.plist(entry.transparent)
            guard !entry.original.isEmpty, entry.original.count == entry.transparent.count,
                  try Self.equivalent(Self.transparent(entry.original), entry.transparent),
                  try !Self.equivalent(entry.original, entry.transparent) else {
                throw Self.fail("Invalid original Dock backup")
            }
        }
        return snapshot
    }
    func current() throws -> [Data] { try Self.names.map { try Self.read(directory.appendingPathComponent($0)) } }
    func state() throws -> State {
        let bytes = try current()
        guard let snapshot = try load() else {
            for data in bytes {
                if try Self.equivalent(data, Self.transparent(data)) { return .mixed }
            }
            return .original
        }
        if zip(bytes, snapshot.entries).allSatisfy({ $0.0 == $0.1.transparent }) { return .hidden }
        if zip(bytes, snapshot.entries).allSatisfy({ $0.0 == $0.1.original }) { return .original }
        return .mixed
    }
    func prepareSnapshot(current bytes: [Data]) throws -> Snapshot {
        if let snapshot = try load() { return snapshot }
        var entries: [Entry] = []
        for (index, name) in Self.names.enumerated() {
            let legacy = backupDirectory.appendingPathComponent(name)
            let original: Data
            if FileManager.default.fileExists(atPath: legacy.path) {
                let saved = try Self.read(legacy)
                let hidden = try Self.transparent(saved)
                guard saved.count == bytes[index].count,
                      try Self.equivalent(bytes[index], saved) || Self.equivalent(bytes[index], hidden) else {
                    throw Self.fail("Legacy Dock backup cannot be verified for this system. Original preserved.")
                }
                original = saved
            } else { original = bytes[index] }
            let hidden = try Self.transparent(original)
            guard try !Self.equivalent(original, hidden) else {
                throw Self.fail("Original Dock backup is missing; current file is already transparent")
            }
            entries.append(Entry(name: name, original: original, transparent: hidden))
        }
        let snapshot = Snapshot(identity: identity, entries: entries)
        let encoder = PropertyListEncoder(); encoder.outputFormat = .binary
        let data = try encoder.encode(snapshot)
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        try data.write(to: snapshotURL, options: .atomic)
        let handle = try FileHandle(forWritingTo: snapshotURL)
        defer { try? handle.close() }
        try handle.synchronize()
        guard try Self.read(snapshotURL) == data else { throw Self.fail("Dock backup persistence failed") }
        return snapshot
    }

    /// Only these two fixed targets can reach the supplied VFS writer. Backups
    /// and replacements are all validated before the first protected write.
    func setHidden(_ hidden: Bool, shouldContinue: () -> Bool = { true },
                   write: (String, Data) -> Bool) throws {
        let before = try current()
        if !hidden, try load() == nil,
           !Self.names.contains(where: { FileManager.default.fileExists(atPath: backupDirectory.appendingPathComponent($0).path) }),
           try state() == .original { return }
        let snapshot = try prepareSnapshot(current: before)
        let desired = snapshot.entries.map { hidden ? $0.transparent : $0.original }
        for i in Self.names.indices {
            guard before[i].count == desired[i].count else { throw Self.fail("Dock file size changed; backup preserved") }
            if hidden, before[i] != snapshot.entries[i].original && before[i] != snapshot.entries[i].transparent {
                throw Self.fail("Dock files changed outside this operation. Restore the originals first.")
            }
        }
        var attempted: [Int] = []
        do {
            for i in Self.names.indices {
                guard shouldContinue() else { throw Self.fail("Dock update interrupted") }
                let path = directory.appendingPathComponent(Self.names[i])
                guard try Self.read(path) == before[i] else { throw Self.fail("Dock changed before writing") }
                if before[i] == desired[i] { continue }
                attempted.append(i) // A failed write may already have changed bytes.
                guard write(path.path, desired[i]), try Self.read(path) == desired[i] else {
                    throw Self.fail("Dock write could not be verified")
                }
            }
            guard try current() == desired else { throw Self.fail("Final Dock verification failed") }
        } catch {
            var recovered = true
            for i in attempted.reversed() {
                let path = directory.appendingPathComponent(Self.names[i])
                let sent = write(path.path, before[i])
                recovered = sent && (try? Self.read(path)) == before[i] && recovered
            }
            if !recovered { throw Self.fail("Dock recovery was incomplete. Original backups are preserved; use Restore Dock.") }
            throw error
        }
    }
}
