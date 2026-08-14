//
//  SBCustomizerView.swift
//  lara
//
//  Created by lunginspector on 5/18/26.
//

import SwiftUI
import UIKit

enum SpringBoardOptions: String, CaseIterable {
    case DockHidden = "DockHidden"
    case HomeBarHidden = "HomeBar"
    case FolderBGHidden = "FolderBGHidden"
    case FolderBlurDisabled = "FolderBlurDisabled"
    case SwitcherBlurDisabled = "SwitcherBlurDisabled"
    case CCModuleBackgroundDisabled = "CCModuleBackgroundDisabled"
    case PodBackgroundDisabled = "PodBackgroundDisabled"
    case NotifBackgroundDisabled = "NotifBackgroundDisabled"
    case ShortcutBanner = "ShortcutBanner"
}

enum OverwritingFileTypes {
    case springboard
    case cc
    case plist
    case audio
    case region
}


struct GeneralOption: Identifiable {
    var value: String
    var id = UUID()
    var key: String
    var sbType: SpringboardColorManager.SpringboardType?
    var title: String
    var shortTitle: String?
    var imageName: String
    var fileType: OverwritingFileTypes
    var options: [String] = []
    var selectedOption: String = "Visible"
    
    var maxVers: Double = 18.9
    
    var color: Color = Color.gray
    var blur: Double = 30
}

