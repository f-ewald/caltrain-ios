//
//  StationDataLoaderTests.swift
//  caltrainTests
//
//  Created by Claude Code on 2/18/26.
//

import Foundation
import Testing
import SwiftData
@testable import caltrain

// MARK: - StationDataLoader Tests

extension SwiftDataTestSuite {

    // MARK: - Helpers

    /// Creates a StationJSON for testing
    private static func makeStationJSON(
        id: String,
        name: String,
        shortCode: String = "XX",
        gtfsStopIdSouth: String = "70011",
        gtfsStopIdNorth: String = "70012",
        latitude: Double = 37.7764,
        longitude: Double = -122.3943,
        zone: Int = 1,
        address: String? = nil,
        addressNumber: String? = nil,
        addressStreet: String? = nil,
        addressCity: String? = nil,
        addressPostalCode: String? = nil,
        addressState: String? = nil,
        addressCountry: String? = nil,
        hasParking: Bool = false,
        hasBikeParking: Bool = false,
        parkingSpaces: Int? = nil,
        bikeRacks: Int? = nil,
        hasBikeLockers: Bool = false,
        hasRestrooms: Bool = false,
        ticketMachines: Int? = nil,
        hasElevator: Bool = false
    ) -> StationJSON {
        StationJSON(
            id: id,
            name: name,
            shortCode: shortCode,
            gtfsStopIdSouth: gtfsStopIdSouth,
            gtfsStopIdNorth: gtfsStopIdNorth,
            latitude: latitude,
            longitude: longitude,
            zone: zone,
            address: address,
            addressNumber: addressNumber,
            addressStreet: addressStreet,
            addressCity: addressCity,
            addressPostalCode: addressPostalCode,
            addressState: addressState,
            addressCountry: addressCountry,
            hasParking: hasParking,
            hasBikeParking: hasBikeParking,
            parkingSpaces: parkingSpaces,
            bikeRacks: bikeRacks,
            hasBikeLockers: hasBikeLockers,
            hasRestrooms: hasRestrooms,
            ticketMachines: ticketMachines,
            hasElevator: hasElevator
        )
    }

    // MARK: - syncStations Tests

    @Test("syncStations inserts all stations on first launch (empty DB)")
    func testSyncStationsFirstLaunch() throws {
        let container = try Self.makeStationOnlyContainer()
        let context = ModelContext(container)

        let jsonStations = [
            Self.makeStationJSON(
                id: "sf",
                name: "San Francisco",
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.776439,
                longitude: -122.394434,
                zone: 1,
                address: "700 4th Street",
                hasParking: false,
                hasBikeParking: true,
                hasRestrooms: true,
                ticketMachines: 10
            ),
            Self.makeStationJSON(
                id: "22nd",
                name: "22nd Street",
                shortCode: "22ND",
                gtfsStopIdSouth: "70022",
                gtfsStopIdNorth: "70021",
                latitude: 37.757583,
                longitude: -122.392733,
                zone: 1,
                hasBikeParking: true,
                bikeRacks: 27,
                hasBikeLockers: true,
                ticketMachines: 2
            ),
        ]

        try StationDataLoader.syncStations(jsonStations, modelContext: context)

        let descriptor = FetchDescriptor<CaltrainStation>()
        let allStations = try context.fetch(descriptor).sorted { $0.stationId < $1.stationId }

        #expect(allStations.count == 2)
        #expect(allStations[0].stationId == "22nd")
        #expect(allStations[0].name == "22nd Street")
        #expect(allStations[0].bikeRacks == 27)
        #expect(allStations[0].hasBikeLockers == true)
        #expect(allStations[1].stationId == "sf")
        #expect(allStations[1].name == "San Francisco")
        #expect(allStations[1].hasRestrooms == true)
        #expect(allStations[1].ticketMachines == 10)
    }

