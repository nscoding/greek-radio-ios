//
//  Greek_RadioApp.swift
//  Greek Radio
//
//  Created by Patrik Tomas Chamelo on 5/4/26.
//

import SwiftUI
import SwiftData

@main
struct Greek_RadioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppLanguage.userDefaultsKey) private var selectedAppLanguageCode = AppLanguage.english.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(selectedAppLanguageCode)
                .environment(\.locale, AppLanguage(rawValue: selectedAppLanguageCode)?.locale ?? AppLanguage.english.locale)
        }
        .modelContainer(for: [FavoriteStation.self])
    }
}
