//
//  Item.swift
//  Greek Radio
//
//  Created by Patrik Tomas Chamelo on 5/4/26.
//

import Foundation
import SwiftData

@Model
final class FavoriteStation {
    @Attribute(.unique) var stationID: Int64
    var createdAt: Date

    init(stationID: Int64, createdAt: Date = .now) {
        self.stationID = stationID
        self.createdAt = createdAt
    }
}
