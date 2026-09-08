#!/usr/bin/env python3
"""Exercise the actual Dock action and shared gate with a suspended fake native call."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
dock = (root / "lara/views/new/DockCustomizerView.swift").read_text()
manager = (root / "lara/classes/laramgr.swift").read_text()

def block(source, marker):
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
struct EagleDockAlert { let message: String }
final class UIApplication {
    static let shared = UIApplication()
    enum State { case active, background }
    var applicationState = State.active
}
final class RemoteCall {
    var isHealthy = true
    var lastCallTimedOut = false
    let started = DispatchSemaphore(value: 0)
    let proceed = DispatchSemaphore(value: 0)
    var result: Int32 = 0
    var requested = 0
}
func set_dock_icon_count(_ process: RemoteCall, _ count: Int32) -> Int32 {
    process.requested = Int(count)
    process.started.signal()
    precondition(process.proceed.wait(timeout: .now() + 5) == .success)
    return process.result
}
final class Manager {
    var fileopinprogress = false
    var dsrunning = false
    var dsready = true
    var rcrunning = false
    var rcready = true
    var rcNativeCallInFlight = false
    var rcSafetyLocked = false
    var rcNativeCallLabel: String?
    var rcLastError: String?
    var storedSBProc: RemoteCall? = RemoteCall()
    var sbProc: RemoteCall? { storedSBProc }
    func logmsg(_ message: String) {}
    func remoteCallSessionIssue(_ session: RemoteCall, process: String) -> String? { nil }
    func quarantineRemoteCall(reason: String) { rcSafetyLocked = true; rcLastError = reason }
    func rcinit(process: String, completion: (Bool) -> Void) { rcready = true; completion(false) }
'''
swift += block(manager, "func beginExclusiveRemoteCall(") + "\n"
swift += block(manager, "func endExclusiveRemoteCall(") + "\n}\n"
swift += r'''
final class Dock {
    let mgr: Manager
    init(_ mgr: Manager) { self.mgr = mgr }
    var isApplying = false
    var selectedCapacity = 5
    let capacities = [4,5,6]
    var alert: EagleDockAlert?
    func message(forResult: Int32) -> String { "Native failure" }
'''
swift += block(dock, "private func applySelectedCapacity()").replace("private func", "func", 1) + "\n"
swift += block(dock, "private func finishWithError(") + "\n}\n"
swift += r'''
func drain(_ done: () -> Bool) {
    let deadline = Date().addingTimeInterval(5)
    while !done() && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
    precondition(done(), "Action did not finish")
}
for unhealthy in [false, true] {
    let mgr = Manager(), view: Dock
    view = Dock(mgr)
    let process = mgr.sbProc!
    view.applySelectedCapacity()
    precondition(process.started.wait(timeout: .now() + 3) == .success)
    precondition(mgr.rcNativeCallInFlight && mgr.rcrunning)
    let second = Dock(mgr)
    second.applySelectedCapacity()
    precondition(!second.isApplying)
    precondition(!mgr.beginExclusiveRemoteCall(label: "theme", expectedSession: process))
    if unhealthy { process.lastCallTimedOut = true }
    process.proceed.signal()
    drain { !view.isApplying }
    precondition(!mgr.rcNativeCallInFlight && !mgr.rcrunning)
    precondition(mgr.rcSafetyLocked == unhealthy)
    precondition(view.alert!.message.contains(unhealthy ? "could not be verified" : "now accepts 5"))
}
for invalid in [Int.min, 0, 50, Int.max] {
    let mgr = Manager(), view: Dock
    view = Dock(mgr); view.selectedCapacity = invalid
    view.applySelectedCapacity()
    drain { view.alert != nil }
    precondition(!mgr.rcNativeCallInFlight && mgr.sbProc!.requested == 0)
}
do {
    let mgr = Manager(), view: Dock
    view = Dock(mgr); mgr.rcready = false
    view.applySelectedCapacity() // failed initialization must not use an incidental ready session
    drain { !view.isApplying }
    precondition(mgr.sbProc!.requested == 0)
    UIApplication.shared.applicationState = .background
    view.applySelectedCapacity()
    precondition(!view.isApplying && !mgr.rcNativeCallInFlight)
}
print("PASS: Dock owns session through completion; competing themes rejected; timeout cannot report success; invalid capacities/background/failed init send nothing")
'''
with tempfile.TemporaryDirectory(prefix="eagle-dock-operation-") as directory:
    directory = Path(directory)
    code = directory / "main.swift"
    code.write_text(swift)
    binary = directory / "verify"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", str(code), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
