//
//  dirtyZeroView.swift
//  lara
//
//  Created by lunginspector on 5/14/26.
//

import SwiftUI

struct dirtyZeroView: View {
    @EnvironmentObject private var mgr: laramgr
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    @AppStorage("enableRiskyTweaks") var enableRiskyTweaks: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "Actions", icon: "wrench.and.screwdriver"), footer: Text("All tweaks are done in memory, so if something goes wrong, please reboot your device. Made with love by [jailbreak.party](https://jailbreak.party). This section of tweaks is also available as a [seperate app!](https://github.com/jailbreakdotparty/dirtyZero)")) {
                    Button("Apply Tweaks", action: {
                        applyTweaks()
                    })
                    Button("Respring", action: {
                        mgr.respring()
                    })
                    Toggle("Enable Risky Tweaks", isOn: $enableRiskyTweaks)
                }
                
                ListedTweaksSection
            }
            .navigationTitle("dirtyZero")
        }
    }
    
    private var ListedTweaksSection: some View {
        ForEach($tweakArray) { $section in
            if (section.name == "Risky Tweaks" && enableRiskyTweaks) || section.name != "Risky Tweaks" {
                Section(header: HeaderDropdown(text: section.name, icon: section.icon, isExpanded: $section.isExpanded, useItemCount: true, itemCount: section.tweaks.count)) {
                    if section.isExpanded {
                        ForEach($section.tweaks) { $tweak in
                            if (doubleSystemVersion() >= tweak.minSupportedVersion && doubleSystemVersion() <= tweak.maxSupportedVersion) || weonadebugbuild_pjbweouttahereexclamationmark {
                                PlainToggle(text: tweak.name, icon: tweak.icon, isOn: $tweak.isOn)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func applyTweaks() {
        guard mgr.vfsready else {
            Alertinator.shared.alert(title: "dirtyZero", body: "VFS is not ready.")
            return
        }

        let tweaks = tweakArray.flatMap { $0.tweaks }.filter { $0.isOn }
        guard !tweaks.isEmpty else {
            Alertinator.shared.alert(title: "dirtyZero", body: "No tweaks are selected.")
            return
        }

        var successCount = 0
        var failCount = 0
        
        for tweak in tweaks {
            for path in tweak.paths {
                if mgr.vfszeropage(at: path, dumb: true) {
                    successCount += 1
                } else {
                    failCount += 1
                }
            }
        }

        if failCount == 0 {
            Alertinator.shared.alert(title: "Tweaks applied", body: "Please respring your device to see any changes.", actionLabel: "Respring", action: {
                mgr.respring()
            })
        } else {
            Alertinator.shared.alert(title: "dirtyZero finished with errors", body: "\(successCount) write(s) succeeded and \(failCount) failed.")
        }
    }
}

// allows us to put arrays into AppStorage
extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
