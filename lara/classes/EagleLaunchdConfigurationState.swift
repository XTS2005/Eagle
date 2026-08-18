import Darwin
import Foundation

nonisolated enum EagleLaunchdConfigurationState: Equatable {
    case checking
    case configuredEnabled
    case configuredDisabled
    case partial(disabled: Int, total: Int)
    case unavailable(lastKnownDisabled: Bool?)

    var isChecking: Bool {
        self == .checking
    }

    var isConfiguredEnabled: Bool {
        self == .configuredEnabled
    }

    var isConfiguredDisabled: Bool {
        self == .configuredDisabled
    }
}

nonisolated enum EagleFileExistenceState: Equatable {
    case checking
    case found
    case notFound
    case unavailable
}

nonisolated enum EagleLaunchdConfigurationReader {
    private static let disabledPlistPath =
        "/private/var/db/com.apple.xpc.launchd/disabled.plist"

    static func read(labels: [String]) -> EagleLaunchdConfigurationState? {
        guard !labels.isEmpty,
              let data = FileManager.default.contents(atPath: disabledPlistPath),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
              ) as? [String: Any] else {
            return nil
        }

        let disabledCount = labels.reduce(into: 0) { count, label in
            if (plist[label] as? Bool) == true {
                count += 1
            }
        }

        switch disabledCount {
        case 0:
            return .configuredEnabled
        case labels.count:
            return .configuredDisabled
        default:
            return .partial(disabled: disabledCount, total: labels.count)
        }
    }

    static func fileExistence(atPath path: String) -> EagleFileExistenceState {
        var fileStatus = stat()
        errno = 0
        let result = path.withCString { pointer in
            lstat(pointer, &fileStatus)
        }
        if result == 0 {
            return .found
        }
        return errno == ENOENT ? .notFound : .unavailable
    }
}
