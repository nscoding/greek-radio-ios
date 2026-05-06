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
              let localizedStrings = localizedStringsDictionary else {
            return fallback
        }

        return localizedStrings[key] ?? fallback
    }

    private var localizedStringsDictionary: [String: String]? {
        let candidateLocalizations: [String]

        switch self {
        case .english:
            candidateLocalizations = []
        case .greek:
            candidateLocalizations = ["el"]
        }

        for localization in candidateLocalizations {
            if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: localization),
               let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] {
                return dictionary
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
