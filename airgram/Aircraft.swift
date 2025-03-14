import Foundation

struct Aircraft: Codable, Identifiable {
    let id: UUID
    let manufacturer: String
    let model: String
    let category: String
    let passengerCapacity: Int?
    let range_km: Int?
    let max_speed_kmh: Int?
    let mtow_kg: Int?
    let firstFlight: String?
    let status: String?
    let description: String?
    let image_url: String?
    let wiki_url: String?
    let icaoCode: String?  // Updated property name
    let iataCode: String?  // Updated property name
    
    enum CodingKeys: String, CodingKey {
        case id
        case manufacturer
        case model
        case category
        case passengerCapacity = "passenger_capacity"
        case range_km
        case max_speed_kmh
        case mtow_kg
        case firstFlight = "first_flight"
        case status
        case description
        case image_url
        case wiki_url
        case icaoCode = "icao_code"  // Updated to match database column
        case iataCode = "iata_code"  // Updated to match database column
    }
}
