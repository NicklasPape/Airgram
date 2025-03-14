import Foundation
import Supabase
import Functions
import Realtime
import UIKit
import Combine

class SupabaseManager {
    static let shared = SupabaseManager()
    internal let client: SupabaseClient
    private let bucketId = "photos"
    
    private init() {
        // TODO: Replace with your Supabase project URL and anon key
        let supabaseURL = URL(string: "https://liyonlcpyewmrcffmqgw.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpeW9ubGNweWV3bXJjZmZtcWd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4OTI3ODIsImV4cCI6MjA1NzQ2ODc4Mn0.DoGZiaMY6crYDJF6w9-sNfAjWO7FQyoJUvKlp4cON0M"
        
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
    
    func uploadImage(_ imageData: Data) async throws -> (URL, OpenAIManager.AircraftAnalysis) {
        print("🚀 Starting image upload process...")
        
        let fileName = "\(UUID().uuidString).jpg"
        print("📝 Generated file path: \(fileName)")
        
        do {
            print("📤 Uploading image to storage...")
            try await client.storage
                .from(bucketId)
                .upload(
                    path: fileName,
                    file: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )
            print("✅ Image upload successful")
            
            print("🔗 Getting public URL...")
            let publicURL = try await client.storage
                .from(bucketId)
                .getPublicURL(path: fileName)
            print("✅ Got public URL: \(publicURL)")
            
            // Get the analysis
            print("🔍 Analyzing image...")
            let analysis = try await OpenAIManager.shared.analyzeImage(imageData)
            print("✅ Image analysis complete")
            
            return (publicURL, analysis)
        } catch {
            print("❌ Upload error: \(error)")
            print("❌ Error details: \(String(describing: error))")
            throw error
        }
    }
    
    struct Listing: Codable, Identifiable {
        let id: UUID
        let photoUrl: String
        let aircraftModel: String
        let operator_: String
        let registration: String
        let livery: String?
        let location: String
        let createdAt: Date
        let updatedAt: Date
        let userId: UUID?
        
        enum CodingKeys: String, CodingKey {
            case id
            case photoUrl = "photo_url"
            case aircraftModel = "aircraft_model"
            case operator_ = "operator"
            case registration
            case livery
            case location
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case userId = "user_id"
        }
    }
    
    struct CreateListingRequest: Encodable {
        let photoUrl: String
        let aircraftModel: String
        let operator_: String
        let registration: String
        let livery: String?
        let location: String
        
        enum CodingKeys: String, CodingKey {
            case photoUrl = "photo_url"
            case aircraftModel = "aircraft_model"
            case operator_ = "operator"
            case registration
            case livery
            case location
        }
    }
    
    struct UpdateListingRequest: Encodable {
        var photoUrl: String?
        var aircraftModel: String?
        var operator_: String?
        var registration: String?
        var livery: String?
        var location: String?
        
        enum CodingKeys: String, CodingKey {
            case photoUrl = "photo_url"
            case aircraftModel = "aircraft_model"
            case operator_ = "operator"
            case registration
            case livery
            case location
        }
    }
    
    func createListing(_ listing: CreateListingRequest) async throws -> Listing {
        print("🚀 Creating new listing...")
        let response: Listing = try await client.database
            .from("listings")
            .insert(listing)
            .select()
            .single()
            .execute()
            .value
        
        print("✅ Listing created successfully")
        return response
    }
    
    func fetchListings() async throws -> [Listing] {
        print("📥 Fetching listings...")
        let response: [Listing] = try await client.database
            .from("listings")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ Fetched \(response.count) listings")
        return response
    }
    
    func updateListing(id: UUID, updates: UpdateListingRequest) async throws -> Listing {
        print("🔄 Updating listing...")
        let response: Listing = try await client.database
            .from("listings")
            .update(updates)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        print("✅ Listing updated successfully")
        return response
    }
    
    func deleteListing(id: UUID) async throws {
        print("🗑 Deleting listing...")
        try await client.database
            .from("listings")
            .delete()
            .eq("id", value: id)
            .execute()
        
        print("✅ Listing deleted successfully")
    }
    
    private struct SecretRecord: Codable {
        let key: String
        let value: String
    }
    
    func getSecret(_ key: String) async throws -> String? {
        let result: [SecretRecord] = try await client.database
            .from("secrets")
            .select()
            .eq("key", value: key)
            .execute()
            .value
        
        return result.first?.value
    }
    
    func fetchAircraftByModel(model: String) async throws -> Aircraft? {
        print("🔍 Fetching aircraft with model: \(model)")
        
        // Split the input into manufacturer and model if possible
        let components = model.split(separator: " ", maxSplits: 1).map(String.init)
        let manufacturer = components.first ?? ""
        let modelNumber = components.count > 1 ? components[1] : model
        
        let response: [Aircraft] = try await client.database
            .from("aircrafts")
            .select()
            .or("model.ilike.%\(modelNumber)%,manufacturer.ilike.%\(manufacturer)%")
            .execute()
            .value
        
        print("📊 Response received: \(response.count) matches")
        if response.isEmpty {
            print("⚠️ No aircraft found for model: \(model)")
        } else {
            print("✅ Found aircraft: \(response.first?.manufacturer ?? "") \(response.first?.model ?? "")")
        }
        
        return response.first
    }
}
