#!/usr/bin/env python3
"""Fault injection for production Collections passcode apply/restore methods."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "lara/views/styles/CompleteStylesView.swift").read_text().split("enum CompletePasscodeStyleEngine {", 1)[1]

def block(marker):
    start = source.index(marker)
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]

swift = r'''
import Foundation
enum LaraL10n { static func text(en: String, es: String) -> String { en } }
enum CompleteStyleEngineError: Error {
    case undoPreparationFailed(String), undoWriteFailed(String), passcodeUnavailable
    case passcodeVerificationFailed, passcodeTargetsIncomplete, incompletePasscode
    case passcodeWriteFailed(String), passcodeOriginalBackupFailed
}
struct CompleteStyleFileSnapshot { let path: String; let data: Data }
final class laramgr {
    static let shared = laramgr()
    var files: [String: Data] = [:]
    var failOnce: String?
    var dropWrites = false
    var writes = 0
    func logmsg(_ message: String) {}
    func lara_overwritefile(target: String, data: Data) -> (ok: Bool, message: String) {
        writes += 1
        if failOnce == target {
            failOnce = nil
            files[target] = Data("partial overwrite".utf8)
            return (false, "injected partial failure")
        }
        if !dropWrites { files[target] = data }
        return (true, "ok")
    }
}
enum Engine {
    static var targets: [String: [String]] = [:]
    static func basePath() -> String? { "/fake-cache" }
    static func targetPaths(in: String) -> [String: [String]] { targets }
    static func hasAllDigits(_ targets: [String: [String]]) -> Bool {
        (0...9).allSatisfy { !(targets[String($0)] ?? []).isEmpty }
    }
    static func read(_ path: String, maximumSize: Int) -> Data? { laramgr.shared.files[path] }
'''
swift += "\n".join(block(marker) for marker in [
    "static func restoreSnapshot(", "static func apply(", "private static func rollback(",
]) + "\n}\n"
swift += r'''
func mustThrow(_ action: () throws -> Void) {
    do { try action(); fatalError("Expected failure") } catch {}
}
let native = laramgr.shared
var original: [String: Data] = [:]
var images: [String: Data] = [:]
for digit in 0...9 {
    let path = "/fake-cache/other-2-\(digit)--dark.png"
    Engine.targets[String(digit)] = [path]
    original[path] = Data("original-\(digit)".utf8)
    images[String(digit)] = Data("theme-\(digit)".utf8)
}
let snapshots = original.map { CompleteStyleFileSnapshot(path: $0.key, data: $0.value) }
native.files = original
if let scenario = CommandLine.arguments.dropFirst().first {
    let path = Engine.targets["5"]!.first!
    let emptyOriginal = snapshots.map { CompleteStyleFileSnapshot(path: $0.path, data: $0.path == path ? Data() : $0.data) }
    switch scenario {
    case "empty-image":
        var invalid = images; invalid["5"] = Data()
        mustThrow { _ = try Engine.apply(images: invalid, rollbackFiles: snapshots) }
    case "empty-original":
        mustThrow { _ = try Engine.apply(images: images, rollbackFiles: emptyOriginal) }
    case "duplicate-original":
        mustThrow { _ = try Engine.apply(images: images, rollbackFiles: snapshots + [snapshots[0]]) }
    case "missing-original":
        mustThrow { _ = try Engine.apply(images: images, rollbackFiles: snapshots.filter { $0.path != path }) }
    case "empty-restore":
        mustThrow { _ = try Engine.restoreSnapshot(emptyOriginal) }
    default: fatalError("Unknown scenario")
    }
    precondition(native.writes == 0 && native.files == original, "Invalid input reached a native write")
    print("PASS: \(scenario) rejected before any write")
    exit(0)
}
let applied = try Engine.apply(images: images, rollbackFiles: snapshots)
precondition(applied == 10)
for digit in 0...9 { precondition(native.files[Engine.targets[String(digit)]!.first!] == images[String(digit)]) }
let restored = try Engine.restoreSnapshot(snapshots)
precondition(restored == 10 && native.files == original)
// Every attempted target, including a partially failed write, must be restored.
for digit in 0...9 {
    native.files = original
    native.failOnce = Engine.targets[String(digit)]!.first!
    mustThrow { _ = try Engine.apply(images: images, rollbackFiles: snapshots) }
    precondition(native.files == original, "Partial write escaped rollback at \(digit)")
}
let missingPath = Engine.targets["5"]!.first!
mustThrow { _ = try Engine.apply(images: images, rollbackFiles: snapshots.filter { $0.path != missingPath }) }
precondition(native.files == original)
let before = native.writes
mustThrow { _ = try Engine.apply(images: [:], rollbackFiles: snapshots) }
precondition(native.writes == before)
_ = try Engine.apply(images: images, rollbackFiles: snapshots)
native.dropWrites = true
mustThrow { _ = try Engine.restoreSnapshot(snapshots) }
native.dropWrites = false
_ = try Engine.restoreSnapshot(snapshots)
precondition(native.files == original)
print("PASS: Collections applies all digits; partial failures at each digit roll back; missing originals stop writes; Restore rejects silent failures")
'''
with tempfile.TemporaryDirectory(prefix="eagle-passcode-transaction-") as directory:
    directory = Path(directory)
    code = directory / "main.swift"
    code.write_text(swift)
    binary = directory / "verify"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", str(code), "-o", str(binary)], check=True)
    subprocess.run([str(binary), *sys.argv[1:]], check=True)
