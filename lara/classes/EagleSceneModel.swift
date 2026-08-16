import Foundation

enum EagleSceneAuraMode: Int, Codable, CaseIterable, Hashable, Identifiable {
    case glow = 1
    case pulse = 2
    case tint = 3
    case rainbow = 4

    var id: Int { rawValue }
}

struct EagleSceneAuraProfile: Codable, Hashable {
    var mode: EagleSceneAuraMode
    var red: Int
    var green: Int
    var blue: Int

    init(mode: EagleSceneAuraMode, red: Int, green: Int, blue: Int) {
        self.mode = mode
        self.red = min(max(red, 0), 255)
        self.green = min(max(green, 0), 255)
        self.blue = min(max(blue, 0), 255)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            mode: try values.decode(EagleSceneAuraMode.self, forKey: .mode),
            red: try values.decode(Int.self, forKey: .red),
            green: try values.decode(Int.self, forKey: .green),
            blue: try values.decode(Int.self, forKey: .blue)
        )
    }

    var rgbSummary: String {
        "RGB \(red), \(green), \(blue)"
    }
}

enum EagleSceneComponent: String, Codable, CaseIterable, Hashable, Identifiable {
    case wallpaper
    case passcode
    case card
    case dockLayout
    case icons
    case islandAura
    case dockAura

    var id: String { rawValue }
}

enum EagleSceneResultState: String, Codable, Hashable {
    case pending
    case applied
    case skipped
    case failed
}

struct EagleSceneComponentResult: Codable, Hashable, Identifiable {
    let component: EagleSceneComponent
    let state: EagleSceneResultState
    let detail: String

    var id: String { component.rawValue }
}

struct EagleSceneRunReport: Codable, Identifiable, Hashable {
    let id: UUID
    let sceneID: UUID
    let sceneName: String
    let startedAt: Date
    var finishedAt: Date?
    var results: [EagleSceneComponentResult]

    var isPending: Bool {
        results.contains { $0.state == .pending }
    }

    var hasAppliedChanges: Bool {
        results.contains { $0.state == .applied }
    }
}
