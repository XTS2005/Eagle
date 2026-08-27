//
//  lara.swift
//  lara
//
//  Created by ruter on 23.03.26.
//

import SwiftUI
import UniformTypeIdentifiers

let g_isunsupported: Bool = isunsupported()
var weonadebugbuild_pjbweouttahereexclamationmark: Bool = false

@main
struct LaraCustomApp: App {
    @StateObject private var mgr = laramgr.shared
    @Environment(\.scenePhase) var scenephase
    @AppStorage("keepAlive") private var keepalive: Bool = false
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english
    @AppStorage(EagleAppearanceMode.storageKey)
    private var appearanceModeRaw = EagleAppearanceMode.dark.rawValue
    @AppStorage("eagle.updates.stable1.completed")
    private var hasSeenStableUpdate = false
    @State private var showingStableUpdate = false

    private var preferredColorScheme: ColorScheme? {
        (EagleAppearanceMode(rawValue: appearanceModeRaw) ?? .dark).preferredColorScheme
    }
    
    init() {
        EaglePreferenceMigration.runIfNeeded()
        EagleSpectrumStyle.configureGlobalNavigationAppearance()

        #if DEBUG
        weonadebugbuild_pjbweouttahereexclamationmark = true
        #endif
        
        // fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
        
        if keepalive {
            toggleka()
        }

        globallogger.capture()
    }
    
    var body: some Scene {
        WindowGroup {
            EagleAppShellView()
            .environmentObject(mgr)
            .environment(\.locale, language.locale)
            .preferredColorScheme(preferredColorScheme)
            .overlay {
                if mgr.showrespring {
                    respringview()
                        .brightness(-1.0)
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                if !hasSeenStableUpdate {
                    showingStableUpdate = true
                }
                if !isunsupported() {
                    init_offsets()
                    offsets_init()
                    mgr.hasOffsets = emergencyfixfunctiontobereplacedlateronquestionmark()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    EagleSceneManager.shared.applyPendingShortcutIfNeeded()
                }
            }
            .onChange(of: scenephase, perform: handleScenePhase)
            .sheet(isPresented: $showingStableUpdate) {
                EagleBeta10WelcomeView {
                    hasSeenStableUpdate = true
                    showingStableUpdate = false
                }
            }
        }
    }
    
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .inactive, .background:
            handlebg()
            globallogger.stopcapture()

        case .active:
            globallogger.capture()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                EagleSceneManager.shared.applyPendingShortcutIfNeeded()
            }

        @unknown default:
            break
        }
    }

    private func handlebg() {
        guard mgr.rcready else { return }
        let keepSpringBoardRemoteCallAlive = UserDefaults.standard.bool(forKey: "keepSpringBoardRemoteCallAliveIOS16")
        if isIOS16() && keepSpringBoardRemoteCallAlive {
            return
        }

        var bgTask: UIBackgroundTaskIdentifier = .invalid

        bgTask = UIApplication.shared.beginBackgroundTask(withName: "RemoteCallCleanup") {
            endbgtask(&bgTask)
        }

        mgr.rcdestroy {
            self.endbgtask(&bgTask)
        }
    }

    private func endbgtask(_ task: inout UIBackgroundTaskIdentifier) {
        guard task != .invalid else { return }
        UIApplication.shared.endBackgroundTask(task)
        task = .invalid
    }
}

// file picker fixes
extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

// make strings compatiable with errors
extension String: @retroactive Error {}