    @Test("syncStations updates existing station while preserving user preferences")
    func testSyncStationsPreservesPreferences() throws {
        let container = try Self.makeStationOnlyContainer()
        let context = ModelContext(container)

        // Insert existing station with user preferences set
        let existing = CaltrainStation(
            stationId: "sf",
            name: "Old Name",
            shortCode: "SF",
            gtfsStopIdSouth: "70011",
            gtfsStopIdNorth: "70012",
            latitude: 37.0,
            longitude: -122.0,
            zoneNumber: 1,
            hasParking: false,
            hasRestrooms: false,
            isFavorite: true,
            isSelected: true
        )
        context.insert(existing)
        try context.save()

        // JSON has updated data for the same station
        let jsonStations = [
            Self.makeStationJSON(
                id: "sf",
                name: "San Francisco",
                shortCode: "SFC",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.776439,
                longitude: -122.394434,
                zone: 1,
                address: "700 4th Street",
                addressNumber: "700",
                addressStreet: "4th Street",
                addressCity: "San Francisco",
                addressPostalCode: "94107",
                addressState: "CA",
                addressCountry: "USA",
                hasParking: true,
                hasBikeParking: true,
                parkingSpaces: 50,
                hasRestrooms: true,
                ticketMachines: 10,
                hasElevator: true
            ),
        ]

        try StationDataLoader.syncStations(jsonStations, modelContext: context)

        let descriptor = FetchDescriptor<CaltrainStation>()
        let allStations = try context.fetch(descriptor)

        #expect(allStations.count == 1)
        let station = allStations[0]

        // Data fields updated
        #expect(station.name == "San Francisco")
        #expect(station.shortCode == "SFC")
        #expect(station.latitude == 37.776439)
        #expect(station.longitude == -122.394434)
        #expect(station.address == "700 4th Street")
        #expect(station.addressNumber == "700")
        #expect(station.addressStreet == "4th Street")
        #expect(station.addressCity == "San Francisco")
        #expect(station.addressPostalCode == "94107")
        #expect(station.addressState == "CA")
        #expect(station.addressCountry == "USA")
        #expect(station.hasParking == true)
        #expect(station.hasBikeParking == true)
        #expect(station.parkingSpaces == 50)
        #expect(station.hasRestrooms == true)
        #expect(station.ticketMachines == 10)
        #expect(station.hasElevator == true)

        // User preferences preserved
        #expect(station.isFavorite == true)
        #expect(station.isSelected == true)
    }

    @Test("syncStations adds new stations alongside existing ones")
    func testSyncStationsAddsNewStation() throws {
        let container = try Self.makeStationOnlyContainer()
        let context = ModelContext(container)

        // DB has station A
        let stationA = CaltrainStation(
            stationId: "sf",
            name: "San Francisco",
            shortCode: "SF",
            gtfsStopIdSouth: "70011",
            gtfsStopIdNorth: "70012",
            latitude: 37.7764,
            longitude: -122.3943,
            zoneNumber: 1,
            isFavorite: true
        )
        context.insert(stationA)
        try context.save()

        // JSON has stations A + B
        let jsonStations = [
            Self.makeStationJSON(
                id: "sf",
                name: "San Francisco",
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.7764,
                longitude: -122.3943,
                zone: 1
            ),
            Self.makeStationJSON(
                id: "millbrae",
                name: "Millbrae",
                shortCode: "MB",
                gtfsStopIdSouth: "70062",
                gtfsStopIdNorth: "70061",
                latitude: 37.599787,
                longitude: -122.38666,
                zone: 3,
                hasParking: true,
                parkingSpaces: 2400
            ),
        ]

        try StationDataLoader.syncStations(jsonStations, modelContext: context)

        let descriptor = FetchDescriptor<CaltrainStation>()
        let allStations = try context.fetch(descriptor).sorted { $0.stationId < $1.stationId }

        #expect(allStations.count == 2)

        // Station A still exists with preferences
        let sf = allStations.first { $0.stationId == "sf" }
        #expect(sf != nil)
        #expect(sf?.isFavorite == true)

        // Station B was added
        let mb = allStations.first { $0.stationId == "millbrae" }
        #expect(mb != nil)
        #expect(mb?.name == "Millbrae")
        #expect(mb?.parkingSpaces == 2400)
        #expect(mb?.isFavorite == false)
    }

