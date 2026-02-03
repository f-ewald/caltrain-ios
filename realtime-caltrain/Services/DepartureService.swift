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
    /// Fetches real-time departures from API and updates SwiftData for ALL stations
    static func refreshAllDepartures(
        allStations: [CaltrainStation],
        modelContext: ModelContext,
        forceRefresh: Bool = false
    ) async throws {
        // 1. Check global throttling (skip if <20s since last refresh)
        if !DepartureRefreshState.shouldRefresh(forceRefresh: forceRefresh) {
            #if DEBUG
            print("🕐 Departures refreshed recently, skipping")
            #endif
            return  // Silently skip - data is recent
        }

        #if DEBUG
        print("🔄 Refreshing departures for ALL stations (\(allStations.count) total)")
        #endif

        // 2. Fetch from API (gets all trips for all stations)
        let response = try await CaltrainAPIClient.fetchTripUpdates()

        // 3. Transform API response to TrainDeparture models for ALL stations
        let newDepartures = transformToTrainDepartures(
            response,
            allStations: allStations
        )

        #if DEBUG
        print("📦 Total departures collected: \(newDepartures.count) across \(allStations.count) stations")
        #endif

        var existingDepartures = Set<String>()
        for departure in newDepartures {
            let departureString = String(format: "%@_%@", departure.stationId, departure.trainNumber)
            if !existingDepartures.contains(departureString) {
                existingDepartures.insert(departureString)
//                print(String(format: "No duplicate detected: %@", departureString))
            } else {
                print(String(format: "Duplicate detected: %@", departureString))
            }
        }

        // 4. Replace ALL old departures with new ones (atomic operation)
        try replaceAllDepartures(with: newDepartures, modelContext: modelContext)

        // 5. Update global refresh timestamp
        DepartureRefreshState.markRefreshed()

        #if DEBUG
        print("✅ Refresh complete for all stations")
        #endif
    }

    /// Delete ALL old departures, insert ALL new ones (atomic replacement)
    private static func replaceAllDepartures(
        with newDepartures: [TrainDeparture],
        modelContext: ModelContext
    ) throws {
        // Delete ALL existing departures
        try modelContext.delete(model: TrainDeparture.self)


        // Insert ALL new departures
       for departure in newDepartures {
           modelContext.insert(departure)
       }
       try modelContext.save()

        #if DEBUG
        print("📦 Replaced all departures: \(newDepartures.count) total")
        #endif
    }

    /// Transform GTFS response to TrainDeparture models for ALL stations
    private static func transformToTrainDepartures(
        _ response: GTFSRealtimeResponse,
        allStations: [CaltrainStation]
    ) -> [TrainDeparture] {
        var departures: [TrainDeparture] = []

        // Create a lookup map: GTFS stop ID -> CaltrainStation
        var stopIdToStation: [String: CaltrainStation] = [:]
        for station in allStations {
            stopIdToStation[station.gtfsStopIdNorth] = station
            stopIdToStation[station.gtfsStopIdSouth] = station
        }

        #if DEBUG
        print("📊 Total entities in response: \(response.entities.count)")
        print("🗺️ Station lookup map created with \(stopIdToStation.count) GTFS stop IDs")
        #endif

        // Process all trip updates
        for entity in response.entities {
            guard let tripUpdate = entity.tripUpdate else { continue }

            // Process all stop updates for this trip
            for stopUpdate in tripUpdate.stopTimeUpdates {
                guard let stopId = stopUpdate.stopId,
                      let station = stopIdToStation[stopId],
                      let departure = stopUpdate.departure,
                      let departureTime = departure.time else {
                    continue
                }

                let estimatedTime = Date(timeIntervalSince1970: TimeInterval(departureTime))

                // Build TrainDeparture model
                // IMPORTANT: Use friendly station ID (e.g., "lawrence") not GTFS ID (e.g., "70231")
                // so that SwiftData queries can find these departures
                let trainDeparture = TrainDeparture(
                    stationId: station.stationId,  // Use friendly ID for database queries
                    direction: (stopId == station.gtfsStopIdNorth) ? .northbound : .southbound,
                    destinationName: (stopId == station.gtfsStopIdNorth) ? "San Francisco" : "San Jose",
                    scheduledTime: estimatedTime,  // Use same time as estimated (no scheduled data available)
                    estimatedTime: estimatedTime,
                    trainNumber: extractTrainNumber(from: tripUpdate.trip.tripId),
                    trainType: inferTrainType(from: tripUpdate.trip),
                    status: .onTime,  // No delay data available in API
                    platformNumber: nil  // Not provided in API response
                )

                departures.append(trainDeparture)
            }
        }

        #if DEBUG
        print("✅ Transformed \(departures.count) departures for \(allStations.count) stations")
        // Print breakdown by station for debugging
        let departuresByStation = Dictionary(grouping: departures, by: { $0.stationId })
        for (stationId, stationDepartures) in departuresByStation.sorted(by: { $0.key < $1.key }) {
            print("   \(stationId): \(stationDepartures.count) departures")
        }
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
