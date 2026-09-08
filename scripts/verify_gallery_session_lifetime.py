#!/usr/bin/env python3
"""Exercise production gallery preflight and ownership gates with fake sessions."""
from pathlib import Path
import argparse
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--baseline', type=Path)
args = parser.parse_args()
manager_source = (root / 'lara/classes/laramgr.swift').read_text()

def method(source, marker):
    start = source.index(marker)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]

common = r'''
import Foundation
final class RemoteCall {
    var destroyed = false
    var rawPID: Int32 = 42
    var isolated = true
    var reads = 0
    var pid: Int32 {
        precondition(!destroyed, "Read destroyed session before ownership")
        reads += 1; return rawPID
    }
    var creatingExtraThread: Bool {
        precondition(!destroyed, "Read destroyed session before ownership")
        reads += 1; return isolated
    }
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
    func logmsg(_ text: String) {}
    func remoteCallSessionIssue(_ session: RemoteCall, process: String) -> String? { nil }
'''
common += method(manager_source, 'func beginExclusiveRemoteCall(') + '\n'
common += method(manager_source, 'func endExclusiveRemoteCall(') + '\n}\n'
common += r'''
struct Target { var displayName = "Island" }
enum Status { case failed }
final class Executor {
    let manager = Manager()
    static func readSpringBoardPID() -> Int32 { 42 }
    func springBoardPID() -> Int32 { 42 }
    func failure(en: String, es: String) -> Bool { false }
    func result(_ component: Int, _ status: Status, en: String, es: String) -> Bool { false }
    func log(_ stage: String, _ id: String, _ target: Target, _ detail: String) {}
    func run(_ candidate: RemoteCall?) -> Bool {
        let preparation: (RemoteCall?, String?) = (candidate, nil)
        let operationID = "qa"
        let target = Target()
        let component = 1
'''
tests = r'''
        precondition(manager.rcNativeCallInFlight, "Native dispatch lacks ownership")
        return true
    }
}
@main struct Tests {
    @MainActor static func main() async {
        let executor = Executor(); let manager = executor.manager
        let candidate = RemoteCall(); manager.storedSBProc = candidate
        let old = RemoteCall(); old.destroyed = true
        precondition(!executor.run(old) && old.reads == 0)
        precondition(!executor.run(nil) && !manager.rcNativeCallInFlight)
        for _ in 0..<100 {
            precondition(executor.run(candidate))
            precondition(!manager.rcNativeCallInFlight && !manager.rcrunning)
        }
        candidate.rawPID = 43
        precondition(!executor.run(candidate) && !manager.rcNativeCallInFlight)
        candidate.rawPID = 0
        precondition(!executor.run(candidate) && !manager.rcNativeCallInFlight)
        candidate.rawPID = 42; candidate.isolated = false
        precondition(!executor.run(candidate) && !manager.rcNativeCallInFlight)
        candidate.isolated = true
        precondition(manager.beginExclusiveRemoteCall(label: "owner", expectedSession: candidate))
        let before = candidate.reads
        precondition(!executor.run(candidate) && candidate.reads == before)
        precondition(manager.rcNativeCallLabel == "owner")
        manager.endExclusiveRemoteCall(label: "owner")
        for state in [UIApplication.State.background, .active] {
            UIApplication.shared.applicationState = state
            manager.fileopinprogress = state == .active
            precondition(!executor.run(candidate) && candidate.reads == before)
            manager.fileopinprogress = false
        }
        let cancelled = Task { @MainActor in executor.run(candidate) }
        cancelled.cancel()
        let accepted = await cancelled.value
        precondition(!accepted && candidate.reads == before && !manager.rcNativeCallInFlight)
        precondition(executor.run(candidate))
        precondition(!manager.rcNativeCallInFlight)
        print("PASS: stale, nil, PID mismatch, missing helper, rival, background, file operation, cancellation and 100 repeated operations")
    }
}
'''
files = ['lara/views/new/IslandGalleryView.swift', 'lara/views/new/DockGalleryView.swift',
         'lara/classes/EagleSceneAuraExecutor.swift']
with tempfile.TemporaryDirectory(prefix='eagle-gallery-lifetime-') as temp:
    for file in files:
        path = args.baseline / Path(file).name if args.baseline else root / file
        source = path.read_text()
        start = source.index('        guard let process = preparation.0 else {')
        end = source.index('        let processBox =', start)
        guards = source[start:end]
        # Dock creates its ID in this block; other executors do so beforehand.
        prelude = common.replace('        let operationID = "qa"\n', '') if 'let operationID =' in guards else common
        if not args.baseline:
            assert guards.index('beginExclusiveRemoteCall') < guards.index('process.pid')
            assert 'defer { manager.endExclusiveRemoteCall(label: label) }' in guards
            assert source.count('manager.endExclusiveRemoteCall(label: label)') == 1
        swift = Path(temp) / 'Test.swift'
        swift.write_text(prelude + guards + tests)
        binary = Path(temp) / 'test'
        compiled = subprocess.run(['swiftc', '-swift-version', '5', '-parse-as-library', str(swift), '-o', str(binary)],
                                  capture_output=True, text=True)
        assert compiled.returncode == 0, compiled.stderr
        result = subprocess.run([str(binary)], capture_output=True, text=True)
        if args.baseline:
            assert result.returncode != 0 and 'Read destroyed session before ownership' in result.stderr
            print(f'REPRODUCED before fix: {Path(file).name} reads the destroyed session')
        else:
            assert result.returncode == 0, result.stderr
            print(Path(file).name + ': ' + result.stdout.strip())
