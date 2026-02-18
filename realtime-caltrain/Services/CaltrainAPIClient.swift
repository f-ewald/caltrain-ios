//
//  CaltrainAPIClient.swift
//  caltrain
//
//  Created by Claude Code on 1/28/26.
//

import Foundation

/// Protocol for fetching Caltrain data (enables testing with mocks)
protocol CaltrainAPIClientProtocol {
    func fetchTripUpdates() async throws -> GTFSRealtimeResponse
    func fetchStations() async throws -> StationData
    func healthcheck() async -> Bool
}

/// API client for fetching real-time Caltrain data from 511.org
struct CaltrainAPIClient: CaltrainAPIClientProtocol {
    private let baseURL = "https://caltrain-gateway.fewald.net/transit/tripupdates"

    /// Load agency ID from Config.plist (defaults to "CT")
    private func loadAgencyID() -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let agencyID = config["CaltrainAgencyID"] as? String else {
            return "CT"
        }
        return agencyID
    }

    /// Fetch trip updates for ALL Caltrain stations
    func fetchTripUpdates() async throws -> GTFSRealtimeResponse {
        // Build URL
        guard let url = buildURL(agencyID: loadAgencyID()) else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        // Log API url for debugging purposes
        print(String(format: "🌎 Loading from URL: %@", url.absoluteString))
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

    /// Fetch all Caltrain stations from the API
    func fetchStations() async throws -> StationData {
        let stationsURL = "https://caltrain-gateway.fewald.net/stations"

        guard let url = URL(string: stationsURL) else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print(String(format: "🌎 Loading stations from URL: %@", url.absoluteString))
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
            let stationData = try decoder.decode(StationData.self, from: data)
            return stationData
        } catch {
            throw APIError.parsingError(error)
        }
    }
    
    /// Perform healthcheck and return true if healthy
    func healthcheck() async -> Bool {
        let url = "https://caltrain-gateway.fewald.net/up"
        
        guard let healthUrl = URL(string: url) else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: healthUrl)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        }
        catch {
            return false
        }
    }

    /// Build URL with query parameters
    private func buildURL(agencyID: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "agency", value: agencyID),
            URLQueryItem(name: "format", value: "json")
        ]
        return components?.url
    }
    
    /// Fetch
    func fetchTimetable() async throws -> TimetableResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/caltrain/timetable"
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let timetableResponse = try decoder.decode(TimetableResponse.self, from: data)
            return timetableResponse
        } catch {
            throw APIError.parsingError(error)
        }
    }
}

// MARK: API Errors

/// API-specific errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case parsingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
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
