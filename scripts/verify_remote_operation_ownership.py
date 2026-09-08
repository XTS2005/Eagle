#!/usr/bin/env python3
"""Run the production operation gates with fake sessions; never touches a device."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "lara/classes/laramgr.swift").read_text()

def method(marker):
    start = source.index(marker)
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]

swift = r'''
import Foundation
final class RemoteCall {
    let pid = 42 // PID equality alone cannot distinguish replaced sessions.
    var destroyed = false
}
final class UIApplication {
    static let shared = UIApplication()
    enum State { case active, background }
    var applicationState = State.active
}
final class Manager {
    var fileopinprogress = false
    var storedSBProc: RemoteCall?
    var rcready = true
    var rcrunning = false
    var rcNativeCallInFlight = false
    var rcSafetyLocked = false
    var rcNativeCallLabel: String?
    var rcLastError: String?
    var validationCount = 0
    func logmsg(_ message: String) {}
    func remoteCallSessionIssue(_ session: RemoteCall, process: String) -> String? {
        precondition(!session.destroyed, "Touched destroyed native session")
        validationCount += 1
        return nil
    }
'''
swift += method("func beginExclusiveRemoteCall(") + "\n" + method("func endExclusiveRemoteCall(")
swift += r'''
}
// A resumed continuation must not acquire a different session after cleanup.
do {
    let manager = Manager(); let session = RemoteCall(); manager.storedSBProc = session
    manager.fileopinprogress = true
    precondition(!manager.beginExclusiveRemoteCall(label: "during-recipe", expectedSession: session))
    precondition(manager.validationCount == 0)
}
do {
    let manager = Manager()
    let old = RemoteCall(); old.destroyed = true
    let current = RemoteCall(); manager.storedSBProc = current
    precondition(!manager.beginExclusiveRemoteCall(label: "stale", expectedSession: old))
    precondition(manager.validationCount == 0 && !manager.rcNativeCallInFlight)
    precondition(manager.beginExclusiveRemoteCall(label: "current", expectedSession: current))
    manager.endExclusiveRemoteCall(label: "current")
}
// Late/duplicate completions cannot unlock the current owner or admit a rival.
for index in 0..<100 {
    let manager = Manager(); let session = RemoteCall(); manager.storedSBProc = session
    let owner = "apply-\(index)"
    precondition(manager.beginExclusiveRemoteCall(label: owner, expectedSession: session))
    for stale in ["previous", "restore", "download", "previous"] .shuffled() {
        manager.endExclusiveRemoteCall(label: stale)
        precondition(manager.rcNativeCallInFlight && manager.rcrunning)
        precondition(manager.rcNativeCallLabel == owner)
        precondition(!manager.beginExclusiveRemoteCall(label: "rival", expectedSession: session))
    }
    manager.endExclusiveRemoteCall(label: owner)
    precondition(!manager.rcNativeCallInFlight && !manager.rcrunning)
    precondition(manager.beginExclusiveRemoteCall(label: "next", expectedSession: session))
    manager.endExclusiveRemoteCall(label: owner)
    precondition(manager.rcNativeCallLabel == "next" && manager.rcNativeCallInFlight)
    manager.endExclusiveRemoteCall(label: "next")
    manager.endExclusiveRemoteCall(label: "next")
    precondition(!manager.rcNativeCallInFlight)
}
// Existing foreground, safety and readiness gates must remain intact.
do {
    let manager = Manager(); let session = RemoteCall(); manager.storedSBProc = session
    UIApplication.shared.applicationState = .background
    precondition(!manager.beginExclusiveRemoteCall(label: "background", expectedSession: session))
    UIApplication.shared.applicationState = .active
    manager.rcSafetyLocked = true
    precondition(!manager.beginExclusiveRemoteCall(label: "locked", expectedSession: session))
    manager.rcSafetyLocked = false; manager.rcready = false
    precondition(!manager.beginExclusiveRemoteCall(label: "not-ready", expectedSession: session))
    precondition(manager.validationCount == 0)
}
print("PASS: replaced sessions rejected before native access; 100 late-completion sequences preserve ownership; background and safety gates intact")
'''
with tempfile.TemporaryDirectory(prefix="eagle-ownership-qa-") as work:
    path = Path(work) / "main.swift"
    path.write_text(swift)
    executable = Path(work) / "verify"
    subprocess.run(["swiftc", "-swift-version", "5", str(path), "-o", str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
