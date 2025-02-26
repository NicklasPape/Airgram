//
//  Item.swift
//  airgram
//
//  Created by Nicklas Skov Pape on 26/02/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
