//
//  DepartureService.swift
//  realtime-caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import Foundation
import SwiftData

struct DepartureService {
    /// Generates mock departure data for a given station
    static func generateMockDepartures(for stationId: String) -> [TrainDeparture] {
        var departures: [TrainDeparture] = []
        let now = Date()

        // Northbound trains (to San Francisco)
        let northboundTrainTypes: [TrainType] = [.local, .limited, .babyBullet, .limited, .local]
        for i in 0..<5 {
            let scheduledTime = now.addingTimeInterval(TimeInterval(i * 900)) // 15-minute intervals
            let estimatedTime = (i == 1) ? scheduledTime.addingTimeInterval(180) : nil // Second train delayed by 3 min
            let status: DepartureStatus = (i == 1) ? .delayed : .onTime

            let departure = TrainDeparture(
                departureId: "NB-\(stationId)-\(i)",
                stationId: stationId,
                direction: .northbound,
                destinationName: "San Francisco",
                scheduledTime: scheduledTime,
                estimatedTime: estimatedTime,
                trainNumber: String(151 + i),
                trainType: northboundTrainTypes[i],
                status: status,
                platformNumber: "2"
            )
            departures.append(departure)
        }

        // Southbound trains (to San Jose/Gilroy)
        let southboundTrainTypes: [TrainType] = [.limited, .local, .babyBullet, .local, .limited]
        let southboundDestinations = ["San Jose", "San Jose", "Gilroy", "San Jose", "San Jose"]
        for i in 0..<5 {
            let scheduledTime = now.addingTimeInterval(TimeInterval(i * 900 + 420)) // Offset by 7 minutes

            let departure = TrainDeparture(
                departureId: "SB-\(stationId)-\(i)",
                stationId: stationId,
                direction: .southbound,
                destinationName: southboundDestinations[i],
                scheduledTime: scheduledTime,
                estimatedTime: nil,
                trainNumber: String(221 + i),
                trainType: southboundTrainTypes[i],
                status: .onTime,
                platformNumber: "1"
            )
            departures.append(departure)
        }

        return departures
    }

    /// Loads mock departures for a station if none exist in the database
    static func loadMockDeparturesIfNeeded(for station: CaltrainStation?, modelContext: ModelContext) {
        guard let station = station else { return }

        // Check if departures already exist for this station
        let stationId = station.stationId
        let descriptor = FetchDescriptor<TrainDeparture>(
            predicate: #Predicate { $0.stationId == stationId }
        )

        do {
            let existingDepartures = try modelContext.fetch(descriptor)
            if existingDepartures.isEmpty {
                // Generate and insert mock departures
                let mockDepartures = generateMockDepartures(for: station.stationId)
                for departure in mockDepartures {
                    modelContext.insert(departure)
                }
            }
        } catch {
            #if DEBUG
            print("Failed to fetch or insert departures: \(error)")
            #endif
        }
    }

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
            gtfsStopId: station.gtfsStopIdNorth,
            friendlyStationId: station.stationId
        ))
        newDepartures.append(contentsOf: transformToTrainDepartures(
            response,
            gtfsStopId: station.gtfsStopIdSouth,
            friendlyStationId: station.stationId
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
        gtfsStopId: String,
        friendlyStationId: String
    ) -> [TrainDeparture] {
        var departures: [TrainDeparture] = []

        #if DEBUG
        print("🔄 Transforming departures for GTFS stop ID: \(gtfsStopId) (friendly ID: \(friendlyStationId))")
        print("📊 Total entities in response: \(response.entities.count)")
        #endif

        for entity in response.entities {
            guard let tripUpdate = entity.tripUpdate else { continue }

            // Filter to departures from this station only
            for stopUpdate in tripUpdate.stopTimeUpdates {
                #if DEBUG
                // Check if this stop matches our station
                if stopUpdate.stopId == gtfsStopId {
                    print("✅ Found matching stop: \(gtfsStopId) for trip \(tripUpdate.trip.tripId)")
                }
                #endif

                guard stopUpdate.stopId == gtfsStopId,
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
                    stationId: friendlyStationId,  // Use friendly ID for database queries
                    direction: inferDirection(from: tripUpdate.trip.directionId),
                    destinationName: inferDestinationName(from: tripUpdate.trip),
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
        print("✅ Transformed \(departures.count) departures for GTFS stop \(gtfsStopId)")
        #endif
        return departures
    }

    // MARK: - Helper Methods

    /// Infer direction from GTFS direction_id
    private static func inferDirection(from directionId: Int?) -> Direction {
        // GTFS convention: 0 = one direction, 1 = opposite
        // For Caltrain: 0 = southbound, 1 = northbound
        return (directionId == 1) ? .northbound : .southbound
    }

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
            return .babyBullet
        } else if routeIdUpper.contains("LIMITED") {
            return .limited
        }
        return .local  // Default for "Local Weekday" and others
    }
}
