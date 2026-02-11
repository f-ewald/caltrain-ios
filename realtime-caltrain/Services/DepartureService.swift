//
//  DepartureService.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import Foundation
import SwiftData
import WidgetKit

struct DepartureService {
    static func upcomingDepartures(modelContext: ModelContext, for station: CaltrainStation, at date: Date) -> [TrainDeparture] {
        // Extract Ids because they cannot be referenced in #Predicate
        let stationId = station.stationId
        let northId = station.gtfsStopIdNorth
        let southId = station.gtfsStopIdSouth
        
        
        // Fetch planned departures
        let plannedDescriptor = FetchDescriptor<PlannedDeparture>(
            predicate: #Predicate { $0.stationId == northId || $0.stationId == southId }
        )
        let plannedDepartures = (try? modelContext.fetch(plannedDescriptor)) ?? []
        
        // Fetch real-time departures
        let realtimeDescriptor = FetchDescriptor<TrainDeparture>(
            predicate: #Predicate { $0.stationId == stationId }
        )
        let realtimeDepartures = (try? modelContext.fetch(realtimeDescriptor)) ?? []

        // Create a set of train numbers from real-time departures for quick lookup
        let realtimeTrainNumbers = Set(realtimeDepartures.map { $0.trainNumber })

        // Convert planned departures to TrainDeparture, excluding duplicates
        let convertedPlanned = plannedDepartures.compactMap { planned -> TrainDeparture? in
            // Skip if we already have real-time data for this train
            guard !realtimeTrainNumbers.contains(planned.trainNumber) else { return nil }
            return planned.toTrainDeparture()
        }
        
        // Merge and sort by scheduled time
        let merged = realtimeDepartures + convertedPlanned
        
        let filtered = merged.filter {
            $0.departureTime >= date
        }
        
        let sorted = filtered.sorted { $0.scheduledTime < $1.scheduledTime }
        return sorted
    }
    
    
    // MARK: - API Integration

    /// Refresh all planned departures and store them to the database
    /// This method only needs to be called on first start and then infrequently because
    /// departures rarely change
    static func refreshPlannedDepartures(modelContext: ModelContext) async throws {
        let timetable = try await CaltrainAPIClient().fetchTimetable()
        
        for (stationId, departures) in timetable {
            for departure in departures {
                modelContext.insert(
                    PlannedDeparture(stationId: stationId,
                                     trainType: departure.trainType,
                                     trainNumber: departure.trainNumber,
                                     scheduledTime: departure.departureTime,
                                     destination: departure.destination)
                    )
            }
        }
    }

    /// Main refresh method called by UI
    /// Fetches real-time departures from API and updates SwiftData for ALL stations
    static func refreshAllDepartures(
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
        print("🔄 Refreshing departures for ALL stations")
        #endif

        // 2. Fetch from API (gets all trips for all stations)
        let response = try await CaltrainAPIClient().fetchTripUpdates()

        // 3. Transform API response to TrainDeparture models for ALL stations
        let newDepartures = transformToTrainDepartures(
            response,
            modelContext: modelContext
        )

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
        
        #if DEBUG
        print("Updating widget now")
        #endif
        // Updating widget with newest data upon fetch.
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Transform GTFS response to TrainDeparture models for ALL stations
    private static func transformToTrainDepartures(
        _ response: GTFSRealtimeResponse,
        modelContext: ModelContext
    ) -> [TrainDeparture] {
        let allStations = StationService().allStations(modelContext: modelContext)
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
                    shortDestinationName: (stopId == station.gtfsStopIdNorth) ? "SF" : "SJ",
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
