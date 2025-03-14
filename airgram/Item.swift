//
//  Item.swift
//  airgram
//
//  Created by Nicklas Skov Pape on 26/02/2025.
//

import Foundation
import SwiftData

@Model
final class AirplanePost {
    var id: UUID
    var caption: String
    var location: String
    var timestamp: Date
    var imageURL: URL?
    var aircraftType: String
    var likes: Int
    
    init(caption: String, location: String, aircraftType: String, imageURL: URL? = nil) {
        self.id = UUID()
        self.caption = caption
        self.location = location
        self.timestamp = Date()
        self.imageURL = imageURL
        self.aircraftType = aircraftType
        self.likes = 0
    }
}
