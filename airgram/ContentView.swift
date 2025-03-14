//
//  ContentView.swift
//  airgram
//
//  Created by Nicklas Skov Pape on 26/02/2025.
//

import SwiftUI
import PhotosUI
import ImageIO
import CoreLocation

struct ContentView: View {
    @State private var listings: [SupabaseManager.Listing] = []
    @State private var selectedImage: PhotosPickerItem?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(listings) { listing in
                        NavigationLink(destination: ListingView(listing: listing)) {
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: URL(string: listing.photoUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .clipped()
                                
                                Text(listing.aircraftModel)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(listing.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            .navigationTitle("Airgram")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images
                    ) {
                        Label("New Post", systemImage: "camera")
                    }
                }
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let newValue {
                    handleImageSelection(newValue)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await loadPosts()
        }
    }

    private func loadPosts() async {
        do {
            listings = try await SupabaseManager.shared.fetchListings()
        } catch {
            showError = true
            errorMessage = "Failed to load listings: \(error.localizedDescription)"
        }
    }

    private func handleImageSelection(_ item: PhotosPickerItem) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                guard let imageData = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                }
                
                // Get image location from metadata using ImageIO
                var location = "Unknown Location"
                if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                   let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
                   let gpsInfo = metadata["{GPS}"] as? [String: Any],
                   let latitude = gpsInfo["Latitude"] as? Double,
                   let longitude = gpsInfo["Longitude"] as? Double {
                    
                    // Adjust for latitude/longitude reference
                    let adjustedLatitude = (gpsInfo["LatitudeRef"] as? String == "S") ? -latitude : latitude
                    let adjustedLongitude = (gpsInfo["LongitudeRef"] as? String == "W") ? -longitude : longitude
                    
                    let locationManager = CLGeocoder()
                    if let placemark = try? await locationManager.reverseGeocodeLocation(
                        CLLocation(latitude: adjustedLatitude, longitude: adjustedLongitude)
                    ).first {
                        let components = [placemark.locality, placemark.administrativeArea, placemark.country].compactMap { $0 }
                        location = components.joined(separator: ", ")
                    }
                }
                
                let (imageURL, analysis) = try await SupabaseManager.shared.uploadImage(imageData)
                
                // Only create listing if we have at least one piece of information
                if analysis.aircraftModel != nil || analysis.operator_ != nil ||
                   analysis.registration != nil || analysis.livery != nil {
                    
                    let newListing = SupabaseManager.CreateListingRequest(
                        photoUrl: imageURL.absoluteString,
                        aircraftModel: analysis.aircraftModel ?? "",  // Use empty string if nil
                        operator_: analysis.operator_ ?? "",          // Use empty string if nil
                        registration: analysis.registration ?? "",    // Use empty string if nil
                        livery: analysis.livery,                      // Already optional
                        location: location
                    )
                    
                    let listing = try await SupabaseManager.shared.createListing(newListing)
                    listings.insert(listing, at: 0)
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No aircraft information could be identified in the image"])
                }
                
            } catch {
                showError = true
                errorMessage = "Failed to create listing: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ContentView()
}
