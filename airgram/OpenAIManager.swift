//
//  ContentView.swift
//  airgram
//
//  Created by Nicklas Skov Pape on 26/02/2025.
//

import SwiftUI
import SwiftData
import PhotosUI
import ImageIO
import CoreLocation

class OpenAIManager {
    static let shared = OpenAIManager()
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let apiKey = "" // Replace with your actual OpenAI key
    
    private init() {}
    
    struct AircraftAnalysis {
        let aircraftModel: String?
        let operator_: String?
        let registration: String?
        let livery: String?
    }
    
    func analyzeImage(_ imageData: Data) async throws -> AircraftAnalysis {
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful AI that can analyze aircraft images."
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Analyze this aircraft image and provide these details ONLY in this format - Aircraft Model: [model], Operator: [operator], Registration: [registration], Livery: [livery description or 'Standard']. ONLY include fields where you can clearly see and identify the information. Do not include fields where you're unsure or cannot see the information."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Debug print the response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw OpenAI Response: \(jsonString)")
        }
        
        // Try to decode error response first
        if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
            throw NSError(
                domain: "OpenAIError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message]
            )
        }
        
        // If no error, decode the success response
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response content"])
        }
        
        return parseAnalysisResponse(content)
    }
    
    private func parseAnalysisResponse(_ content: String) -> AircraftAnalysis {
        var model: String? = nil
        var operator_: String? = nil
        var registration: String? = nil
        var livery: String? = nil
        
        if let modelMatch = content.range(of: "Aircraft Model: ([^,\n]+)", options: .regularExpression) {
            let value = String(content[modelMatch].dropFirst(15)).trimmingCharacters(in: .whitespaces)
            if !value.isEmpty { model = value }
        }
        
        if let operatorMatch = content.range(of: "Operator: ([^,\n]+)", options: .regularExpression) {
            let value = String(content[operatorMatch].dropFirst(10)).trimmingCharacters(in: .whitespaces)
            if !value.isEmpty { operator_ = value }
        }
        
        if let registrationMatch = content.range(of: "Registration: ([^,\n]+)", options: .regularExpression) {
            let value = String(content[registrationMatch].dropFirst(14)).trimmingCharacters(in: .whitespaces)
            if !value.isEmpty { registration = value }
        }
        
        if let liveryMatch = content.range(of: "Livery: ([^,\n]+)", options: .regularExpression) {
            let value = String(content[liveryMatch].dropFirst(8)).trimmingCharacters(in: .whitespaces)
            if !value.isEmpty && value.lowercased() != "standard" { livery = value }
        }
        
        return AircraftAnalysis(
            aircraftModel: model,
            operator_: operator_,
            registration: registration,
            livery: livery
        )
    }
}

// Response structures
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let usage: Usage
    let choices: [Choice]
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct Choice: Codable {
    let message: Message
    let finishReason: String
    let index: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
        case index
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIErrorDetail
}

struct OpenAIErrorDetail: Codable {
    let message: String
    let type: String
    let param: String?
    let code: String
}
