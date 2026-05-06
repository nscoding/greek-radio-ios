import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    static let userDefaultsKey = "selectedAppLanguageCode"

    case english = "en"
    case greek = "el"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var flag: String {
        switch self {
        case .english:
            return "🇬🇧"
        case .greek:
            return "🇬🇷"
        }
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .greek:
            return "Ελληνικά"
        }
    }

    func localizedString(_ key: String) -> String {
        let fallback = Bundle.main.localizedString(forKey: key, value: key, table: nil)

        guard rawValue != AppLanguage.english.rawValue,
              let bundle = localizedBundle else {
            return fallback
        }

        return bundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    private var localizedBundle: Bundle? {
        let candidateNames: [String]

        switch self {
        case .english:
            candidateNames = []
        case .greek:
            candidateNames = [rawValue, "Greek"]
        }

        for name in candidateNames {
            if let localizationPath = Bundle.main.path(forResource: name, ofType: "lproj"),
               let bundle = Bundle(path: localizationPath) {
                return bundle
            }
        }

        return nil
    }

    static var current: AppLanguage {
        let storedValue = UserDefaults.standard.string(forKey: userDefaultsKey)
        return AppLanguage(rawValue: storedValue ?? AppLanguage.english.rawValue) ?? .english
    }
}

func appLocalized(_ key: String) -> String {
    AppLanguage.current.localizedString(key)
}
