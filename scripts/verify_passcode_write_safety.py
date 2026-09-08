#!/usr/bin/env python3
"""Exercise production passcode writes with real temporary files and injected I/O faults."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--case", default="all")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / "lara/views/tweaks/passcode/PasscodeView.swift").read_text()

def block(text, marker):
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]

swift = r'''
import Foundation
protocol ObservableObject {}
enum LaraL10n { static func text(en: String, es: String) -> String { en } }
let rootURL = URL(fileURLWithPath: CommandLine.arguments[1])
let passcodeBackupDir = rootURL.appendingPathComponent("backups")
let legacyPasscodeBackupDir = rootURL.appendingPathComponent("legacy")
final class laramgr {
    static let shared = laramgr()
    var faults: [String] = []
    var writes = 0
    func vfsread(path: String, maxSize: Int) -> Data? { try? Data(contentsOf: URL(fileURLWithPath: path)) }
    func lara_overwritefile(target: String, data: Data) -> (ok: Bool, message: String) {
        writes += 1
        let fault = faults.isEmpty ? "" : faults.removeFirst()
        if fault == "drop" { return (true, "silent no-op") }
        if fault == "fail" { return (false, "injected failure") }
        do {
            try (fault == "partial" ? Data("partial".utf8) : data).write(to: URL(fileURLWithPath: target))
            return (fault != "partial", "injected partial overwrite")
        } catch { return (false, error.localizedDescription) }
    }
}
'''
swift += block(source, "nonisolated enum PasscodeDigitFilename") + "\n"
swift += block(source, "final class PasscodeThemeManager").replace("@Published ", "")
swift += r'''
func require(_ ok: @autoclosure () -> Bool, _ message: String) {
    if !ok() { print("FAIL: \(message)"); exit(1) }
}
func mustThrow(_ action: () throws -> Void) {
    do { try action(); print("FAIL: write returned false success"); exit(1) } catch {}
}
let chosen = CommandLine.arguments[2]
let manager = PasscodeThemeManager.shared
let native = laramgr.shared
let fm = FileManager.default
for scenario in ["success", "empty", "drop", "partial", "rollback-failure"] where chosen == "all" || chosen == scenario {
    let target = rootURL.appendingPathComponent("other-2-5--dark-\(scenario).png")
    let original = Data("original digit".utf8)
    let current = Data("previous theme".utf8)
    let next = Data("next theme".utf8)
    try original.write(to: target)
    try manager.applyImage(data: current, to: target.path)
    require(manager.originalDataIfAvailable(targetPath: target.path) == original, "Original backup must precede the first theme")
    let before = native.writes
    if scenario == "success" {
        try manager.applyImage(data: next, to: target.path)
        require(try! Data(contentsOf: target) == next, "Successful retry writes selected bytes")
    } else if scenario == "empty" {
        mustThrow { try manager.applyImage(data: Data(), to: target.path) }
        require(native.writes == before, "Empty imported digit must not reach native write")
    } else {
        native.faults = scenario == "rollback-failure" ? ["partial", "fail"] : [scenario]
        mustThrow { try manager.applyImage(data: next, to: target.path) }
        if scenario != "rollback-failure" {
            require(try! Data(contentsOf: target) == current, "Failed apply must preserve the previous theme")
        }
    }
    require(manager.originalDataIfAvailable(targetPath: target.path) == original, "Original backup survives every failure")
    native.faults = []
    try manager.restoreBackup(targetPath: target.path)
    require(try! Data(contentsOf: target) == original, "Explicit recovery restores original bytes")
    print("PASS: \(scenario)")
}
'''
with tempfile.TemporaryDirectory(prefix="eagle-passcode-write-qa-") as directory:
    work = Path(directory)
    code = work / "main.swift"
    code.write_text(swift)
    executable = work / "verify"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", str(code), "-o", str(executable)], check=True)
    subprocess.run([str(executable), str(work), args.case], check=True)
