//
//  DepartureService.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import Foundation
import SwiftData

struct DepartureService {
    // MARK: - API Integration

    /// Main refresh method called by UI
    /// Fetches real-time departures from API and updates SwiftData
    static func refreshDepartures(
        for station: CaltrainStation,
        modelContext: ModelContext,
        forceRefresh: Bool = false
    ) async throws {
        // 1. Check throttling (skip if <20s since last refresh)
        if !forceRefresh && !shouldRefresh(station) {
            return  // Silently skip - data is recent
        }

        #if DEBUG
        print("🔄 Refreshing departures for station: \(station.name) (ID: \(station.stationId))")
        print("   North GTFS ID: \(station.gtfsStopIdNorth)")
        print("   South GTFS ID: \(station.gtfsStopIdSouth)")
        #endif

        // 2. Fetch from API (gets all trips, we'll filter by station)
        let response = try await CaltrainAPIClient.fetchTripUpdates()

        // 3. Transform API response to TrainDeparture models
        // Fetch departures for both northbound and southbound platforms
        var newDepartures: [TrainDeparture] = []
        newDepartures.append(contentsOf: transformToTrainDepartures(
            response,
            station: station
        ))

        #if DEBUG
        print("📦 Total departures collected: \(newDepartures.count)")
        #endif

        // 4. Replace old departures in database (use stationId, not GTFS IDs)
        try replaceDepartures(for: station.stationId, with: newDepartures, modelContext: modelContext)

        // 5. Update last refresh timestamp
        station.lastRefreshed = Date()
        try modelContext.save()

        #if DEBUG
        print("✅ Refresh complete for \(station.name)")
        #endif
    }

    /// Check if refresh is allowed (>20s since last)
    private static func shouldRefresh(_ station: CaltrainStation) -> Bool {
        guard let lastRefresh = station.lastRefreshed else {
            return true  // Never refreshed
        }
        return Date().timeIntervalSince(lastRefresh) >= 20
    }

    /// Delete old departures, insert new ones
    private static func replaceDepartures(
        for stationId: String,
        with newDepartures: [TrainDeparture],
        modelContext: ModelContext
    ) throws {
        // Delete existing departures for this station
        let stationIdValue = stationId
        let descriptor = FetchDescriptor<TrainDeparture>(
            predicate: #Predicate { $0.stationId == stationIdValue }
        )
        let existing = try modelContext.fetch(descriptor)
        for departure in existing {
            modelContext.delete(departure)
        }

        // Insert new departures
        for departure in newDepartures {
            modelContext.insert(departure)
        }
    }

    /// Transform GTFS response to TrainDeparture models
    private static func transformToTrainDepartures(
        _ response: GTFSRealtimeResponse,
        station: CaltrainStation,
    ) -> [TrainDeparture] {
        var departures: [TrainDeparture] = []

        #if DEBUG
        print("🔄 Transforming departures for GTFS stop IDs: \(station.gtfsStopIdNorth) \(station.gtfsStopIdSouth) (friendly ID: \(station.stationId))")
        print("📊 Total entities in response: \(response.entities.count)")
        #endif

        for entity in response.entities {
            guard let tripUpdate = entity.tripUpdate else { continue }

            // Filter to departures from this station only
            for stopUpdate in tripUpdate.stopTimeUpdates {
                #if DEBUG
                // Check if this stop matches our station
                if stopUpdate.stopId == station.gtfsStopIdNorth {
                    print("✅ Found matching NORTH stop: \(station.gtfsStopIdNorth) [\(station.name)] for trip \(tripUpdate.trip.tripId)")
                } else if stopUpdate.stopId == station.gtfsStopIdSouth {
                    print("✅ Found matching SOUTH stop: \(station.gtfsStopIdSouth) [\(station.name)] for trip \(tripUpdate.trip.tripId)")
                }
                #endif

                guard station.stopIds.contains(stopUpdate.stopId!),
                      let departure = stopUpdate.departure,
                      let departureTime = departure.time else {
                    continue
                }

                let estimatedTime = Date(timeIntervalSince1970: TimeInterval(departureTime))

                // Build TrainDeparture model
                // IMPORTANT: Use friendly station ID (e.g., "lawrence") not GTFS ID (e.g., "70231")
                // so that SwiftData queries can find these departures
                let trainDeparture = TrainDeparture(
                    departureId: "\(tripUpdate.trip.tripId)_\(stopUpdate.stopSequence ?? 0)",
                    stationId: station.stationId,  // Use friendly ID for database queries
                    direction: (stopUpdate.stopId == station.gtfsStopIdNorth) ? .northbound : .southbound,
                    destinationName: (stopUpdate.stopId == station.gtfsStopIdNorth) ? "San Francisco" : "San Jose",
                    scheduledTime: estimatedTime,  // Use same time as estimated (no scheduled data available)
                    estimatedTime: estimatedTime,
                    trainNumber: extractTrainNumber(from: tripUpdate.trip.tripId),
                    trainType: inferTrainType(from: tripUpdate.trip),
                    status: .onTime,  // No delay data available in API
                    platformNumber: nil  // Not provided in API response
                )

                #if DEBUG
                print("🚂 Created departure: Train \(trainDeparture.trainNumber) to \(trainDeparture.destinationName) at \(estimatedTime)")
                #endif
                departures.append(trainDeparture)
            }
        }

        #if DEBUG
        print("✅ Transformed \(departures.count) departures for GTFS stop \(station.gtfsStopIdNorth) and \(station.gtfsStopIdSouth)")
        #endif
        return departures
    }

    // MARK: - Helper Methods

    /// Infer destination name from trip data
    private static func inferDestinationName(from trip: Trip) -> String {
        // Use direction to provide generic destination
        // In a production app, would load GTFS static data for accurate destinations
        if trip.directionId == 1 {
            return "San Francisco"
        } else {
            // Check route to determine if it goes to Gilroy or San Jose
            if let routeId = trip.routeId, routeId.uppercased().contains("GILROY") {
                return "Gilroy"
            }
            return "San Jose"
        }
    }

    /// Extract train number from trip ID
    private static func extractTrainNumber(from tripId: String) -> String {
        // 511.org uses trip ID as train number (e.g., "114", "412", "511")
        return tripId
    }

    /// Infer train type from route ID
    private static func inferTrainType(from trip: Trip) -> TrainType {
        // 511.org uses RouteId like "Local Weekday", "Limited", "Express"
        guard let routeId = trip.routeId else {
            return .local  // Default
        }

        let routeIdUpper = routeId.uppercased()
        if routeIdUpper.contains("EXPRESS") || routeIdUpper.contains("BULLET") {
            return .express
        } else if routeIdUpper.contains("LIMITED") {
            return .limited
        }
        return .local  // Default for "Local Weekday" and others
    }
}
