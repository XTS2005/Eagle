//
//  isunsupported.swift
//  lara
//
//  Created by ruter on 30.03.26.
//

import Foundation
import Darwin

/// The product support levels shown to users. Keep every iOS range in
/// `eagleSupportAssessment(version:machine:)`; native callers must not invent a
/// second, broader range.
enum EagleSupportStatus: String, Equatable {
    /// The engine has a path for this release, but it is not considered stable.
    case possible
    /// Confirmed on at least one device, with more device coverage still needed.
    case testedNeedsMoreTesting
    case supported
    case unsupported

    var allowsPrepare: Bool {
        self != .unsupported
    }
}

/// Stable diagnostic identifiers. These are deliberately not localized so a
/// shared Prepare report can be searched and compared across languages.
enum EagleSupportReason: String, Equatable {
    case ios16Experimental = "ios16.experimental"
    case ios1672LimitedTesting = "ios16.7.2.tested-limited"
    case ios17Through1871 = "ios17.0-ios18.7.1.supported"
    case ios260Through2601 = "ios26.0-ios26.0.1.supported"
    case belowIOS16 = "ios.below-16.unsupported"
    case ios1872OrNewer = "ios18.7.2-or-newer.unsupported"
    case unrecognizedMajorGap = "ios19-ios25.unsupported"
    case ios26After2601 = "ios26.after-26.0.1.unsupported"
    case futureMajor = "ios.after-26.unsupported"
    case memoryIntegrityEnforcement = "device.mie.unsupported"
}

struct EagleSupportAssessment: Equatable {
    let status: EagleSupportStatus
    let reason: EagleSupportReason

    var allowsPrepare: Bool {
        status.allowsPrepare
    }

    /// A concise bilingual explanation suitable for a compatibility screen or
    /// diagnostic export. The app UI can continue selecting its own language.
    func message(spanish: Bool) -> String {
        switch reason {
        case .ios16Experimental:
            return spanish
                ? "iOS 16.x es experimental. Puede funcionar, pero necesita más pruebas."
                : "iOS 16.x is experimental. It may work, but needs more testing."
        case .ios1672LimitedTesting:
            return spanish
                ? "iOS 16.7.2 fue probado, pero todavía necesita pruebas en más dispositivos."
                : "iOS 16.7.2 was tested, but still needs testing on more devices."
        case .ios17Through1871:
            return spanish
                ? "Esta versión está dentro del rango compatible de iOS 17.0 a iOS 18.7.1."
                : "This release is inside the supported iOS 17.0 through iOS 18.7.1 range."
        case .ios260Through2601:
            return spanish
                ? "Esta versión está dentro del rango compatible de iOS 26.0 a iOS 26.0.1."
                : "This release is inside the supported iOS 26.0 through iOS 26.0.1 range."
        case .belowIOS16:
            return spanish
                ? "Las versiones anteriores a iOS 16 no son compatibles."
                : "Releases earlier than iOS 16 are not supported."
        case .ios1872OrNewer:
            return spanish
                ? "iOS 18.7.2 y las versiones posteriores de iOS 18 no son compatibles."
                : "iOS 18.7.2 and later iOS 18 releases are not supported."
        case .unrecognizedMajorGap:
            return spanish
                ? "Este número principal de iOS no pertenece a un rango compatible conocido."
                : "This iOS major version is not part of a known supported range."
        case .ios26After2601:
            return spanish
                ? "Solo iOS 26.0 y iOS 26.0.1 son compatibles actualmente."
                : "Only iOS 26.0 and iOS 26.0.1 are currently supported."
        case .futureMajor:
            return spanish
                ? "Esta versión de iOS es más reciente que el motor compatible actual."
                : "This iOS release is newer than the current supported engine."
        case .memoryIntegrityEnforcement:
            return spanish
                ? "Este modelo usa protecciones de memoria que el motor actual no admite."
                : "This model uses memory protections that the current engine does not support."
        }
    }
}

func devicemachine() -> String {
    var sysinfo = utsname()
    uname(&sysinfo)

    let mirror = Mirror(reflecting: sysinfo.machine)
    return mirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
}

func hasmie(machine: String) -> Bool {
    machine.hasPrefix("iPhone18,")
}

func hasmie() -> Bool {
    hasmie(machine: devicemachine())
}

/// Pure compatibility resolver. Accepting the version and machine explicitly
/// makes every boundary testable without pretending a simulator has kernel
/// access.
func eagleSupportAssessment(
    version: OperatingSystemVersion,
    machine: String
) -> EagleSupportAssessment {
    if hasmie(machine: machine) {
        return EagleSupportAssessment(
            status: .unsupported,
            reason: .memoryIntegrityEnforcement
        )
    }

    switch version.majorVersion {
    case ..<16:
        return EagleSupportAssessment(status: .unsupported, reason: .belowIOS16)

    case 16:
        if version.minorVersion == 7, version.patchVersion == 2 {
            return EagleSupportAssessment(
                status: .testedNeedsMoreTesting,
                reason: .ios1672LimitedTesting
            )
        }
        return EagleSupportAssessment(status: .possible, reason: .ios16Experimental)

    case 17:
        return EagleSupportAssessment(status: .supported, reason: .ios17Through1871)

    case 18:
        let isAtOrBefore1871 = version.minorVersion < 7 ||
            (version.minorVersion == 7 && version.patchVersion <= 1)
        return isAtOrBefore1871
            ? EagleSupportAssessment(status: .supported, reason: .ios17Through1871)
            : EagleSupportAssessment(status: .unsupported, reason: .ios1872OrNewer)

    case 19...25:
        return EagleSupportAssessment(status: .unsupported, reason: .unrecognizedMajorGap)

    case 26:
        let is260Through2601 = version.minorVersion == 0 && version.patchVersion <= 1
        return is260Through2601
            ? EagleSupportAssessment(status: .supported, reason: .ios260Through2601)
            : EagleSupportAssessment(status: .unsupported, reason: .ios26After2601)

    default:
        return EagleSupportAssessment(status: .unsupported, reason: .futureMajor)
    }
}

func eagleSupportAssessment() -> EagleSupportAssessment {
    eagleSupportAssessment(
        version: ProcessInfo.processInfo.operatingSystemVersion,
        machine: devicemachine()
    )
}

func isunsupported() -> Bool {
    !eagleSupportAssessment().allowsPrepare
}
