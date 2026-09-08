#!/usr/bin/env python3
"""Run the actual VFS controller with failed, pending and successful preparation."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / "lara/views/new/HideDockIslandView.swift").read_text()
controller = source[source.index("private final class EagleDockRecipeWork"):
                    source.index("struct HideDockIslandView: View")].replace("@Published ", "")
stub = r'''
import Foundation
protocol ObservableObject {}
enum LaraL10n { static func text(en: String, es: String) -> String { en } }
func devicemachine() -> String { "iPhone17,1" }
func eagleSystemBuild() -> String? { "22G100" }
struct ProcessInfo {
    static let processInfo = ProcessInfo()
    let operatingSystemVersion = OperatingSystemVersion(majorVersion: 18, minorVersion: 6, patchVersion: 2)
}
extension URL { static var documents: URL { URL(fileURLWithPath: "/unused") } }
struct BackgroundID: Equatable { let value: Int; static let invalid = BackgroundID(value: -1) }
final class UIApplication {
    static let shared = UIApplication()
    enum State { case active, background }
    var applicationState = State.active
    var assertions = 0
    func beginBackgroundTask(withName: String, expirationHandler: @escaping () -> Void) -> BackgroundID {
        assertions += 1; return BackgroundID(value: 1)
    }
    func endBackgroundTask(_ id: BackgroundID) { assertions -= 1 }
}
final class Logger { func log(_ value: String) {}; func flushToDisk() {} }
let globallogger = Logger()
struct EagleDockRecipes {
    static let systemDirectory = URL(fileURLWithPath: "/unused")
    enum State { case original, hidden, mixed }
    static var diskState = State.original
    let directory: URL, backupDirectory: URL, identity: String
    func state() throws -> State { Self.diskState }
    func setHidden(_ hidden: Bool, shouldContinue: () -> Bool, write: (String, Data) -> Bool) throws {
        guard shouldContinue(), write("/test/dock", Data([1])) else {
            throw NSError(domain: "test", code: 1)
        }
        Self.diskState = hidden ? .hidden : .original
    }
}
final class laramgr: @unchecked Sendable {
    static let shared = laramgr()
    var dsready = true, hasOffsets = true, vfsready = true
    var fileopinprogress = false, dsrunning = false, rcrunning = false, vfsrunning = false, sbxrunning = false
    var initSucceeds = true, writeSucceeds = true
    var preparations = 0, writes = 0
    var onPrepare: (() -> Void)?
    func vfsinit(completion: (Bool) -> Void) {
        preparations += 1; onPrepare?(); vfsready = initSucceeds; completion(initSucceeds)
    }
    func vfsoverwritewithdata(target: String, data: Data) -> Bool {
        precondition(fileopinprogress); writes += 1; return writeSucceeds
    }
}
'''
tests = r'''
@main struct Check {
    @MainActor static func main() async {
        let mgr = laramgr.shared, app = UIApplication.shared
        let controller = EagleDockBackgroundController.shared
        let scenario = CommandLine.arguments[1]
        switch scenario {
        case "fresh": mgr.vfsready = false
        case "init-failed": mgr.vfsready = false; mgr.initSucceeds = false
        case "write-failed": mgr.writeSucceeds = false
        case "background": app.applicationState = .background
        case "cancel-prepare":
            mgr.vfsready = false
            mgr.onPrepare = { app.applicationState = .background }
        case "busy": mgr.rcrunning = true
        default: break
        }
        let result = await controller.setHidden(true)
        let success = ["fresh", "repeat"].contains(scenario)
        precondition(result.succeeded == success && result.offersRespring == success)
        precondition(!mgr.fileopinprogress && app.assertions == 0)
        if success {
            precondition(controller.hidden && mgr.writes == 1)
            let restored = await controller.setHidden(false)
            precondition(restored.succeeded && !controller.hidden)
            precondition(mgr.preparations == (scenario == "fresh" ? 1 : 0))
        } else if scenario != "write-failed" { precondition(mgr.writes == 0) }
        print("PASS: recipe controller \(scenario)")
    }
}
'''
with tempfile.TemporaryDirectory(prefix="eagle-recipe-controller-") as tmp:
    tmp = Path(tmp)
    code = tmp / "check.swift"
    code.write_text(stub + controller + tests)
    binary = tmp / "check"
    subprocess.run(["swiftc", "-swift-version", "5", "-parse-as-library", str(code), "-o", str(binary)], check=True)
    for scenario in ["fresh", "repeat", "init-failed", "write-failed", "background", "cancel-prepare", "busy"]:
        subprocess.run([str(binary), scenario], check=True)
