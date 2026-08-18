import Foundation

enum EaglePreferenceKeys {
    static let accessMethod = "selectedMethod"
    static let legacyAccessMethod = "selectedmethod"
    static let disableLogDividers = "loggerNoBS"
    static let legacyDisableLogDividers = "loggernobullshit"
}

enum EaglePreferenceMigration {
    private static let versionKey = "eagle.preferenceMigration.version"
    private static let currentVersion = 1
    private static let validAccessMethods = Set(["VFS", "SBX", "Hybrid"])
    private static let defaultAccessMethod = "Hybrid"
    private static let defaultDisableLogDividers = true

    static func runIfNeeded(defaults: UserDefaults = .standard) {
        guard defaults.integer(forKey: versionKey) < currentVersion else {
            return
        }

        let currentMethod = defaults.string(forKey: EaglePreferenceKeys.accessMethod)
        let legacyMethod = defaults.string(forKey: EaglePreferenceKeys.legacyAccessMethod)
        let resolvedMethod: String
        if let currentMethod, validAccessMethods.contains(currentMethod) {
            resolvedMethod = currentMethod
        } else if let legacyMethod, validAccessMethods.contains(legacyMethod) {
            resolvedMethod = legacyMethod
        } else {
            resolvedMethod = defaultAccessMethod
        }
        persistAccessMethod(resolvedMethod, defaults: defaults)

        let disableLogDividers: Bool
        if defaults.object(forKey: EaglePreferenceKeys.disableLogDividers) != nil {
            disableLogDividers = defaults.bool(
                forKey: EaglePreferenceKeys.disableLogDividers
            )
        } else if defaults.object(
            forKey: EaglePreferenceKeys.legacyDisableLogDividers
        ) != nil {
            disableLogDividers = defaults.bool(
                forKey: EaglePreferenceKeys.legacyDisableLogDividers
            )
        } else {
            disableLogDividers = defaultDisableLogDividers
        }
        persistDisableLogDividers(disableLogDividers, defaults: defaults)

        defaults.set(currentVersion, forKey: versionKey)
    }

    static func persistAccessMethod(
        _ rawValue: String,
        defaults: UserDefaults = .standard
    ) {
        guard validAccessMethods.contains(rawValue) else { return }
        defaults.set(rawValue, forKey: EaglePreferenceKeys.accessMethod)
        defaults.set(rawValue, forKey: EaglePreferenceKeys.legacyAccessMethod)
    }

    static func persistDisableLogDividers(
        _ disabled: Bool,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(disabled, forKey: EaglePreferenceKeys.disableLogDividers)
        defaults.set(disabled, forKey: EaglePreferenceKeys.legacyDisableLogDividers)
    }
}
