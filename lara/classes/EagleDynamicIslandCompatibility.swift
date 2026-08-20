import Foundation

/// A fail-closed hardware gate for features that require Dynamic Island.
///
/// Apple does not expose a public `hasDynamicIsland` API. Keep the model
/// matrix explicit instead of inferring support from screen size, safe-area
/// insets, or the numeric generation: iPhone 14/14 Plus, iPhone 16e and
/// iPhone 17e are counterexamples to all of those shortcuts. Native Aura code
/// still has to verify the live SpringBoard host before changing anything.
struct EagleDynamicIslandCompatibility: Equatable {
    enum Availability: String {
        case supported
        case unsupported
        case unknown
    }

    let runtimeMachine: String
    let modelIdentifier: String
    let isSimulator: Bool
    let availability: Availability

    /// Known hardware may be previewed in Simulator, but SpringBoard mutation
    /// is intentionally limited to a physical, explicitly supported model and
    /// an access-engine combination that has not been field-blocked.
    var canAttemptLiveIslandAura: Bool {
        availability == .supported &&
            !isSimulator &&
            eagleSupportAssessment(
                version: ProcessInfo.processInfo.operatingSystemVersion,
                machine: modelIdentifier
            ).allowsPrepare
    }

    var diagnosticsToken: String {
        "runtime=\(runtimeMachine) model=\(modelIdentifier) " +
            "simulator=\(isSimulator) island=\(availability.rawValue) " +
            "live=\(canAttemptLiveIslandAura ? "allowed" : "blocked")"
    }

    static var current: EagleDynamicIslandCompatibility {
        let runtimeMachine = devicemachine()
#if targetEnvironment(simulator)
        let isSimulator = true
        let simulatedModel = ProcessInfo.processInfo.environment[
            "SIMULATOR_MODEL_IDENTIFIER"
        ]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelIdentifier: String
        if let simulatedModel, !simulatedModel.isEmpty {
            modelIdentifier = simulatedModel
        } else {
            modelIdentifier = runtimeMachine
        }
#else
        let isSimulator = false
        let modelIdentifier = runtimeMachine
#endif
        return classify(
            runtimeMachine: runtimeMachine,
            modelIdentifier: modelIdentifier,
            isSimulator: isSimulator
        )
    }

    /// Pure classification entry point kept internal so generic/Simulator
    /// builds can exercise every known model without requiring a device.
    static func classify(
        runtimeMachine: String,
        modelIdentifier: String,
        isSimulator: Bool
    ) -> EagleDynamicIslandCompatibility {
        let normalized = modelIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let availability: Availability
        if dynamicIslandModels.contains(normalized) {
            availability = .supported
        } else if nonDynamicIslandModels.contains(normalized) ||
                    isOlderIPhoneFamily(normalized) ||
                    isKnownNonIPhoneDevice(normalized) {
            availability = .unsupported
        } else {
            // New or unrecognized iPhones remain disabled until their Apple
            // hardware specification and live SpringBoard host are verified.
            availability = .unknown
        }
        return EagleDynamicIslandCompatibility(
            runtimeMachine: runtimeMachine,
            modelIdentifier: normalized.isEmpty ? "unknown" : normalized,
            isSimulator: isSimulator,
            availability: availability
        )
    }

    // Hardware identifiers are sourced from Apple's installed Xcode
    // Simulator device profiles; product capabilities are cross-checked with
    // Apple's published iPhone model specifications.
    private static let dynamicIslandModels: Set<String> = [
        // iPhone 14 Pro / 14 Pro Max
        "iPhone15,2", "iPhone15,3",
        // iPhone 15 / 15 Plus / 15 Pro / 15 Pro Max
        "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2",
        // iPhone 16 Pro / 16 Pro Max / 16 / 16 Plus
        "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
        // iPhone 17 Pro / 17 Pro Max / 17 / iPhone Air
        "iPhone18,1", "iPhone18,2", "iPhone18,3", "iPhone18,4",
    ]

    private static let nonDynamicIslandModels: Set<String> = [
        "iPhone14,7", // iPhone 14
        "iPhone14,8", // iPhone 14 Plus
        "iPhone17,5", // iPhone 16e
        "iPhone18,5", // iPhone 17e
    ]

    private static func isOlderIPhoneFamily(_ identifier: String) -> Bool {
        guard identifier.hasPrefix("iPhone"),
              let comma = identifier.firstIndex(of: ","),
              let family = Int(identifier[identifier.index(
                identifier.startIndex,
                offsetBy: "iPhone".count
              )..<comma]) else {
            return false
        }
        return family < 15
    }

    private static func isKnownNonIPhoneDevice(_ identifier: String) -> Bool {
        identifier.hasPrefix("iPad") ||
            identifier.hasPrefix("iPod") ||
            identifier.hasPrefix("AppleTV") ||
            identifier.hasPrefix("Watch")
    }
}
