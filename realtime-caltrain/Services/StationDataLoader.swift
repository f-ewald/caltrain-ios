//
//  StationDataLoader.swift
//  realtime-caltrain
//
//  Created by Claude Code on 1/27/26.
//

import Foundation
import SwiftData

struct StationDataLoader {
    static func loadStationsIfNeeded(modelContext: ModelContext) {
        // Check if stations already loaded
        let descriptor = FetchDescriptor<CaltrainStation>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else {
            #if DEBUG
            print("✅ Stations already loaded: \(existingCount)")

            // Verify first station has GTFS IDs (schema migration check)
            if let firstStation = try? modelContext.fetch(descriptor).first {
                if firstStation.gtfsStopIdNorth.isEmpty {
                    print("⚠️ CRITICAL: Stations missing GTFS IDs - schema migration needed!")
                    print("💡 Please reset simulator: xcrun simctl erase all")
                } else {
                    print("✅ Stations have GTFS IDs: \(firstStation.gtfsStopIdNorth)")
                }
            }
            #endif
            return
        }

        #if DEBUG
        print("📥 Loading stations from JSON...")
        #endif

        // Load from JSON
        guard let url = Bundle.main.url(forResource: "caltrain_stations", withExtension: "json") else {
            #if DEBUG
            print("❌ ERROR: caltrain_stations.json not found in bundle")
            print("📦 Bundle path: \(Bundle.main.bundlePath)")
            #endif
            return
        }

        #if DEBUG
        print("✅ Found caltrain_stations.json at: \(url.path)")
        #endif

        do {
            let data = try Data(contentsOf: url)
            #if DEBUG
            print("📄 JSON file size: \(data.count) bytes")
            #endif

            let stationData = try JSONDecoder().decode(StationData.self, from: data)
            #if DEBUG
            print("🗺️ Decoded \(stationData.stations.count) stations from JSON")
            #endif

            // Import stations into SwiftData
            for station in stationData.stations {
                let newStation = CaltrainStation(
                    stationId: station.id,
                    name: station.name,
                    shortCode: station.shortCode,
                    gtfsStopIdSouth: station.gtfsStopIdSouth,
                    gtfsStopIdNorth: station.gtfsStopIdNorth,
                    latitude: station.latitude,
                    longitude: station.longitude,
                    zoneNumber: station.zone,
                    address: station.address,
                    hasParking: station.hasParking,
                    hasBikeParking: station.hasBikeParking,
                    parkingSpaces: station.parkingSpaces,
                    bikeRacks: station.bikeRacks,
                    hasBikeLockers: station.hasBikeLockers,
                    hasRestrooms: station.hasRestrooms,
                    ticketMachines: station.ticketMachines,
                    hasElevator: station.hasElevator
                )
                modelContext.insert(newStation)
            }

            try modelContext.save()
            #if DEBUG
            print("✅ Successfully loaded \(stationData.stations.count) stations into SwiftData")
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
    let zone: Int?
    let address: String?
    let hasParking: Bool
    let hasBikeParking: Bool
    let parkingSpaces: Int?
    let bikeRacks: Int?
    let hasBikeLockers: Bool
    let hasRestrooms: Bool
    let ticketMachines: Int?
    let hasElevator: Bool
}
