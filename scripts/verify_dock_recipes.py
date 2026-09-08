#!/usr/bin/env python3
"""Exercise production recipe transformation/backup/transaction on real temp files."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
engine = (root / "lara/views/new/EagleDockRecipes.swift").read_text()
colors = (root / "lara/views/tweaks/sbcustomizer/SBCustomizerHandler.swift").read_text()
colors = colors[colors.index("class ColorSwapManager {"):colors.index("// MARK: i actually like this")]
swift = engine + '\nextension String: @retroactive Error {}\n' + colors + r'''
let fixtures = URL(fileURLWithPath: CommandLine.arguments[1])
let rootURL = URL(fileURLWithPath: CommandLine.arguments[2])
let fm = FileManager.default
func require(_ ok: @autoclosure () -> Bool, _ message: String) {
    if !ok() { print("FAIL: \(message)"); exit(1) }
}
func mustThrow(_ body: () throws -> Void) {
    do { try body(); fatalError("Expected rejection") } catch {}
}
let originals = try EagleDockRecipes.names.map { try Data(contentsOf: fixtures.appendingPathComponent($0)) }
for scenario in ["repeat", "legacy", "no-op", "partial", "rollback-failure", "corrupt-backup", "missing-original", "size-change", "cancel", "external", "identity"] {
    let folder = rootURL.appendingPathComponent(scenario)
    let files = folder.appendingPathComponent("system")
    let backups = folder.appendingPathComponent("backup")
    try fm.createDirectory(at: files, withIntermediateDirectories: true)
    for i in EagleDockRecipes.names.indices { try originals[i].write(to: files.appendingPathComponent(EagleDockRecipes.names[i])) }
    let engine = EagleDockRecipes(directory: files, backupDirectory: backups, identity: "device-build")
    var writes = 0
    var failAt = 0
    var failRecovery = false
    var noop = false
    let writer: (String, Data) -> Bool = { path, data in
        writes += 1
        if noop { return true }
        if writes == failAt || (failRecovery && writes > failAt) {
            try! Data(repeating: 0x41, count: data.count).write(to: URL(fileURLWithPath: path))
            return false
        }
        try! data.write(to: URL(fileURLWithPath: path)); return true
    }
    if scenario == "repeat" {
        for _ in 0..<12 {
            try engine.setHidden(true, write: writer)
            require(try! engine.state() == .hidden, "Hidden state comes from disk")
            let previous = writes
            try engine.setHidden(true, write: writer)
            require(writes == previous, "Repeated hide makes no redundant writes")
            let reopened = EagleDockRecipes(directory: files, backupDirectory: backups, identity: "device-build")
            require(try! reopened.state() == .hidden, "State survives reopening")
            try reopened.setHidden(false, write: writer)
            require(try! engine.current() == originals, "Restore preserves byte-exact originals")
        }
    } else if scenario == "legacy" {
        try fm.createDirectory(at: backups, withIntermediateDirectories: true)
        for i in EagleDockRecipes.names.indices {
            try originals[i].write(to: backups.appendingPathComponent(EagleDockRecipes.names[i]))
            try EagleDockRecipes.transparent(originals[i]).write(to: files.appendingPathComponent(EagleDockRecipes.names[i]))
        }
        try engine.setHidden(false, write: writer)
        require(try! engine.current() == originals, "Public release backup can restore")
    } else if scenario == "no-op" {
        noop = true
        mustThrow { try engine.setHidden(true, write: writer) }
        require(try! engine.current() == originals, "Silent write cannot announce success")
    } else if scenario == "partial" || scenario == "rollback-failure" {
        failAt = 2; failRecovery = scenario == "rollback-failure"
        mustThrow { try engine.setHidden(true, write: writer) }
        require(try! engine.load() != nil, "Backup survives failed write/recovery")
        if !failRecovery { require(try! engine.current() == originals, "Partial second write also rolls back") }
        failAt = 0; failRecovery = false
        try engine.setHidden(false, write: writer)
        require(try! engine.current() == originals, "Recovery can be retried")
    } else if scenario == "corrupt-backup" || scenario == "identity" {
        try engine.setHidden(true, write: writer)
        if scenario == "identity" {
            let bad = EagleDockRecipes.Snapshot(identity: "another-build", entries: try engine.load()!.entries)
            try PropertyListEncoder().encode(bad).write(to: engine.snapshotURL)
        } else { try Data("damaged".utf8).write(to: engine.snapshotURL) }
        let before = try engine.current(); let previous = writes
        mustThrow { try engine.setHidden(true, write: writer) }
        require(writes == previous && (try! engine.current()) == before, "Bad backup rejects before writes")
    } else if scenario == "missing-original" {
        for i in EagleDockRecipes.names.indices {
            try EagleDockRecipes.transparent(originals[i]).write(to: files.appendingPathComponent(EagleDockRecipes.names[i]))
        }
        mustThrow { try engine.setHidden(true, write: writer) }
        require(writes == 0, "Never save transparent bytes as original")
    } else if scenario == "size-change" {
        try engine.setHidden(true, write: writer)
        try Data(repeating: 0, count: 8).write(to: files.appendingPathComponent(EagleDockRecipes.names[0]))
        let previous = writes
        mustThrow { try engine.setHidden(false, write: writer) }
        require(writes == previous, "Size mismatch rejects before writing either file")
    } else if scenario == "cancel" {
        mustThrow { try engine.setHidden(true, shouldContinue: { writes == 0 }, write: writer) }
        require(try! engine.current() == originals, "Cancellation after first write restores it")
    } else {
        try engine.setHidden(true, write: writer)
        try Data(repeating: 0x41, count: originals[0].count).write(to: files.appendingPathComponent(EagleDockRecipes.names[0]))
        let previous = writes
        mustThrow { try engine.setHidden(true, write: writer) }
        require(writes == previous, "Unknown external bytes are not overwritten on hide")
        try engine.setHidden(false, write: writer)
        require(try! engine.current() == originals, "Restore repairs interrupted bytes using originals")
    }
    print("PASS: Dock recipes \(scenario)")
}
'''
with tempfile.TemporaryDirectory(prefix="eagle-recipes-qa-") as tmp:
    tmp = Path(tmp)
    code = tmp / "main.swift"
    code.write_text(swift)
    binary = tmp / "verify"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", str(code), "-o", str(binary)], check=True)
    subprocess.run([str(binary), str(root / "OverwriteFiles/SpringboardFiles/BackupFiles/Dock"), str(tmp)], check=True)
