import SwiftUI

struct OTAView: View {
    @ObservedObject var mgr: laramgr
    @AppStorage("lara.ota.disabled") private var otaDisabled: Bool = false
    @State private var isWorking: Bool = false
    @State private var lastResult: String? = nil

    var body: some View {
        List {
            Section(header: HeaderLabel(text: "Status", icon: "antenna.radiowaves.left.and.right")) {
                HStack {
                    Text("OTA Updates")
                    Spacer()
                    Text(otaDisabled ? "Disabled" : "Enabled")
                        .foregroundColor(otaDisabled ? .red : .green)
                        .monospaced()
                }
            }

            Section(
                header: HeaderLabel(text: "Actions", icon: "wrench.and.screwdriver"),
                footer: Text("Modifies launchd's disabled.plist via RemoteCall to prevent OTA update daemons from running. A reboot is required for changes to take effect.")
            ) {
                Button {
                    apply(disabled: true)
                } label: {
                    if isWorking && !otaDisabled {
                        HStack {
                            Text("Disabling…")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Disable OTA Updates")
                    }
                }
                .disabled(isWorking || otaDisabled)

                Button {
                    apply(disabled: false)
                } label: {
                    if isWorking && otaDisabled {
                        HStack {
                            Text("Enabling…")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Enable OTA Updates")
                    }
                }
                .disabled(isWorking || !otaDisabled)
            }
        }
        .navigationTitle("OTA Updates")
        .onAppear {
            if !otaDisabled {
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
                "com.apple.mobile.softwareupdated",
                "com.apple.OTATaskingAgent",
                "com.apple.softwareupdateservicesd",
                "com.apple.mobile.NRDUpdated",
            ]
            guard let data = NSData(contentsOfFile: plistPath) as Data?,
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                return
            }
            let allDisabled = daemonLabels.allSatisfy { (plist[$0] as? Bool) == true }
            if allDisabled {
                DispatchQueue.main.async {
                    otaDisabled = true
                }
            }
        }
    }

    private func apply(disabled: Bool) {
        isWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = ota_set_disabled(disabled)
            DispatchQueue.main.async {
                isWorking = false
                if ok {
                    otaDisabled = disabled
                    lastResult = disabled
                        ? "OTA updates disabled. Reboot to apply."
                        : "OTA updates enabled. Reboot to apply."
                } else {
                    lastResult = "Operation failed. Check logs for details."
                }
            }
        }
    }
}
