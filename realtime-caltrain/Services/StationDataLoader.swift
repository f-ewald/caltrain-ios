//
//  StationDataLoader.swift
//  caltrain
//
//  Created by Claude Code on 1/27/26.
//

import Foundation
import SwiftData

struct StationDataLoader {
    static func loadStationsIfNeeded(modelContext: ModelContext) {
        #if DEBUG
        print("📥 Syncing stations from bundled JSON...")
        #endif

        // Load from JSON
        guard let url = Bundle.main.url(forResource: "caltrain_stations", withExtension: "json") else {
            #if DEBUG
            print("❌ ERROR: caltrain_stations.json not found in bundle")
            print("📦 Bundle path: \(Bundle.main.bundlePath)")
            #endif
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let stationData = try JSONDecoder().decode(StationData.self, from: data)

            #if DEBUG
            print("🗺️ Decoded \(stationData.stations.count) stations from JSON")
            #endif

            try syncStations(stationData.stations, modelContext: modelContext)

            #if DEBUG
            print("✅ Successfully synced stations from bundled JSON")
            #endif
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("❌ JSON DECODING ERROR: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Missing key: \(key.stringValue) - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   Type mismatch: \(type) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found: \(type) - \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   Unknown decoding error")
            }
            #endif
        } catch {
            #if DEBUG
            print("❌ ERROR loading stations: \(error)")
            #endif
        }
    }

    /// Syncs the given JSON stations into the database using upsert logic:
    /// - Updates existing stations (preserving user preferences like isFavorite, isSelected)
    /// - Inserts new stations
    /// - Deletes stations no longer present in the JSON
    static func syncStations(_ jsonStations: [StationJSON], modelContext: ModelContext) throws {
        // Fetch all existing stations into a lookup dictionary
        let descriptor = FetchDescriptor<CaltrainStation>()
        let existingStations = try modelContext.fetch(descriptor)
        var existingDict: [String: CaltrainStation] = [:]
        for station in existingStations {
            existingDict[station.stationId] = station
        }

        // Track which station IDs are in the JSON
        var jsonStationIds = Set<String>()

        for jsonStation in jsonStations {
            jsonStationIds.insert(jsonStation.id)

            if let existing = existingDict[jsonStation.id] {
                // Update data fields, preserve user preferences (isFavorite, isSelected)
                existing.name = jsonStation.name
                existing.shortCode = jsonStation.shortCode
                existing.gtfsStopIdSouth = jsonStation.gtfsStopIdSouth
                existing.gtfsStopIdNorth = jsonStation.gtfsStopIdNorth
                existing.latitude = jsonStation.latitude
                existing.longitude = jsonStation.longitude
                existing.zoneNumber = jsonStation.zone
                existing.address = jsonStation.address
                existing.addressNumber = jsonStation.addressNumber
                existing.addressStreet = jsonStation.addressStreet
                existing.addressCity = jsonStation.addressCity
                existing.addressPostalCode = jsonStation.addressPostalCode
                existing.addressState = jsonStation.addressState
                existing.addressCountry = jsonStation.addressCountry
                existing.hasParking = jsonStation.hasParking
                existing.hasBikeParking = jsonStation.hasBikeParking
                existing.parkingSpaces = jsonStation.parkingSpaces
                existing.bikeRacks = jsonStation.bikeRacks
                existing.hasBikeLockers = jsonStation.hasBikeLockers
                existing.hasRestrooms = jsonStation.hasRestrooms
                existing.ticketMachines = jsonStation.ticketMachines
                existing.hasElevator = jsonStation.hasElevator
            } else {
                // Insert new station
                let newStation = CaltrainStation(
                    stationId: jsonStation.id,
                    name: jsonStation.name,
                    shortCode: jsonStation.shortCode,
                    gtfsStopIdSouth: jsonStation.gtfsStopIdSouth,
                    gtfsStopIdNorth: jsonStation.gtfsStopIdNorth,
                    latitude: jsonStation.latitude,
                    longitude: jsonStation.longitude,
                    zoneNumber: jsonStation.zone,
                    address: jsonStation.address,
                    addressNumber: jsonStation.addressNumber,
                    addressStreet: jsonStation.addressStreet,
                    addressCity: jsonStation.addressCity,
                    addressPostalCode: jsonStation.addressPostalCode,
                    addressState: jsonStation.addressState,
                    addressCountry: jsonStation.addressCountry,
                    hasParking: jsonStation.hasParking,
                    hasBikeParking: jsonStation.hasBikeParking,
                    parkingSpaces: jsonStation.parkingSpaces,
                    bikeRacks: jsonStation.bikeRacks,
                    hasBikeLockers: jsonStation.hasBikeLockers,
                    hasRestrooms: jsonStation.hasRestrooms,
                    ticketMachines: jsonStation.ticketMachines,
                    hasElevator: jsonStation.hasElevator
                )
                modelContext.insert(newStation)
            }
        }

        // Delete stations that are no longer in the JSON
        for existing in existingStations {
            if !jsonStationIds.contains(existing.stationId) {
                modelContext.delete(existing)
            }
        }

        try modelContext.save()
    }
}

// Decodable structures for JSON parsing
struct StationData: Decodable {
    let stations: [StationJSON]
    let version: String
    let lastUpdated: String
}

struct StationJSON: Decodable {
    let id: String
    let name: String
    let shortCode: String
    let gtfsStopIdSouth: String
    let gtfsStopIdNorth: String
    let latitude: Double
    let longitude: Double
    let zone: Int
    let address: String?
    let addressNumber: String?
    let addressStreet: String?
    let addressCity: String?
    let addressPostalCode: String?
    let addressState: String?
    let addressCountry: String?
    let hasParking: Bool
    let hasBikeParking: Bool
    let parkingSpaces: Int?
    let bikeRacks: Int?
    let hasBikeLockers: Bool
    let hasRestrooms: Bool
    let ticketMachines: Int?
    let hasElevator: Bool
}
