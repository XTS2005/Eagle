import Foundation

nonisolated enum LaraLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"

    static let storageKey = "lara.interfaceLanguage"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }

    var shortName: String {
        switch self {
        case .english: return "EN"
        case .spanish: return "ES"
        }
    }
}

nonisolated enum LaraL10n {
    static var language: LaraLanguage {
        guard
            let rawValue = UserDefaults.standard.string(forKey: LaraLanguage.storageKey),
            let language = LaraLanguage(rawValue: rawValue)
        else {
            return .english
        }
        return language
    }

    static func text(en: String, es: String) -> String {
        language == .spanish ? es : en
    }

    static func localized(_ key: String) -> String {
        if language == .spanish {
            return key
        }
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
