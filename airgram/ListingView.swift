import SwiftUI

struct ListingView: View {
    let listing: SupabaseManager.Listing
    @State private var aircraftInfo: Aircraft?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Image section
                AsyncImage(url: URL(string: listing.photoUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(maxHeight: 400)
                
                // Info section
                VStack(alignment: .leading, spacing: 16) {
                    // Header info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(listing.aircraftModel)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(listing.operator_)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Listing Details
                    VStack(alignment: .leading, spacing: 12) {
                        let registration = listing.registration.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !["unknown", "Unknown", "UNKNOWN", ""].contains(registration) {
                            DetailRow(label: "Registration", value: registration)
                        }
                        
                        if let livery = listing.livery {
                            DetailRow(label: "Livery", value: livery)
                        }
                        
                        let location = listing.location.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !["unknown", "Unknown", "UNKNOWN", ""].contains(location) {
                            DetailRow(label: "Location", value: location)
                        }
                    }
                    
                    // Aircraft Information
                    if let aircraft = aircraftInfo {
                        Divider()
                        
                        Group {
                            Text("Aircraft Information")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            DetailRow(label: "Manufacturer", value: aircraft.manufacturer)
                            DetailRow(label: "Category", value: aircraft.category)
                            
                            if let icao = aircraft.icaoCode {
                                DetailRow(label: "ICAO", value: icao)
                            }
                            if let iata = aircraft.iataCode {
                                DetailRow(label: "IATA", value: iata)
                            }
                            if let status = aircraft.status {
                                DetailRow(label: "Status", value: status)
                            }
                            
                            if let passengerCapacity = aircraft.passengerCapacity {
                                DetailRow(label: "Capacity", value: "\(passengerCapacity) passengers")
                            }
                            
                            if let description = aircraft.description {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "text.alignleft")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text(description)
                                        .font(.body)
                                }
                                .padding(.top, 8)
                            }
                            
                            if let firstFlight = aircraft.firstFlight {
                                DetailRow(label: "First Flight", value: firstFlight)
                            }
                            
                            // Technical specifications grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                if let maxSpeed = aircraft.max_speed_kmh {
                                    SpecificationView(label: "Max Speed", value: "\(maxSpeed) km/h")
                                }
                                if let range = aircraft.range_km {
                                    SpecificationView(label: "Range", value: "\(range) km")
                                }
                                if let mtow = aircraft.mtow_kg {
                                    SpecificationView(label: "MTOW", value: "\(mtow) kg")
                                }
                            }
                            .padding(.top, 8)
                            
                            if let wikiUrl = aircraft.wiki_url, let url = URL(string: wikiUrl) {
                                Link("Learn More", destination: url)
                                    .font(.footnote)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Timestamp
                    Text(listing.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .task {
            do {
                isLoading = true
                aircraftInfo = try await SupabaseManager.shared.fetchAircraftByModel(model: listing.aircraftModel)
            } catch {
                print("Failed to fetch aircraft info: \(error)")
            }
            isLoading = false
        }
    }
}

// Helper view for consistent detail rows
struct DetailRow: View {
    let label: String
    let value: String
    
    var icon: String {
        switch label {
        case "Registration": return "airplane"
        case "Livery": return "paintpalette"
        case "Location": return "mappin.circle"
        case "Manufacturer": return "briefcase"
        case "Category": return "tag"
        case "ICAO": return "globe"
        case "IATA": return "globe"
        case "Status": return "checkmark"
        case "Capacity": return "person.2"
        case "First Flight": return "calendar"
        default: return ""
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct SpecificationView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Preview provider
struct ListingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ListingView(listing: SupabaseManager.Listing(
                id: UUID(),
                photoUrl: "https://example.com/sample.jpg",
                aircraftModel: "Boeing 747-400",
                operator_: "Sample Airline",
                registration: "N123SA",
                livery: "Special Livery",
                location: "Sample Airport",
                createdAt: Date(),
                updatedAt: Date(),
                userId: UUID()
            ))
        }
    }
}
