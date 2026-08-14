//
//  LaraCustomProfile.swift
//  Lara Custom
//
//  Central feature profile for the custom Lara fork.
//

import Foundation

enum LaraCapability: String, CaseIterable {
    case exploit
    case vfs
    case sandbox
    case remoteCall
}

enum LaraFeature: String, CaseIterable {
    // SpringBoard
    case remoteCallCustomizer
    case liquidGlass
    case springBoardCustomizer

    // Lock Screen
    case passcodeTheme

    // Apps
    case cardOverwrite
    case appDecrypt
    case threeAppBypass
    case unblacklist
    case jitEnabler

    // User Interface
    case dirtyZero
    case showHiddenIcons
    case mobileGestalt
    case fontOverwrite
    case systemColorPatcher

    // System
    case varClean
    case customOverwrite
    case otaUpdates
    case screenTime

    // Utilities
    case extraTools
    case fileManagerTab
    case respringAction
    case panicAction

    /// Each set is a valid capability path. A feature with more than one path
    /// can run when any one of those paths is ready.
    var supportedCapabilityPaths: [Set<LaraCapability>] {
        switch self {
        case .remoteCallCustomizer:
            return [[.exploit, .remoteCall]]
        case .liquidGlass, .springBoardCustomizer, .cardOverwrite,
             .dirtyZero, .fontOverwrite, .customOverwrite:
            return [[.exploit, .vfs]]
        case .passcodeTheme, .appDecrypt, .threeAppBypass, .unblacklist,
             .jitEnabler, .mobileGestalt, .varClean:
            return [[.exploit, .sandbox]]
        case .showHiddenIcons:
            return [[.exploit, .vfs], [.exploit, .sandbox]]
        case .systemColorPatcher:
            return [[.exploit, .vfs, .sandbox]]
        case .otaUpdates, .screenTime, .extraTools, .fileManagerTab,
             .respringAction, .panicAction:
            return [[.exploit]]
        }
    }
}

enum LaraCustomProfile {
    /// Add a case here to hide that option from Lara Custom.
    /// The original Lara project remains unchanged.
    static let disabledFeatures: Set<LaraFeature> = []

    static func includes(_ feature: LaraFeature) -> Bool {
        !disabledFeatures.contains(feature)
    }
}
