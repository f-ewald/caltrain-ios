//
//  GTFSRealtimeModels.swift
//  caltrain
//
//  Created by Claude Code on 1/28/26.
//

import Foundation

/// Root response object for 511.org GTFS-Realtime trip updates
/// Uses PascalCase naming convention
struct GTFSRealtimeResponse: Codable {
    let entities: [FeedEntity]

    enum CodingKeys: String, CodingKey {
        case entities = "Entities"
    }
}

/// Individual feed entity containing trip update
struct FeedEntity: Codable {
    let id: String
    let tripUpdate: TripUpdate?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case tripUpdate = "TripUpdate"
    }
}

/// Trip update with associated trip and stop time updates
struct TripUpdate: Codable {
    let trip: Trip
    let stopTimeUpdates: [StopTimeUpdate]

    enum CodingKeys: String, CodingKey {
        case trip = "Trip"
        case stopTimeUpdates = "StopTimeUpdates"
    }
}

/// Trip information (route, direction)
struct Trip: Codable {
    let tripId: String
    let routeId: String?
    let directionId: Int?

    enum CodingKeys: String, CodingKey {
        case tripId = "TripId"
        case routeId = "RouteId"
        case directionId = "DirectionId"
    }
}

/// Stop time update with arrival/departure information
struct StopTimeUpdate: Codable {
    let stopSequence: Int?
    let stopId: String?
    let arrival: TimeEvent?
    let departure: TimeEvent?

    enum CodingKeys: String, CodingKey {
        case stopSequence = "StopSequence"
        case stopId = "StopId"
        case arrival = "Arrival"
        case departure = "Departure"
    }
}

/// Time event with timestamp (no delay field in 511.org API)
struct TimeEvent: Codable {
    let time: Int64?  // POSIX timestamp (real-time estimate)

    enum CodingKeys: String, CodingKey {
        case time = "Time"
    }
}
