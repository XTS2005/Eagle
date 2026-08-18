//
//  TweaksView.swift
//  lara
//
//  Created by lunginspector on 5/3/26.
//

import SwiftUI

struct TweaksView: View {
    @AppStorage("logsdisplaymode") private var selectedlogsdisplaymode: logsdisplaymode = .toolbar
    @ObservedObject var mgr: laramgr
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "SpringBoard", icon: "house")) {
                    if LaraCustomProfile.includes(.remoteCallCustomizer) {
                        NavigationLink("RemoteCall Customizer", destination: RemoteView(mgr: mgr))
                            .disabled(!mgr.rcready)
                    }
                    if LaraCustomProfile.includes(.liquidGlass) {
                        NavigationLink("Liquid Glass", destination: LiquidGlassView())
                            .disabled(!mgr.vfsready)
                    }
                    if LaraCustomProfile.includes(.springBoardCustomizer) {
                        NavigationLink("SpringBoard Customizer", destination: SpringBoardView(mgr: mgr))
                            .disabled(!mgr.vfsready)
                    }
                }
                
                Section(header: HeaderLabel(text: "Lock Screen", icon: "lock")) {
                    if LaraCustomProfile.includes(.passcodeTheme) {
                        NavigationLink("Passcode Theme", destination: PasscodeView(mgr: mgr))
                            .disabled(!mgr.sbxready)
                    }
                }
                
                Section(header: HeaderLabel(text: "Apps", icon: "app")) {
                    if LaraCustomProfile.includes(.cardOverwrite) {
                        NavigationLink("Card Overwrite", destination: CardView())
                            .disabled(!mgr.vfsready)
                    }
                    if LaraCustomProfile.includes(.appDecrypt) {
                        NavigationLink("App Decrypt", destination: DecryptView())
                            .disabled(!mgr.sbxready)
                    }
                    if LaraCustomProfile.includes(.threeAppBypass) {
                        NavigationLink("3 App Bypass", destination: AppsView())
                            .disabled(!mgr.sbxready)
                    }
                    if LaraCustomProfile.includes(.unblacklist) {
                        NavigationLink("Unblacklist", destination: WhitelistView())
                            .disabled(!mgr.sbxready)
                    }
                    if LaraCustomProfile.includes(.jitEnabler) {
                        NavigationLink("JIT Enabler", destination: JitView())
                            .disabled(!mgr.sbxready)
                    }
                }
                
                Section(header: HeaderLabel(text: "User Interface", icon: "eye")) {
                    if LaraCustomProfile.includes(.dirtyZero) {
                        NavigationLink("dirtyZero", destination: dirtyZeroView())
                            .disabled(!mgr.vfsready)
                    }
                    if LaraCustomProfile.includes(.showHiddenIcons) {
                        NavigationLink("Show Hidden Icons", destination: ShowHiddenIconsView(mgr: mgr))
                            .disabled(!mgr.sbxready && !mgr.vfsready)
                    }
                    if LaraCustomProfile.includes(.mobileGestalt) {
                        NavigationLink("MobileGestalt", destination: GestaltView(mgr: mgr))
                            .disabled(!mgr.sbxready)
                    }
                    if LaraCustomProfile.includes(.fontOverwrite) {
                        NavigationLink("Font Overwrite", destination: FontPicker(mgr: mgr))
                            .disabled(!mgr.vfsready)
                    }
                    if LaraCustomProfile.includes(.systemColorPatcher) {
                        NavigationLink("SystemColor Patcher", destination: SystemColor(mgr: mgr))
                            .disabled(!mgr.sbxready || !mgr.vfsready)
                    }
                }
                
                Section(header: HeaderLabel(text: "System", icon: "gear")) {
                    if LaraCustomProfile.includes(.varClean) {
                        NavigationLink("VarClean", destination: VarCleanView())
                            .disabled(!mgr.sbxready)
                    }
                    if LaraCustomProfile.includes(.customOverwrite) {
                        NavigationLink("Custom Overwrite", destination: CustomView(mgr: mgr))
                            .disabled(!mgr.vfsready)
                    }
                    if LaraCustomProfile.includes(.otaUpdates) {
                        NavigationLink(
                            LaraL10n.text(en: "OTA Updates", es: "Actualizaciones OTA"),
                            destination: OTAView(mgr: mgr)
                        )
                    }
                    if LaraCustomProfile.includes(.screenTime) {
                        NavigationLink(
                            LaraL10n.text(en: "Screen Time", es: "Tiempo en Pantalla"),
                            destination: ScreenTimeView(mgr: mgr)
                        )
                    }
                }
                
                if LaraCustomProfile.includes(.extraTools) {
                    NavigationLink("Extra Tools", destination: ToolsView())
                }
            }
            .disabled(!mgr.dsready)
            .navigationTitle("Tweaks")
            .toolbar {
                if selectedlogsdisplaymode == .toolbar {
                    Button(action: {
                        mgr.showLogs.toggle()
                    }) {
                        Image(systemName: "terminal")
                    }
                }
            }
        }
    }
}
