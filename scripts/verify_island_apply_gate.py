#!/usr/bin/env python3
"""Exercise the real Island executor entry guards while fake work is suspended."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "lara/views/new/IslandGalleryView.swift").read_text()
start = source.index("    private func run(")
start = source.index(") async -> IslandGalleryApplyResult {", start)
start = source.index("{", start) + 1
guards = source[start:source.index("        let version =", start)]

swift = r'''
import Foundation
@MainActor final class UIApplication {
    static let shared = UIApplication()
    enum State { case active, background }
    var applicationState = State.active
}
@MainActor final class Executor {
    private var operationInProgress = false
    var started = 0
    var completion: CheckedContinuation<Void, Never>?
    func failure(en: String, es: String) -> Bool { false }
    func run() async -> Bool {
'''+guards+r'''
        started += 1
        await withCheckedContinuation { completion = $0 }
        return true
    }
    func finish() { completion?.resume(); completion = nil }
}
@main struct Tests {
    @MainActor static func main() async {
        let executor = Executor()
        let first = Task { await executor.run() }
        while executor.started == 0 { await Task.yield() }
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<40 { group.addTask { await executor.run() } }
            for await accepted in group { precondition(!accepted, "Duplicate apply entered") }
        }
        precondition(executor.started == 1)
        executor.finish()
        let firstSucceeded = await first.value
        precondition(firstSucceeded)

        UIApplication.shared.applicationState = .background
        let backgroundAccepted = await executor.run()
        precondition(!backgroundAccepted && executor.started == 1)
        UIApplication.shared.applicationState = .active
        let cancelled = Task { await executor.run() }
        cancelled.cancel()
        let cancelledAccepted = await cancelled.value
        precondition(!cancelledAccepted && executor.started == 1)

        let next = Task { await executor.run() }
        while executor.started < 2 { await Task.yield() }
        executor.finish()
        let nextSucceeded = await next.value
        precondition(nextSucceeded, "Lock leaked after completion or early rejection")
        print("PASS: 40 concurrent Island applies rejected; foreground/cancellation rejection and lock release verified")
    }
}
'''
with tempfile.TemporaryDirectory(prefix="eagle-island-entry-qa-") as work:
    path = Path(work) / "Tests.swift"
    path.write_text(swift)
    executable = Path(work) / "verify"
    subprocess.run(["swiftc", "-parse-as-library", "-swift-version", "5", str(path), "-o", str(executable)], check=True)
    subprocess.run([str(executable)], check=True, timeout=20)
