#!/usr/bin/env python3
"""Run the production Prepare orchestration with a suspended fake old session."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "lara/classes/laramgr.swift").read_text()

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
final class Events {
    static let shared = Events()
    private let lock = NSLock()
    private var values: [String] = []
    func append(_ event: String) { lock.lock(); defer { lock.unlock() }; values.append(event) }
    var all: [String] { lock.lock(); defer { lock.unlock() }; return values }
}
enum EaglePrepareAttemptJournal {
    enum Stage: String { case armed, darkSwordRunning, darkSwordReady }
    static func beginLatest(route: String, machine: String, systemBuild: String) -> String? { Events.shared.append("armed"); return "attempt" }
    static func mark(_ id: String?, stage: Stage, detail: String? = nil) { if id != nil { Events.shared.append(stage.rawValue) } }
    static func finish(_ id: String?, succeeded: Bool, detail: String? = nil) { if id != nil { Events.shared.append(succeeded ? "completed" : "failed") } }
}
struct Support { var allowsPrepare = true; var reason = Reason(); struct Reason { let rawValue = "supported" } }
enum Route: String { case stableLegacy, a18KernelStageLab }
func eagleSupportAssessment() -> Support { Support() }
func eagleSystemBuild() -> String? { "22F76" }
func devicemachine() -> String { "iPhone17,3" }
func eaglePrepareExecutionRoute(version: OperatingSystemVersion, machine: String, systemBuild: String?) -> Route { .stableLegacy }
final class Logger { func log(_ message: String) {}; func divider() {} }
let globallogger = Logger()
var kernelResult: Int32 = 0
var primitiveReady = true
func ds_run() -> Int32 { Events.shared.append("ds_run"); return kernelResult }
func ds_is_ready() -> Bool { primitiveReady }
func ds_get_our_proc() -> UInt64 { 1 }
func ds_get_our_task() -> UInt64 { 1 }
func ds_get_kernel_base() -> UInt64 { 1 }
func ds_get_kernel_slide() -> UInt64 { 1 }
func ds_set_log_callback(_ callback: @escaping (UnsafePointer<CChar>?) -> Void) {}
func ds_set_progress_callback(_ callback: @escaping (Double) -> Void) {}
final class RemoteCall {
    let entered = DispatchSemaphore(value: 0)
    let proceed = DispatchSemaphore(value: 0)
    var result = 0
    func destroy() -> Int {
        Events.shared.append("destroy.begin"); entered.signal(); proceed.wait()
        Events.shared.append("destroy.end"); return result
    }
}
final class laramgr {
    var fileopinprogress = false
    static let shared = laramgr()
    var dsrunning = false, rcrunning = false, rcFreshSessionInFlight = false
    var rcNativeCallInFlight = false, rcSafetyLocked = false
    var dsready = false, dsfailed = false, dsattempted = false
    var rcready = false, rcfailed = false
    var rcLastError: String?, rcSafetyReason: String?, rcNativeCallLabel: String?
    var dsprogress = 0.0
    var kernbase: UInt64 = 0, kernslide: UInt64 = 0, rcGeneration: UInt64 = 0
    var prepareAttemptID: String?
    var log = ""
    var storedSBProc: RemoteCall?
    var sbProc: RemoteCall? { get { storedSBProc }; set { storedSBProc = newValue } }
    func resetPreparedSubsystemStateForNewRun() {}
    func enqueueDSLog(_ message: String) {}
    func enqueueDSProgress(_ progress: Double) {}
    func logmsg(_ message: String) {}
    func quarantineRemoteCall(reason: String) { rcSafetyLocked = true; rcready = false }
'''.replace('get { storedSBProc }; set', 'get { storedSBProc } set')
swift += block("private func detachRemoteCallStateForPrepareStart()") + "\n"
swift += block("func run(completion:") + "\n}\n"
swift += r'''
func require(_ value: @autoclosure () -> Bool, _ message: String) {
    if !value() { print("FAIL: \(message) — \(Events.shared.all)"); exit(1) }
}
let scenario = CommandLine.arguments[1]
let manager = laramgr.shared
var completion: Bool?
let remote = RemoteCall()
if scenario != "no-session" { manager.storedSBProc = remote }
if scenario == "cleanup-failure" { remote.result = -1 }
if scenario == "kernel-failure" { kernelResult = -1 }
if scenario == "invalid-primitive" { primitiveReady = false }
manager.run { completion = $0 }
if scenario != "no-session" {
    require(remote.entered.wait(timeout: .now() + 2) == .success, "Old session cleanup must start")
    require(!Events.shared.all.contains("ds_run"), "Kernel entry must wait for cleanup")
    if scenario == "pending" {
        require(!Events.shared.all.contains("darkSwordRunning"), "Journal cannot claim DarkSword ran during pending cleanup")
    }
    var rival: Bool?
    manager.run { rival = $0 }
    require(rival == false && manager.dsrunning, "Concurrent Prepare rejected during cleanup")
    remote.proceed.signal()
}
let deadline = Date().addingTimeInterval(3)
while completion == nil && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
require(completion != nil && !manager.dsrunning, "Completion must leave no running flag")
let events = Events.shared.all
if scenario == "cleanup-failure" {
    require(completion == false && manager.rcSafetyLocked && manager.storedSBProc === remote, "Failed cleanup remains quarantined")
    require(!events.contains("ds_run"), "Failed cleanup never enters DarkSword")
    require(events.last == "failed" && !events.contains("darkSwordRunning"), "Failed cleanup must finish its journal without claiming kernel entry")
} else {
    require(events.filter { $0 == "ds_run" }.count == 1, "Exactly one kernel call")
    require(events.firstIndex(of: "darkSwordRunning")! < events.firstIndex(of: "ds_run")!, "Checkpoint immediately precedes kernel entry")
    if scenario != "no-session" { require(events.firstIndex(of: "destroy.end")! < events.firstIndex(of: "ds_run")!, "Cleanup ordering preserved") }
    let expected = scenario != "kernel-failure" && scenario != "invalid-primitive"
    require(completion == expected && manager.dsready == expected && manager.dsfailed != expected, "Kernel result and primitive verification both matter")
    require(events.last == (expected ? "darkSwordReady" : "failed"), "Journal matches actual result")
}
print("PASS: \(scenario)")
'''
with tempfile.TemporaryDirectory(prefix="eagle-prepare-cleanup-qa-") as directory:
    work = Path(directory)
    code = work / "main.swift"
    code.write_text(swift)
    binary = work / "verify"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", str(code), "-o", str(binary)], check=True)
    for scenario in sys.argv[1:] or ["no-session", "success", "pending", "cleanup-failure", "kernel-failure", "invalid-primitive"]:
        subprocess.run([str(binary), scenario], check=True)
