//
//  StationService.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/8/26.
//

import SwiftData
import _LocationEssentials

struct StationService {
    let apiClient: CaltrainAPIClientProtocol

    init(apiClient: CaltrainAPIClientProtocol = CaltrainAPIClient()) {
        self.apiClient = apiClient
    }
    /// All stations in alphabetical order
    func allStations(modelContext: ModelContext) -> [CaltrainStation] {
        let descriptor = FetchDescriptor<CaltrainStation>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// All stations ordered by distance to a location
    func closestStations(modelContext: ModelContext, to userLocation: CLLocation) -> [CaltrainStation] {
        let descriptor = FetchDescriptor<CaltrainStation>()
        
        guard let stations = try? modelContext.fetch(descriptor) else { return [] }
        
        return stations.sorted {
            let dist1 = $0.location.distance(from: userLocation)
            let dist2 = $1.location.distance(from: userLocation)
            return dist1 < dist2
        }
    }
    
    /// Refreshes stations from the API and syncs with the database.
    /// - Updates existing stations with new data (preserves user preferences)
    /// - Adds new stations that don't exist in the database
    /// - Removes stations that no longer exist in the API
    func refreshStations(modelContext: ModelContext) async throws {
        #if DEBUG
        print("🔄 Refreshing stations from API...")
        #endif

        // Fetch stations from API
        let stationData = try await apiClient.fetchStations()

        #if DEBUG
        print("📡 Fetched \(stationData.stations.count) stations from API")
        #endif

        // Fetch existing stations from database
        let descriptor = FetchDescriptor<CaltrainStation>()
        let existingStations = try modelContext.fetch(descriptor)

        // Create a dictionary of existing stations by stationId for quick lookup
        var existingStationsDict: [String: CaltrainStation] = [:]
        for station in existingStations {
            existingStationsDict[station.stationId] = station
        }

        // Track which stations exist in the API
        var apiStationIds = Set<String>()

        // Update existing stations and add new ones
        for apiStation in stationData.stations {
            apiStationIds.insert(apiStation.id)

            if let existingStation = existingStationsDict[apiStation.id] {
                // Update existing station (preserve user preferences)
                existingStation.name = apiStation.name
                existingStation.shortCode = apiStation.shortCode
                existingStation.gtfsStopIdSouth = apiStation.gtfsStopIdSouth
                existingStation.gtfsStopIdNorth = apiStation.gtfsStopIdNorth
                existingStation.latitude = apiStation.latitude
                existingStation.longitude = apiStation.longitude
                existingStation.zoneNumber = apiStation.zone
                existingStation.address = apiStation.address
                existingStation.hasParking = apiStation.hasParking
                existingStation.hasBikeParking = apiStation.hasBikeParking
                existingStation.parkingSpaces = apiStation.parkingSpaces
                existingStation.bikeRacks = apiStation.bikeRacks
                existingStation.hasBikeLockers = apiStation.hasBikeLockers
                existingStation.hasRestrooms = apiStation.hasRestrooms
                existingStation.ticketMachines = apiStation.ticketMachines
                existingStation.hasElevator = apiStation.hasElevator
                // Note: isFavorite and isSelected are NOT updated (user preferences)

                #if DEBUG
                print("✏️ Updated station: \(apiStation.name)")
                #endif
            } else {
                // Add new station
                let newStation = CaltrainStation(
                    stationId: apiStation.id,
                    name: apiStation.name,
                    shortCode: apiStation.shortCode,
                    gtfsStopIdSouth: apiStation.gtfsStopIdSouth,
                    gtfsStopIdNorth: apiStation.gtfsStopIdNorth,
                    latitude: apiStation.latitude,
                    longitude: apiStation.longitude,
                    zoneNumber: apiStation.zone,
                    address: apiStation.address,
                    hasParking: apiStation.hasParking,
                    hasBikeParking: apiStation.hasBikeParking,
                    parkingSpaces: apiStation.parkingSpaces,
                    bikeRacks: apiStation.bikeRacks,
                    hasBikeLockers: apiStation.hasBikeLockers,
                    hasRestrooms: apiStation.hasRestrooms,
                    ticketMachines: apiStation.ticketMachines,
                    hasElevator: apiStation.hasElevator
                )
                modelContext.insert(newStation)

                #if DEBUG
                print("➕ Added new station: \(apiStation.name)")
                #endif
            }
        }

        // Remove stations that no longer exist in the API
        for existingStation in existingStations {
            if !apiStationIds.contains(existingStation.stationId) {
                #if DEBUG
                print("🗑️ Removing station: \(existingStation.name)")
                #endif
                modelContext.delete(existingStation)
            }
        }

        // Save all changes
        try modelContext.save()

        #if DEBUG
        print("✅ Successfully refreshed stations")
        #endif
    }
}
