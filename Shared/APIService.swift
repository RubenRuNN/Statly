//
//  APIService.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    private init() {}
    
    func fetchStats(config: WidgetConfiguration) async throws -> StatsResponse {
        guard let url = URL(string: config.endpointURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let statsResponse = try JSONDecoder().decode(StatsResponse.self, from: data)
            return statsResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func testEndpoint(url: String, apiKey: String) async throws -> StatsResponse {
        let tempConfig = WidgetConfiguration(
            endpointURL: url,
            apiKey: apiKey
        )
        return try await fetchStats(config: tempConfig)
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid endpoint URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Invalid data format from endpoint"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