struct SpringBoardView: View {
    // list of options
    @State var tweakOptions: [GeneralOption] = [
        .init(value: getDefaultStr(forKey: "Dock"), key: "Dock", sbType: .dock, title: NSLocalizedString("Dock", comment: "Springboard tool"), imageName: "dock.rectangle", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Color", "Disabled"]),
        .init(value: getDefaultStr(forKey: "HomeBar"), key: "HomeBar", title: NSLocalizedString("Home Bar", comment: "Springboard tool"), imageName: "iphone", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Disabled"], maxVers: 26.0),
        .init(value: getDefaultStr(forKey: "FolderBG"), key: "FolderBG", sbType: .folder, title: NSLocalizedString("Folder Background", comment: "Springboard tool"), imageName: "folder", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Color", "Disabled"]),
        .init(value: getDefaultStr(forKey: "FolderBlur"), key: "FolderBlur", sbType: .folderBG, title: NSLocalizedString("Folder Blur", comment: "Springboard tool"), imageName: "folder.circle", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Color", "Disabled"]),
        .init(value: getDefaultStr(forKey: "CCModuleBG"), key: "CCModuleBG", sbType: .module, title: NSLocalizedString("CC Module Background", comment: "Springboard tool"), shortTitle: "CC Module BG", imageName: "switch.2", fileType: OverwritingFileTypes.cc, options: ["Visible", "Color", "Disabled"]),
        .init(value: getDefaultStr(forKey: "CCBG"), key: "CCBG", sbType: .moduleBG, title: NSLocalizedString("CC Background Blur", comment: "Springboard tool"), imageName: "switch.2", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Color", "Disabled"]),
        .init(value: getDefaultStr(forKey: "Switcher"), key: "Switcher", sbType: .switcher, title: NSLocalizedString("App Switcher Blur", comment: "Springboard tool"), imageName: "apps.iphone", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Blur", "Disabled"], maxVers: 26.0),
        .init(value: getDefaultStr(forKey: "PodBG"), key: "PodBG", sbType: .libraryFolder, title: NSLocalizedString("Library Pod Background", comment: "Springboard tool"), shortTitle: "Library Pod BG", imageName: "square.stack", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Color", "Disabled"]),
        .init(value: getDefaultStr(forKey: "NotifBG"), key: "NotifBG", sbType: .notif, title: NSLocalizedString("Notification Banner Background", comment: "Springboard tool"), shortTitle: "Notification BG", imageName: "platter.filled.top.iphone", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Color", "Disabled"]),
        .init(value: getDefaultStr(forKey: "NotifShadow"), key: "NotifShadow", sbType: .notifShadow, title: NSLocalizedString("Notification Banner Shadow", comment: "Springboard tool"), shortTitle: "Notification Shadow", imageName: "platter.filled.top.iphone", fileType: OverwritingFileTypes.springboard, options: ["Visible", "Color", "Disabled"]),
    ]

    let mgr: laramgr
    let replacementPaths: [String: [String]] = [
        SpringBoardOptions.DockHidden.rawValue: ["CoreMaterial.framework/dockDark.materialrecipe", "CoreMaterial.framework/dockLight.materialrecipe"],
        SpringBoardOptions.HomeBarHidden.rawValue: ["MaterialKit.framework/Assets.car"],
        SpringBoardOptions.FolderBGHidden.rawValue: ["SpringBoardHome.framework/folderLight.materialrecipe", "SpringBoardHome.framework/folderDark.materialrecipe", "SpringBoardHome.framework/folderDarkSimplified.materialrecipe"],
        SpringBoardOptions.FolderBlurDisabled.rawValue: ["SpringBoardHome.framework/folderExpandedBackgroundHome.materialrecipe", "SpringBoardHome.framework/folderExpandedBackgroundHomeSimplified.materialrecipe"],
        SpringBoardOptions.SwitcherBlurDisabled.rawValue: ["SpringBoard.framework/homeScreenBackdrop-application.materialrecipe", "SpringBoard.framework/homeScreenBackdrop-switcher.materialrecipe"],
        SpringBoardOptions.CCModuleBackgroundDisabled.rawValue: ["CoreMaterial.framework/modules.materialrecipe"],
        SpringBoardOptions.PodBackgroundDisabled.rawValue: ["SpringBoardHome.framework/podBackgroundViewLight.visualstyleset", "SpringBoardHome.framework/podBackgroundViewDark.visualstyleset"],
        SpringBoardOptions.NotifBackgroundDisabled.rawValue: ["CoreMaterial.framework/plattersDark.materialrecipe", "CoreMaterial.framework/platters.materialrecipe"],
        SpringBoardOptions.ShortcutBanner.rawValue: ["SpringBoard.framework/BannersAuthorizedBundleIDs.plist"]
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "Applying", icon: "checkmark")) {
                    Button("Apply") {
                        applyTweaks()
                    }
                    Button("Reset all") {
                        for ind in tweakOptions.indices {
                            tweakOptions[ind].value = "Visible"
                            tweakOptions[ind].selectedOption = "Visible"
                            UserDefaults.standard.set("Visible", forKey: tweakOptions[ind].key)
                        }
                        applyTweaks()
                    }
                }
                ForEach($tweakOptions) { $option in
                    if doubleSystemVersion() <= option.maxVers {
                        Section(header: HeaderLabel(text: option.title, icon: option.imageName)) {
                            Picker("Option", selection: $option.selectedOption) {
                                ForEach(0..<option.options.count) { ind in
                                    Text(option.options[ind]).tag(option.options[ind])
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .onChange(of: option.selectedOption) { newvalue in
                                option.value = newvalue
                                UserDefaults.standard.set(newvalue, forKey: option.key)
                            }
                            if option.selectedOption == "Color" || option.selectedOption == "Blur" {
                                if option.selectedOption == "Color" {
                                    HStack(spacing: 12) {
                                        Text("Color")
                                        Spacer()
                                        Text(colortohex(option.color))
                                            .monospaced()
                                            .foregroundColor(.secondary)
                                        ColorPicker("Set notification banner color", selection: $option.color)
                                            .labelsHidden()
                                            .frame(width: 40)
                                            .onChange(of: option.color) { newcolor in
                                                do {
                                                    try SpringboardColorManager.createColor(forType: option.sbType!, color: CIColor(color: UIColor(newcolor)), blur: Int(option.blur), asTemp: false)
                                                    print("Success")
                                                } catch {
                                                    print(error.localizedDescription)
                                                }
                                            }
                                    }
                                }
                                HStack {
                                    Text("Blur:")
                                    Spacer()
                                    Text("\(Int(option.blur))")
                                        .monospaced()
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: $option.blur, in: 0...150, step: 1.0, onEditingChanged: { _ in
                                    do {
                                        try SpringboardColorManager.createColor(forType: option.sbType!, color: CIColor(color: UIColor(option.color)), blur: Int(option.blur), asTemp: false)
                                        print("Success")
                                    } catch {
                                        print(error.localizedDescription)
                                    }
                                })
                            }
                        }
                    }
                }
            }
            .navigationTitle("SpringBoard Tools")
            .onAppear {
                load()
            }
        }
    }

    func load() {
        for (i, option) in tweakOptions.enumerated() {
            tweakOptions[i].value = getDefaultStr(forKey: option.key)
            tweakOptions[i].selectedOption = tweakOptions[i].value
            if option.sbType != nil {
                if option.value == "Color" {
                    tweakOptions[i].color = SpringboardColorManager.getColor(forType: option.sbType!)
                    tweakOptions[i].blur = SpringboardColorManager.getBlur(forType: option.sbType!)
                }
            }
        }
    }
    
    func apply(_ sbType: SpringboardColorManager.SpringboardType, _ color: Color, _ blur: Int, save: Bool = true) -> Bool {
        do {
            try SpringboardColorManager.createColor(forType: sbType, color: CIColor(color: UIColor(color)), blur: blur, asTemp: !save)
            SpringboardColorManager.applyColor(forType: sbType, asTemp: !save)
            if !save {
                try SpringboardColorManager.deteleColor(forType: sbType)
            }
            print("Success")
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    func applyTweaks() {
        var failed: Bool = false
        for option in tweakOptions {
            //  apply tweak
            if option.value == "Disabled" {
                print("Applying tweak \"" + option.title + "\"")
                var succeeded = false
                if option.sbType != nil {
                    succeeded = apply(option.sbType!, .gray.opacity(0), 0)
                } else {
                    succeeded = overwriteFile(typeOfFile: option.fileType, fileIdentifier: option.key, true)
                }
                if succeeded {
                    print("Successfully applied tweak \"" + option.title + "\"")
                } else {
                    print("Failed to apply tweak \"" + option.title + "\"!!!")
                    failed = true
                }
                
            } else if option.value == "Visible" {
                print("Applying tweak \"" + option.title + "\"")
                if option.sbType != nil {
                    if option.sbType! == .switcher {
                        let succeeded = apply(option.sbType!, .gray.opacity(1), 20, save: false)
                        if succeeded {
                            print("Successfully applied tweak \"" + option.title + "\"")
                        } else {
                            print("Failed to apply tweak \"" + option.title + "\"!!!")
                        }
                    } else {
                        do {
                            try SpringboardColorManager.revertFiles(forType: option.sbType!)
                            print("Successfully applied tweak \"" + option.title + "\"")
                        } catch {
                            print("Failed to apply tweak \"" + option.title + "\"!!!")
                            print(error.localizedDescription)
                        }
                    }
                } else {
                    let succeeded = overwriteFile(typeOfFile: option.fileType, fileIdentifier: option.key, false)
                    if succeeded {
                        print("Successfully applied tweak \"" + option.title + "\"")
                    } else {
                        print("Failed to apply tweak \"" + option.title + "\"!!!")
                    }
                }
                
            } else if option.value == "Color" || option.value == "Blur" {
                if option.sbType != nil {
                    print("Applying tweak \"" + option.title + "\"")
                    let succeeded = apply(option.sbType!, option.color, Int(option.blur))
                    if succeeded {
                        print("Successfully applied tweak \"" + option.title + "\"")
                    } else {
                        print("Failed to apply tweak \"" + option.title + "\"!!!")
                        failed = true
                    }
                } else {
                    print("\(option.title) does not have a springboard type!")
                    failed = true
                }
            }
        }
        if failed {
            Alertinator.shared.alert(title: "useless ass alert", body: "something failed while applying tweaks")
        } else {
            Alertinator.shared.alert(title: "Success!", body: "Respring to see changes.", actionLabel: "Respring", action: { mgr.respring() })
        }
    }
    
    // MARK: sigh     //UIApplication.shared.alert(title: NSLocalizedString("Successfully applied tweaks", comment: "Successfully applied tweaks"), body: NSLocalizedString("Respring to see changes", comment: "Respring to see changes"))
    func overwriteFile<Value>(typeOfFile: OverwritingFileTypes, fileIdentifier: String, _ value: Value) -> Bool {
        // find the path and replace the file
        // springboard option
        if typeOfFile == OverwritingFileTypes.springboard {
            // springboard tweak being applied
            if replacementPaths[fileIdentifier] != nil {
                var succeeded = true
                for path in replacementPaths[fileIdentifier]! {
                    if fileIdentifier == "HomeBar" && value as? Bool == false {
                        if let url: URL = Bundle.main.url(forResource: "HomeBarAssets", withExtension: "car") {
                            do {
                                let replacementCar = try Data(contentsOf: url)
                                //try MDC.overwriteFile(at: "/System/Library/PrivateFrameworks/" + path, with: replacementCar)
                            } catch {
                                print(error.localizedDescription)
                                succeeded = false
                            }
                        } else {
                            print("Home bar file not found!")
                            return false
                        }
                    } else {
                        let randomGarbage = Data("###".utf8)
                        
                        let result = laramgr.shared.lara_overwritefile(target: "/System/Library/PrivateFrameworks/" + path, data: randomGarbage)
                        
                        if result.ok {
                            print("i hope it worked")
                        } else {
                            print("it didn't")
                        }
                        
                        return true
                    }
                }
                return succeeded
            }
        }
        
        return true
    }
}

func getDefaultStr(forKey: String, defaultValue: String = "Visible") -> String {
    let defaults = UserDefaults.standard
    
    return defaults.string(forKey: forKey) ?? defaultValue
}

func colortohex(_ color: Color) -> String {
    let ui = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    ui.getRed(&r, green: &g, blue: &b, alpha: &a)
    return String(format: "#%02X%02X%02X (%02X)", Int(r*255), Int(g*255), Int(b*255), Int(a*255))
}
