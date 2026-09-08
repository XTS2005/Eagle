#!/usr/bin/env python3
"""Exercise production digit matching and backup/restore with temporary files."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "lara/views/tweaks/passcode/PasscodeView.swift").read_text()

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
protocol ObservableObject {}
let rootURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let passcodeBackupDir = rootURL.appendingPathComponent("backups")
let legacyPasscodeBackupDir = rootURL.appendingPathComponent("legacy")
enum LaraL10n { static func text(en: String, es: String) -> String { en } }
final class laramgr {
    static let shared = laramgr()
    var failPath: String?
    var dropPath: String?
    var writes = 0
    func vfsread(path: String, maxSize: Int) -> Data? { nil }
    func lara_overwritefile(target: String, data: Data) -> (ok: Bool, message: String) {
        writes += 1
        if target == failPath { return (false, "injected write failure") }
        if target == dropPath { return (true, "silent no-op") }
        do { try data.write(to: URL(fileURLWithPath: target)); return (true, "ok") }
        catch { return (false, error.localizedDescription) }
    }
}
'''
swift += block("nonisolated enum PasscodeDigitFilename") + "\n"
swift += block("final class PasscodeThemeManager").replace("@Published ", "")
swift += r'''
func mustThrow(_ action: () throws -> Void) {
    do { try action(); fatalError("Expected an error, got false success") } catch {}
}
let fm = FileManager.default
let cache = rootURL.appendingPathComponent("TelephonyUI-15")
try fm.createDirectory(at: cache, withIntermediateDirectories: true)
let manager = PasscodeThemeManager.shared
let native = laramgr.shared
for digit in 0...9 {
    for path in ["\(digit).png", "theme/\(digit).JPG", "theme\\\(digit).jpeg",
                 "other-2-\(digit)--dark.png", "folder-1-/other-2-\(digit)--dark.png",
                 "key-\(digit)@3x.png", "key_\(digit)_dark.png"] {
        precondition(PasscodeDigitFilename.digit(in: path) == String(digit), path)
    }
    let target = cache.appendingPathComponent("other-2-\(digit)--dark.png")
    try Data("original-\(digit)".utf8).write(to: target)
    try manager.applyImage(data: Data("theme-\(digit)".utf8), to: target.path)
    precondition(try Data(contentsOf: target) == Data("theme-\(digit)".utf8))
}
precondition(PasscodeDigitFilename.digit(in: "folder-2-/preview.png") == nil)
precondition(PasscodeDigitFilename.digit(in: "10.png") == nil)
let unmodified = cache.appendingPathComponent("key-5@2x.png")
try Data("untouched".utf8).write(to: unmodified)
let failing = cache.appendingPathComponent("other-2-5--dark.png")
native.failPath = failing.path
mustThrow { try manager.restoreAll(basePath: cache.path) }
for digit in 0...9 where digit != 5 {
    precondition(try Data(contentsOf: cache.appendingPathComponent("other-2-\(digit)--dark.png")) == Data("original-\(digit)".utf8))
}
precondition(try Data(contentsOf: unmodified) == Data("untouched".utf8))
precondition(manager.hasBackup(targetPath: failing.path))
native.failPath = nil
try manager.restoreAll(basePath: cache.path)
precondition(try Data(contentsOf: failing) == Data("original-5".utf8))
try Data("still-themed".utf8).write(to: failing)
native.dropPath = failing.path
mustThrow { try manager.restoreAll(basePath: cache.path) }
precondition(manager.hasBackup(targetPath: failing.path))
native.dropPath = nil
try manager.restoreAll(basePath: cache.path)
// A corrupt existing backup must not authorize a destructive apply or a restore.
let badBackup = passcodeBackupDir.appendingPathComponent(failing.path.replacingOccurrences(of: "/", with: "_"))
try Data().write(to: badBackup)
let before = native.writes
mustThrow { try manager.applyImage(data: Data("replacement".utf8), to: failing.path) }
mustThrow { try manager.restoreBackup(targetPath: failing.path) }
precondition(native.writes == before)
let empty = rootURL.appendingPathComponent("empty-cache")
try fm.createDirectory(at: empty, withIntermediateDirectories: true)
mustThrow { try manager.restoreAll(basePath: empty.path) }
print("PASS: all 10 digits matched; failed restore reported and retry succeeds; originals retained; empty/corrupt backups cannot authorize writes")
'''
# Swift precondition autoclosures cannot throw.
swift = swift.replace("precondition(try Data(contentsOf:", "precondition(try! Data(contentsOf:")
with tempfile.TemporaryDirectory(prefix="eagle-passcode-qa-") as work:
    work = Path(work)
    code = work / "main.swift"
    code.write_text(swift)
    executable = work / "verify"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", str(code), "-o", str(executable)], check=True)
    subprocess.run([str(executable), str(work)], check=True)
