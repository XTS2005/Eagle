import AppIntents
import Foundation

enum EaglePresetScene: String, AppEnum {
    case focus
    case night
    case play
    case calm

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Eagle Scene")
    static var caseDisplayRepresentations: [EaglePresetScene: DisplayRepresentation] = [
        .focus: DisplayRepresentation(title: "Focus"),
        .night: DisplayRepresentation(title: "Night"),
        .play: DisplayRepresentation(title: "Play"),
        .calm: DisplayRepresentation(title: "Calm")
    ]

    var sceneID: UUID {
        switch self {
        case .focus: return UUID(uuidString: "EAF10000-0000-4000-8000-000000000001")!
        case .night: return UUID(uuidString: "EAF10000-0000-4000-8000-000000000002")!
        case .play: return UUID(uuidString: "EAF10000-0000-4000-8000-000000000003")!
        case .calm: return UUID(uuidString: "EAF10000-0000-4000-8000-000000000004")!
        }
    }
}

struct ApplyEagleSceneIntent: AppIntent {
    static var title: LocalizedStringResource = "Apply Eagle Scene"
    static var description = IntentDescription(
        "Opens Eagle and applies a protected wallpaper, passcode, card, and Dock Scene."
    )
    static var openAppWhenRun = true

    @Parameter(title: "Scene")
    var scene: EaglePresetScene

    static var parameterSummary: some ParameterSummary {
        Summary("Apply \(\.$scene)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(
            scene.sceneID.uuidString,
            forKey: EagleSceneShortcutBridge.pendingSceneKey
        )
        return .result(dialog: "Opening Eagle to apply \(scene.rawValue.capitalized) safely.")
    }
}

struct ApplyEagleMomentIntent: AppIntent {
    static var title: LocalizedStringResource = "Apply Eagle Moment"
    static var description = IntentDescription(
        "Opens Eagle and prepares a private Scene suggestion for the current moment."
    )
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(
            true,
            forKey: EagleSceneShortcutBridge.pendingMomentKey
        )
        return .result(dialog: "Opening Eagle to prepare your Moment safely.")
    }
}

struct EagleAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ApplyEagleSceneIntent(),
            phrases: [
                "Apply \(\.$scene) with \(.applicationName)",
                "Activate \(\.$scene) in \(.applicationName)"
            ],
            shortTitle: "Apply Scene",
            systemImageName: "rectangle.3.group.fill"
        )
        AppShortcut(
            intent: ApplyEagleMomentIntent(),
            phrases: [
                "Choose my Moment with \(.applicationName)",
                "Apply the best Scene in \(.applicationName)"
            ],
            shortTitle: "Eagle Moment",
            systemImageName: "wand.and.stars"
        )
    }
}

enum EagleSceneShortcutBridge {
    nonisolated static let pendingSceneKey = "eagle.scenes.pendingShortcut"
    nonisolated static let pendingMomentKey = "eagle.scenes.pendingMoment"
}
