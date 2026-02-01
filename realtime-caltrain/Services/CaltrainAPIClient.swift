//
//  CaltrainAPIClient.swift
//  realtime-caltrain
//
//  Created by Claude Code on 1/28/26.
//

import Foundation

/// API client for fetching real-time Caltrain data from 511.org
struct CaltrainAPIClient {
    private static let baseURL = "https://caltrain-gateway.fewald.net/transit/tripupdates"

    /// Load agency ID from Config.plist (defaults to "CT")
    private static func loadAgencyID() -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let agencyID = config["CaltrainAgencyID"] as? String else {
            return "CT"
        }
        return agencyID
    }

    /// Fetch trip updates for specific station (or all if stationId is nil)
    static func fetchTripUpdates(for stationId: String? = nil) async throws -> GTFSRealtimeResponse {
        // Build URL
        guard let url = buildURL(agencyID: loadAgencyID()) else {
            throw APIError.invalidResponse
        }
        
        #if DEBUG
        // Log API url for debugging purposes
        print(String(format: "Loading from URL: %@", url.absoluteString))
        #endif

        // Make request
        let (data, response) = try await URLSession.shared.data(from: url)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        // Parse JSON
        do {
            let decoder = JSONDecoder()
            let gtfsResponse = try decoder.decode(GTFSRealtimeResponse.self, from: data)
            return gtfsResponse
        } catch {
            throw APIError.parsingError(error)
        }
    }

    /// Build URL with query parameters
    private static func buildURL(agencyID: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "agency", value: agencyID),
            URLQueryItem(name: "format", value: "json")
        ]
        return components?.url
    }
}

/// API-specific errors
enum APIError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case parsingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API key not configured. Please add your API key to Config.plist."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .parsingError(let error):
            return "Unable to parse departure data: \(error.localizedDescription)"
        }
    }
}
