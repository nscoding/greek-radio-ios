//
//  Item.swift
//  Greek Radio
//
//  Created by Patrik Tomas Chamelo on 5/4/26.
//

import Combine
import Foundation
import SwiftData

final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()
    @Published var stationIDs: Set<Int64> = []
    private init() {}
}

@Model
final class FavoriteStation {
    @Attribute(.unique) var stationID: Int64
    var createdAt: Date

    init(stationID: Int64, createdAt: Date = .now) {
        self.stationID = stationID
        self.createdAt = createdAt
    }
}
