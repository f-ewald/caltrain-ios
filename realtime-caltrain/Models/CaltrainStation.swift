//
//  CaltrainStation.swift
//  caltrain
//
//  Created by Claude Code on 1/27/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class CaltrainStation {
    /// stationId is the unique identifier for a station
    @Attribute(.unique) var stationId: String        // e.g., "sf", "millbrae"
    var name: String             // e.g., "San Francisco"
    var shortCode: String        // e.g., "SF", "MTV"
    var gtfsStopIdSouth: String  // GTFS stop ID for southbound platform
    var gtfsStopIdNorth: String  // GTFS stop ID for northbound platform
    var latitude: Double
    var longitude: Double
    var zoneNumber: Int         // Fare zone (1-6)
    var address: String?
    var addressNumber: String?
    var addressStreet: String?
    var addressCity: String?
    var addressPostalCode: String?
    var addressState: String?
    var addressCountry: String?
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

    @available(*, deprecated, message: "lastRefreshed is no longer used. Global refresh state is managed by DepartureRefreshState.")
    var lastRefreshed: Date?     // Timestamp of last API refresh (DEPRECATED - use DepartureRefreshState instead)

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
         zoneNumber: Int, address: String? = nil,
         addressNumber: String? = nil,
         addressStreet: String? = nil,
         addressCity: String? = nil,
         addressPostalCode: String? = nil,
         addressState: String? = nil,
         addressCountry: String? = nil,
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
        self.addressNumber = addressNumber
        self.addressStreet = addressStreet
        self.addressCity = addressCity
        self.addressPostalCode = addressPostalCode
        self.addressState = addressState
        self.addressCountry = addressCountry
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
    }
    
    static var exampleStation = CaltrainStation(
        stationId: "sf",
        name: "San Francisco",
        shortCode: "sf",
        gtfsStopIdSouth: "1",
        gtfsStopIdNorth: "2",
        latitude: 37.776439,
        longitude: -122.394434,
        zoneNumber: 1,
        address: "700 4th St., San Francisco 94107",
        addressNumber: "700",
        addressStreet: "4th St.",
        addressCity: "San Francisco",
        addressPostalCode: "94107",
        addressState: "CA",
        addressCountry: "USA",
        hasParking: true,
        hasBikeParking: false,
        parkingSpaces: 20,
        bikeRacks: 10,
        hasBikeLockers: true,
        hasRestrooms: false,
        ticketMachines: 6,
        hasElevator: false,
        isFavorite: true,
        isSelected: false
    )
    
    static var exampleStation2 = CaltrainStation(
        stationId: "sj",
        name: "San Jose",
        shortCode: "sj",
        gtfsStopIdSouth: "1",
        gtfsStopIdNorth: "2",
        latitude: 37.776439,
        longitude: -122.394434,
        zoneNumber: 3,
        address: "700 4th St., San Francisco 94107",
        addressNumber: "700",
        addressStreet: "4th St.",
        addressCity: "San Francisco",
        addressPostalCode: "94107",
        addressState: "CA",
        addressCountry: "USA",
        hasParking: true,
        hasBikeParking: false,
        parkingSpaces: 20,
        bikeRacks: 10,
        hasBikeLockers: true,
        hasRestrooms: false,
        ticketMachines: 6,
        hasElevator: false,
        isFavorite: true,
        isSelected: false
    )
}