    @Test("syncStations deletes stations no longer in JSON")
    func testSyncStationsDeletesRemovedStation() throws {
        let container = try Self.makeStationOnlyContainer()
        let context = ModelContext(container)

        // DB has stations A and B
        let stationA = CaltrainStation(
            stationId: "sf",
            name: "San Francisco",
            shortCode: "SF",
            gtfsStopIdSouth: "70011",
            gtfsStopIdNorth: "70012",
            latitude: 37.7764,
            longitude: -122.3943,
            zoneNumber: 1
        )
        let stationB = CaltrainStation(
            stationId: "old",
            name: "Old Station",
            shortCode: "OLD",
            gtfsStopIdSouth: "99999",
            gtfsStopIdNorth: "99998",
            latitude: 37.5,
            longitude: -122.5,
            zoneNumber: 2
        )
        context.insert(stationA)
        context.insert(stationB)
        try context.save()

        // JSON has only station A
        let jsonStations = [
            Self.makeStationJSON(
                id: "sf",
                name: "San Francisco",
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.7764,
                longitude: -122.3943,
                zone: 1
            ),
        ]

        try StationDataLoader.syncStations(jsonStations, modelContext: context)

        let descriptor = FetchDescriptor<CaltrainStation>()
        let allStations = try context.fetch(descriptor)

        #expect(allStations.count == 1)
        #expect(allStations[0].stationId == "sf")
    }

    @Test("syncStations handles combined update, add, and delete")
    func testSyncStationsCombinedOperations() throws {
        let container = try Self.makeStationOnlyContainer()
        let context = ModelContext(container)

        // DB has stations: sf (to update), old (to delete)
        let sfStation = CaltrainStation(
            stationId: "sf",
            name: "Old SF Name",
            shortCode: "SF",
            gtfsStopIdSouth: "70011",
            gtfsStopIdNorth: "70012",
            latitude: 37.7764,
            longitude: -122.3943,
            zoneNumber: 1,
            isFavorite: true,
            isSelected: true
        )
        let oldStation = CaltrainStation(
            stationId: "deleted",
            name: "Deleted Station",
            shortCode: "DEL",
            gtfsStopIdSouth: "88888",
            gtfsStopIdNorth: "88887",
            latitude: 37.4,
            longitude: -122.4,
            zoneNumber: 1
        )
        context.insert(sfStation)
        context.insert(oldStation)
        try context.save()

        // JSON: updated sf + new millbrae, "deleted" station removed
        let jsonStations = [
            Self.makeStationJSON(
                id: "sf",
                name: "San Francisco",
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.776439,
                longitude: -122.394434,
                zone: 1,
                address: "700 4th Street",
                hasRestrooms: true
            ),
            Self.makeStationJSON(
                id: "millbrae",
                name: "Millbrae",
                shortCode: "MB",
                gtfsStopIdSouth: "70062",
                gtfsStopIdNorth: "70061",
                latitude: 37.599787,
                longitude: -122.38666,
                zone: 3,
                hasParking: true,
                parkingSpaces: 2400,
                hasElevator: true
            ),
        ]

        try StationDataLoader.syncStations(jsonStations, modelContext: context)

        let descriptor = FetchDescriptor<CaltrainStation>()
        let allStations = try context.fetch(descriptor)

        // 2 stations: sf (updated) + millbrae (new), deleted station gone
        #expect(allStations.count == 2)

        // SF updated, preferences preserved
        let sf = allStations.first { $0.stationId == "sf" }
        #expect(sf != nil)
        #expect(sf?.name == "San Francisco")
        #expect(sf?.latitude == 37.776439)
        #expect(sf?.hasRestrooms == true)
        #expect(sf?.isFavorite == true)
        #expect(sf?.isSelected == true)

        // Millbrae added
        let mb = allStations.first { $0.stationId == "millbrae" }
        #expect(mb != nil)
        #expect(mb?.name == "Millbrae")
        #expect(mb?.parkingSpaces == 2400)
        #expect(mb?.hasElevator == true)

        // Deleted station gone
        let deleted = allStations.first { $0.stationId == "deleted" }
        #expect(deleted == nil)
    }
}
