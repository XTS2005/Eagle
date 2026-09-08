#!/usr/bin/env python3
"""Verify production Collections backup persistence using isolated plist files."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--case", default="all")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / "lara/views/styles/CompleteStylesView.swift").read_text()

def block(text, marker):
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]

store = block(source, "private final class CompletePasscodeOriginalStore")
store = store.replace("private final class", "final class", 1)
store = store.replace(block(store, "private init()"), r'''init() { fileURL = rootURL.appendingPathComponent("originals.plist") }''')
swift = r'''
import Foundation
let rootURL = URL(fileURLWithPath: CommandLine.arguments[1])
struct CompleteStyleFileSnapshot: Codable, Equatable { let path: String; let data: Data }
enum CompleteStyleEngineError: Error { case passcodeOriginalBackupFailed }
'''
swift += store
swift += r'''
func require(_ ok: @autoclosure () -> Bool, _ message: String) {
    if !ok() { print("FAIL: \(message)"); exit(1) }
}
func mustThrow(_ action: () throws -> Void) {
    do { try action(); print("FAIL: invalid backup was accepted"); exit(1) } catch {}
}
let chosen = CommandLine.arguments[2]
let store = CompletePasscodeOriginalStore()
let fm = FileManager.default
let file = rootURL.appendingPathComponent("originals.plist")
let originals = (0...9).map { CompleteStyleFileSnapshot(path: "/cache/other-2-\($0)--dark.png", data: Data("original-\($0)".utf8)) }
let themed = originals.map { CompleteStyleFileSnapshot(path: $0.path, data: Data("themed".utf8)) }
let extra = CompleteStyleFileSnapshot(path: "/cache/key-5@3x.png", data: Data("new variant original".utf8))
for scenario in ["success", "added-target", "invalid-update", "corrupt-existing", "write-failure", "duplicate-input"] where chosen == "all" || chosen == scenario {
    try? fm.removeItem(at: file)
    try store.saveIfNeeded(originals)
    let saved = try Data(contentsOf: file)
    if scenario == "success" {
        try store.saveIfNeeded(themed)
        require(try! Data(contentsOf: file) == saved, "Same targets preserve existing originals")
    } else if scenario == "added-target" {
        try store.saveIfNeeded(themed + [extra])
        let loaded = store.load() ?? []
        require(originals.allSatisfy { loaded.contains($0) } && loaded.contains(extra), "Adding a cache variant must not replace original digits with themed bytes")
        try store.saveIfNeeded(themed)
        require(store.load()?.contains(extra) == true, "Temporarily absent cache variants keep their original backup")
    } else if scenario == "invalid-update" {
        mustThrow { try store.saveIfNeeded([]) }
        require(try! Data(contentsOf: file) == saved, "Invalid candidate must not delete the existing backup")
    } else if scenario == "corrupt-existing" {
        let corrupt = Data("damaged but must be preserved".utf8)
        try corrupt.write(to: file)
        mustThrow { try store.saveIfNeeded(themed) }
        require(try! Data(contentsOf: file) == corrupt, "Unreadable original must not be overwritten by a theme")
    } else if scenario == "write-failure" {
        try fm.setAttributes([.posixPermissions: 0o500], ofItemAtPath: rootURL.path)
        mustThrow { try store.saveIfNeeded(themed + [extra]) }
        try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: rootURL.path)
        require(try! Data(contentsOf: file) == saved, "Failed atomic update preserves previous backup bytes")
    } else {
        mustThrow { try store.saveIfNeeded(themed + [themed[0]]) }
        require(try! Data(contentsOf: file) == saved, "Duplicate targets rejected before altering backup")
    }
    print("PASS: \(scenario)")
}
'''
with tempfile.TemporaryDirectory(prefix="eagle-passcode-originals-qa-") as directory:
    work = Path(directory)
    code = work / "main.swift"
    code.write_text(swift)
    binary = work / "verify"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", str(code), "-o", str(binary)], check=True)
    subprocess.run([str(binary), str(work), args.case], check=True)
