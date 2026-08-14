import SwiftUI

struct ScreenTimeView: View {
    @ObservedObject var mgr: laramgr
    @AppStorage("lara.screentime.disabled") private var screenTimeDisabled: Bool = false
    @State private var killScreenTimeAgent: Bool = true
    @State private var killUsageTrackingAgent: Bool = true
    @State private var killHomed: Bool = false
    @State private var killFamilycircled: Bool = false
    @State private var isWorking: Bool = false
    @State private var lastResult: String? = nil

    private var backupExists: Bool {
        FileManager.default.fileExists(atPath: "/var/mobile/Library/Preferences/com.apple.ScreenTimeAgent.plist.bak")
    }

    var body: some View {
        List {
            Section(header: HeaderLabel(text: "Status", icon: "hourglass")) {
                HStack {
                    Text("Screen Time")
                    Spacer()
                    Text(screenTimeDisabled ? "Disabled" : "Enabled")
                        .foregroundColor(screenTimeDisabled ? .red : .green)
                        .monospaced()
                }
                HStack {
                    Text("Preferences backup")
                    Spacer()
                    Text(backupExists ? "Found" : "Not found")
                        .foregroundColor(backupExists ? .green : .secondary)
                        .monospaced()
                }
            }

            Section(
                header: HeaderLabel(text: "Daemons", icon: "gearshape.2"),
                footer: Text("Select which daemons to disable. ScreenTimeAgent and UsageTrackingAgent are the minimum required to fully disable Screen Time.")
            ) {
                Toggle("ScreenTimeAgent", isOn: $killScreenTimeAgent)
                    .disabled(isWorking || screenTimeDisabled)
                Toggle("UsageTrackingAgent", isOn: $killUsageTrackingAgent)
                    .disabled(isWorking || screenTimeDisabled)
                Toggle("Homed", isOn: $killHomed)
                    .disabled(isWorking || screenTimeDisabled)
                Toggle("Familycircled", isOn: $killFamilycircled)
                    .disabled(isWorking || screenTimeDisabled)
            }

            Section(
                header: HeaderLabel(text: "Actions", icon: "wrench.and.screwdriver"),
                footer: Text("Kills selected daemons, removes Screen Time preferences, and marks them as disabled in launchd's disabled.plist. A reboot is required for changes to take effect.")
            ) {
                Button {
                    applyDisable()
                } label: {
                    if isWorking && !screenTimeDisabled {
                        HStack {
                            Text("Disabling…")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Disable Screen Time")
                    }
                }
                .disabled(isWorking || screenTimeDisabled)

                Button {
                    applyEnable()
                } label: {
                    if isWorking && screenTimeDisabled {
                        HStack {
                            Text("Enabling…")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Enable Screen Time")
                    }
                }
                .disabled(isWorking || !screenTimeDisabled)
            }
        }
        .navigationTitle("Screen Time")
        .onAppear {
            if !screenTimeDisabled {
                syncStateFromPlist()
            }
        }
        .alert("Result", isPresented: .constant(lastResult != nil)) {
            Button("OK") { lastResult = nil }
        } message: {
            Text(lastResult ?? "")
        }
    }

    private func syncStateFromPlist() {
        DispatchQueue.global(qos: .userInitiated).async {
            let plistPath = "/private/var/db/com.apple.xpc.launchd/disabled.plist"
            let daemonLabels = [
                "com.apple.ScreenTimeAgent",
                "com.apple.UsageTrackingAgent",
            ]
            guard let data = NSData(contentsOfFile: plistPath) as Data?,
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                return
            }
            let allDisabled = daemonLabels.allSatisfy { (plist[$0] as? Bool) == true }
            if allDisabled {
                DispatchQueue.main.async {
                    screenTimeDisabled = true
                }
            }
        }
    }

    private func applyDisable() {
        isWorking = true
        let agent = killScreenTimeAgent
        let usage = killUsageTrackingAgent
        let homed = killHomed
        let family = killFamilycircled
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = screentime_disable(agent, usage, homed, family)
            DispatchQueue.main.async {
                isWorking = false
                if ok {
                    screenTimeDisabled = true
                    lastResult = "Screen Time disabled. Reboot to apply."
                } else {
                    lastResult = "Operation failed. Check logs for details."
                }
            }
        }
    }

    private func applyEnable() {
        isWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = screentime_enable()
            DispatchQueue.main.async {
                isWorking = false
                if ok {
                    screenTimeDisabled = false
                    lastResult = "Screen Time enabled. Reboot to apply."
                } else {
                    lastResult = "Operation failed. Check logs for details."
                }
            }
        }
    }
}
