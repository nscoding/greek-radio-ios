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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FavoriteStation.self])
    }
}
