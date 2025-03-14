import SwiftUI

struct ListingView: View {
    let listing: SupabaseManager.Listing
    
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
                        
                        Text(listing.operator_)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Registration", value: listing.registration)
                        
                        if let livery = listing.livery {
                            DetailRow(label: "Livery", value: livery)
                        }
                        
                        DetailRow(label: "Location", value: listing.location)
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
    }
}

// Helper view for consistent detail rows
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

// Preview provider
#Preview {
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
