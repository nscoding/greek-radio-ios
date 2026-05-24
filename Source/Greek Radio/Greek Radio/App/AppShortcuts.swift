import UIKit

enum AppShortcut {
    static let selectedSectionKey = "selectedSection"
    static let pendingStationIDKey = "pendingShortcutStationID"
    static let urlScheme = "greekradio"

    private static let favoritesType = shortcutType("favorites")
    private static let stationTypePrefix = shortcutType("station.")

    static func handle(_ shortcutItem: UIApplicationShortcutItem) {
        let userDefaults = UserDefaults.standard

        if shortcutItem.type == favoritesType {
            userDefaults.set("favorites", forKey: selectedSectionKey)
            return
        }

        guard shortcutItem.type.hasPrefix(stationTypePrefix) else { return }

        if let stationID = shortcutItem.userInfo?["stationID"] as? NSNumber {
            userDefaults.set(stationID.stringValue, forKey: pendingStationIDKey)
        } else {
            let stationID = String(shortcutItem.type.dropFirst(stationTypePrefix.count))
            userDefaults.set(stationID, forKey: pendingStationIDKey)
        }
    }

    static func stationURL(for stationID: Int64) -> URL {
        URL(string: "\(urlScheme)://station/\(stationID)")!
    }

    @discardableResult
    static func handle(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == urlScheme else {
            return false
        }

        if url.host == "favorites" {
            UserDefaults.standard.set("favorites", forKey: selectedSectionKey)
            return true
        }

        let stationID: String?
        if url.host == "station" {
            stationID = url.pathComponents.dropFirst().first
        } else {
            let pathComponents = url.pathComponents.dropFirst()
            stationID = pathComponents.first == "station" ? pathComponents.dropFirst().first : nil
        }

        guard let stationID, Int64(stationID) != nil else {
            return false
        }

        UserDefaults.standard.set(stationID, forKey: pendingStationIDKey)
        return true
    }

    @MainActor
    static func updateShortcuts(favoriteStations: [RadioStation]) {
        var shortcutItems: [UIApplicationShortcutItem] = [
            UIApplicationShortcutItem(
                type: favoritesType,
                localizedTitle: appLocalized("Favorites"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "heart.fill"),
                userInfo: nil
            )
        ]

        shortcutItems += favoriteStations.prefix(3).map { station in
            UIApplicationShortcutItem(
                type: stationType(for: station.id),
                localizedTitle: station.name,
                localizedSubtitle: station.frequency.isEmpty ? station.region : "\(station.frequency) • \(station.region)",
                icon: UIApplicationShortcutIcon(systemImageName: "play.circle.fill"),
                userInfo: ["stationID": NSNumber(value: station.id)]
            )
        }

        UIApplication.shared.shortcutItems = shortcutItems
    }

    private static func stationType(for stationID: Int64) -> String {
        "\(stationTypePrefix)\(stationID)"
    }

    private static func shortcutType(_ suffix: String) -> String {
        "\(Bundle.main.bundleIdentifier ?? "GreekRadio").shortcut.\(suffix)"
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if #unavailable(iOS 26.0) {
            if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
                AppShortcut.handle(shortcutItem)
                return false
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        AppShortcut.handle(shortcutItem)
        completionHandler(true)
    }
}
