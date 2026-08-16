import Foundation

enum EagleReleaseChannel: String, CaseIterable, Identifiable {
    case stable
    case beta
    case experimental

    static let storageKey = "eagle.release.channel"

    var id: String { rawValue }

    var level: Int {
        switch self {
        case .stable: return 0
        case .beta: return 1
        case .experimental: return 2
        }
    }

    var title: String {
        switch self {
        case .stable:
            return LaraL10n.text(en: "Stable", es: "Estable")
        case .beta:
            return "Beta"
        case .experimental:
            return LaraL10n.text(en: "Experimental", es: "Experimental")
        }
    }

    var explanation: String {
        switch self {
        case .stable:
            return LaraL10n.text(
                en: "Only the most conservative, verified features are available.",
                es: "Solo están disponibles las funciones más conservadoras y verificadas."
            )
        case .beta:
            return LaraL10n.text(
                en: "Adds Scenes and tested motion effects with safe fallbacks.",
                es: "Añade Escenas y efectos animados probados con alternativas seguras."
            )
        case .experimental:
            return LaraL10n.text(
                en: "Unlocks private-surface experiments that may be unavailable on some SpringBoard states.",
                es: "Desbloquea experimentos con superficies privadas que pueden no estar disponibles en algunos estados de SpringBoard."
            )
        }
    }
}

enum EagleProductFeature: String, CaseIterable, Identifiable {
    case prepare
    case wallpapers
    case completeStyles
    case islandGlow
    case dockGlow
    case scenes
    case auraPulse
    case auraRainbow
    case islandTint
    case advancedSystemTools

    var id: String { rawValue }

    var minimumChannel: EagleReleaseChannel {
        switch self {
        case .prepare, .wallpapers, .completeStyles, .islandGlow, .dockGlow:
            return .stable
        case .scenes, .auraPulse, .auraRainbow:
            return .beta
        case .islandTint, .advancedSystemTools:
            return .experimental
        }
    }

    var title: String {
        switch self {
        case .prepare: return LaraL10n.text(en: "Prepare iPhone", es: "Preparar iPhone")
        case .wallpapers: return LaraL10n.text(en: "Wallpapers", es: "Fondos")
        case .completeStyles: return LaraL10n.text(en: "Complete Styles", es: "Estilos completos")
        case .islandGlow: return "Island Glow"
        case .dockGlow: return "Dock Glow"
        case .scenes: return LaraL10n.text(en: "Scenes", es: "Escenas")
        case .auraPulse: return "Aura Pulse"
        case .auraRainbow: return "Aura Rainbow"
        case .islandTint: return "True Tint"
        case .advancedSystemTools:
            return LaraL10n.text(en: "Advanced system tools", es: "Herramientas avanzadas del sistema")
        }
    }
}

enum EagleFeaturePolicy {
    static func allows(
        _ feature: EagleProductFeature,
        channel: EagleReleaseChannel
    ) -> Bool {
        channel.level >= feature.minimumChannel.level
    }

    static func channel(from rawValue: String) -> EagleReleaseChannel {
        EagleReleaseChannel(rawValue: rawValue) ?? .stable
    }

    /// Resolves the persisted channel through one fail-closed path. Unknown or
    /// corrupt values intentionally become Stable instead of unlocking tools.
    static func persistedChannel(
        defaults: UserDefaults = .standard
    ) -> EagleReleaseChannel {
        channel(from: defaults.string(forKey: EagleReleaseChannel.storageKey) ?? "")
    }

    static func persist(
        _ channel: EagleReleaseChannel,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(channel.rawValue, forKey: EagleReleaseChannel.storageKey)
    }

    static func allows(
        _ feature: EagleProductFeature,
        defaults: UserDefaults = .standard
    ) -> Bool {
        allows(feature, channel: persistedChannel(defaults: defaults))
    }

    static func availableFeatures(
        channel: EagleReleaseChannel
    ) -> [EagleProductFeature] {
        EagleProductFeature.allCases.filter { allows($0, channel: channel) }
    }

    /// Resolves a saved Scene Aura profile at the moment it is about to reach
    /// SpringBoard. Scenes can outlive a feature-channel change, so filtering
    /// only the editor would let an older pending/imported Scene bypass the
    /// current policy.
    static func allowsSceneAura(
        _ mode: EagleSceneAuraMode,
        target: EagleSceneAuraTarget,
        channel: EagleReleaseChannel = persistedChannel(),
        operatingSystemVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
    ) -> Bool {
        switch mode {
        case .glow:
            return allows(target == .island ? .islandGlow : .dockGlow, channel: channel)
        case .pulse:
            return allows(.auraPulse, channel: channel)
        case .rainbow:
            return allows(.auraRainbow, channel: channel)
        case .tint:
            return target == .island &&
                operatingSystemVersion.majorVersion == 18 &&
                allows(.islandTint, channel: channel)
        }
    }
}
