import Foundation

/// Treat saved preferences as untrusted input without changing valid settings.
nonisolated enum EagleStoredThemeValues {
    static func flags(_ raw: Int) -> UInt32 {
        UInt32(exactly: raw) ?? 0
    }

    static func intensity(_ raw: Double) -> Double {
        min(max(raw.isFinite ? raw : 0.72, 0), 1)
    }

    static func dockPreviewCapacity(_ raw: Int) -> Int {
        [4, 5, 6].contains(raw) ? raw : 5
    }
}
