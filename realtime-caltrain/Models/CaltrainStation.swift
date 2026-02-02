//
//  CaltrainStation.swift
//  realtime-caltrain
//
//  Created by Claude Code on 1/27/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class CaltrainStation {
    var stationId: String        // e.g., "sf", "millbrae"
    var name: String             // e.g., "San Francisco"
    var shortCode: String        // e.g., "SF", "MTV"
    var gtfsStopIdSouth: String  // GTFS stop ID for southbound platform
    var gtfsStopIdNorth: String  // GTFS stop ID for northbound platform
    var latitude: Double
    var longitude: Double
    var zoneNumber: Int?         // Fare zone (1-6)
    var address: String?
    var hasParking: Bool
    var hasBikeParking: Bool

    // Detailed amenities
    var parkingSpaces: Int?
    var bikeRacks: Int?
    var hasBikeLockers: Bool
    var hasRestrooms: Bool
    var ticketMachines: Int?
    var hasElevator: Bool

    var isFavorite: Bool         // User's favorite status
    var isSelected: Bool         // User's selected station status
    var lastRefreshed: Date?     // Timestamp of last API refresh (for throttling)

    // Computed property for CLLocation
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// A set containing both stop ids for easier comparison.
    var stopIds: Set<String> {
        Set([gtfsStopIdNorth, gtfsStopIdSouth])
    }

    init(stationId: String, name: String, shortCode: String, gtfsStopIdSouth: String, gtfsStopIdNorth: String,
         latitude: Double, longitude: Double,
         zoneNumber: Int? = nil, address: String? = nil,
         hasParking: Bool = false, hasBikeParking: Bool = false,
         parkingSpaces: Int? = nil, bikeRacks: Int? = nil,
         hasBikeLockers: Bool = false, hasRestrooms: Bool = false,
         ticketMachines: Int? = nil, hasElevator: Bool = false,
         isFavorite: Bool = false, isSelected: Bool = false,
         lastRefreshed: Date? = nil) {
        self.stationId = stationId
        self.name = name
        self.shortCode = shortCode
        self.gtfsStopIdSouth = gtfsStopIdSouth
        self.gtfsStopIdNorth = gtfsStopIdNorth
        self.latitude = latitude
        self.longitude = longitude
        self.zoneNumber = zoneNumber
        self.address = address
        self.hasParking = hasParking
        self.hasBikeParking = hasBikeParking
        self.parkingSpaces = parkingSpaces
        self.bikeRacks = bikeRacks
        self.hasBikeLockers = hasBikeLockers
        self.hasRestrooms = hasRestrooms
        self.ticketMachines = ticketMachines
        self.hasElevator = hasElevator
        self.isFavorite = isFavorite
        self.isSelected = isSelected
        self.lastRefreshed = lastRefreshed
    }
}
