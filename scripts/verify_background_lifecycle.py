#!/usr/bin/env python3
"""Exercise production lifecycle methods with a fake OS and transport on macOS.

No device, kernel access, or SpringBoard mutations are performed.
"""
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
source = (repo / "lara/classes/laramgr.swift").read_text()

def block(marker):
    start = source.index(marker)
    opening = source.index("{", start)
    end, depth = opening + 1, 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]

methods = "\n".join(block(marker) for marker in [
    "func remoteAppDidEnterBackground()", "func remoteAppDidBecomeActive()",
    "private func beginRemoteBackgroundTask()", "private func endRemoteBackgroundTask()",
    "private func finishRemoteWorkIfIdle()", "func rcdestroy(",
])
running = block("@Published var rcrunning:").replace("@Published ", "")
prefix = r'''
import Foundation
struct UIBackgroundTaskIdentifier: Equatable {
    let value: Int
    static let invalid = Self(value: -1)
}
final class UIApplication {
    static let shared = UIApplication()
    var serial = 0
    var handlers: [Int: () -> Void] = [:]
    func beginBackgroundTask(withName: String, expirationHandler: @escaping () -> Void) -> UIBackgroundTaskIdentifier {
        serial += 1; handlers[serial] = expirationHandler
        return UIBackgroundTaskIdentifier(value: serial)
    }
    func endBackgroundTask(_ task: UIBackgroundTaskIdentifier) {
        precondition(handlers.removeValue(forKey: task.value) != nil, "Duplicate task end")
    }
    func expire() { Array(handlers.values).forEach { $0() } }
}
final class RemoteCall {
    var result = 0
    let entered = DispatchSemaphore(value: 0)
    let proceed = DispatchSemaphore(value: 0)
    func destroy() -> Int { entered.signal(); proceed.wait(); return result }
}
final class Manager {
    var fileopinprogress = false
    var storedSBProc: RemoteCall?
    var sbProc: RemoteCall? { get { storedSBProc } set { storedSBProc = newValue } }
    var dsrunning = false
    var rcready = false
    var rcFreshSessionInFlight = false
    var rcNativeCallInFlight = false
    var rcDaemonRunning = false
    var rcSafetyLocked = false
    var rcLastError: String?
    var rcGeneration: UInt64 = 0
    private var remoteBackgroundTask = UIBackgroundTaskIdentifier.invalid
    private var remoteCleanupPending = false
    private var appIsBackgrounded = false
    func logmsg(_ message: String) {}
    func quarantineRemoteCall(reason: String) { rcSafetyLocked = true; rcLastError = reason }
'''
tests = r'''
}
func drain() { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
func check(_ value: @autoclosure () -> Bool, _ message: String) {
    precondition(value(), message)
}
func session(_ manager: Manager) -> RemoteCall {
    let remote = RemoteCall(); manager.storedSBProc = remote; manager.rcready = true
    return remote
}
// Going home while Apply is running must wait, then clean exactly once.
do {
    let m = Manager(); let remote = session(m)
    m.fileopinprogress = true
    m.remoteAppDidEnterBackground()
    check(remote.entered.wait(timeout: .now()) == .timedOut, "Dock recipe write must defer session teardown")
    m.fileopinprogress = false
    m.remoteAppDidBecomeActive()
    check(UIApplication.shared.handlers.isEmpty, "Recipe reservation ends after returning to foreground")
}
do {
    let m = Manager(); let remote = session(m)
    m.rcrunning = true; m.rcNativeCallInFlight = true
    m.remoteAppDidEnterBackground(); m.remoteAppDidEnterBackground()
    check(remote.entered.wait(timeout: .now()) == .timedOut, "Must not destroy an active operation")
    check(UIApplication.shared.handlers.count == 1, "Only one assertion for duplicate background events")
    m.rcNativeCallInFlight = false; m.rcrunning = false; drain()
    check(remote.entered.wait(timeout: .now() + 1) == .success, "Deferred cleanup must run")
    m.remoteAppDidEnterBackground()
    remote.proceed.signal(); drain()
    check(m.storedSBProc == nil && !m.rcrunning, "Cleanup clears transport and running state")
    check(UIApplication.shared.handlers.isEmpty, "Cleanup must release execution assertion")
    check(remote.entered.wait(timeout: .now()) == .timedOut, "Must not destroy twice")
}
// Returning before completion cancels pending background cleanup.
do {
    let m = Manager(); let remote = session(m)
    m.rcrunning = true; m.remoteAppDidEnterBackground(); m.remoteAppDidBecomeActive()
    m.rcrunning = false; drain()
    check(m.storedSBProc === remote, "Foreground return preserves usable session")
    check(remote.entered.wait(timeout: .now()) == .timedOut, "Foreground must not trigger teardown")
    check(UIApplication.shared.handlers.isEmpty, "Foreground idle releases assertion")
}
// Expiration locks further changes, but never destroys a live native call.
do {
    let m = Manager(); let remote = session(m)
    m.rcrunning = true; m.rcNativeCallInFlight = true; m.remoteAppDidEnterBackground()
    UIApplication.shared.expire()
    check(m.rcSafetyLocked, "Expired work must be quarantined")
    check(remote.entered.wait(timeout: .now()) == .timedOut, "Expiration cannot destroy in-flight work")
    m.rcNativeCallInFlight = false; m.rcrunning = false; drain()
    check(UIApplication.shared.handlers.isEmpty, "Expired assertion must end once")
}
// A failed teardown is never reported as success or made reusable.
do {
    let m = Manager(); let remote = session(m); remote.result = -1
    m.remoteAppDidEnterBackground()
    check(remote.entered.wait(timeout: .now() + 1) == .success, "Idle background cleanup starts")
    remote.proceed.signal(); drain()
    check(m.rcSafetyLocked && !m.rcready, "Failed cleanup must lock retries")
    check(UIApplication.shared.handlers.isEmpty, "Failed cleanup releases assertion")
}
// Preparation can finish after the background notification.
do {
    let m = Manager(); m.rcrunning = true; m.rcFreshSessionInFlight = true
    m.remoteAppDidEnterBackground()
    let remote = session(m); m.rcFreshSessionInFlight = false; m.rcrunning = false; drain()
    check(remote.entered.wait(timeout: .now() + 1) == .success, "Late preparation must also be cleaned")
    remote.proceed.signal(); drain()
    check(UIApplication.shared.handlers.isEmpty, "Late preparation leaves no assertion")
}
print("PASS: background Apply, foreground return, duplicate events, expiration, failed teardown, late preparation")
'''
with tempfile.TemporaryDirectory(prefix="eagle-lifecycle-qa-") as temp:
    swift = Path(temp) / "main.swift"
    swift.write_text(prefix + running + "\n" + methods + tests)
    binary = Path(temp) / "verify"
    subprocess.run(["swiftc", "-swift-version", "5", str(swift), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
