//
//  StationServiceTests.swift
//  caltrainTests
//
//  Created by Claude Code on 2/8/26.
//

import Testing
import SwiftData
@testable import caltrain

// MARK: - Mock API Client

/// Mock API client for testing StationService
class MockCaltrainAPIClient: CaltrainAPIClientProtocol {
    var mockStationData: StationData?
    var shouldThrowError: Bool = false
    var fetchStationsCalled: Bool = false

    func fetchTripUpdates() async throws -> GTFSRealtimeResponse {
        // Not needed for StationService tests
        fatalError("fetchTripUpdates not implemented in mock")
    }

    func fetchStations() async throws -> StationData {
        fetchStationsCalled = true

        if shouldThrowError {
            throw APIError.invalidResponse
        }

        guard let data = mockStationData else {
            throw APIError.invalidResponse
        }

        return data
    }

    func healthcheck() async -> Bool {
        return true
    }
}

// MARK: - Tests

@Test("refreshStations updates existing stations")
func testRefreshStationsUpdatesExisting() async throws {
    // Create in-memory model container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CaltrainStation.self, configurations: config)
    let context = ModelContext(container)

    // Create initial station with old data
    let oldStation = CaltrainStation(
        stationId: "sf",
        name: "Old San Francisco Name",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943,
        zoneNumber: 1,
        isFavorite: true,  // User preference
        isSelected: true   // User preference
    )
    context.insert(oldStation)
    try context.save()

    // Create mock API response with updated station data
    let mockAPIClient = MockCaltrainAPIClient()
    mockAPIClient.mockStationData = StationData(
        stations: [
            StationJSON(
                id: "sf",
                name: "San Francisco",  // Updated name
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.776439,  // Updated latitude
                longitude: -122.394434,  // Updated longitude
                zone: 1,
                address: "700 4th Street",
                addressNumber: "700",
                addressStreet: "4th Street",
                addressCity: "San Francisco",
                addressPostalCode: "12345",
                addressState: "CA",
                addressCountry: "USA",
                hasParking: false,
                hasBikeParking: true,
                parkingSpaces: nil,
                bikeRacks: nil,
                hasBikeLockers: false,
                hasRestrooms: true,
                ticketMachines: 10,
                hasElevator: false
            )
        ],
        version: "1.0",
        lastUpdated: "2026-02-08"
    )

    // Execute refresh
    let service = StationService(apiClient: mockAPIClient)
    try await service.refreshStations(modelContext: context)

    // Verify API was called
    #expect(mockAPIClient.fetchStationsCalled == true)

    // Fetch updated station
    let descriptor = FetchDescriptor<CaltrainStation>()
    let allStations = try context.fetch(descriptor)
    let stations = allStations.filter { $0.stationId == "sf" }

    #expect(stations.count == 1)
    let updatedStation = stations[0]

    // Verify station data was updated
    #expect(updatedStation.name == "San Francisco")
    #expect(updatedStation.latitude == 37.776439)
    #expect(updatedStation.longitude == -122.394434)
    #expect(updatedStation.address == "700 4th Street")
    #expect(updatedStation.hasRestrooms == true)

    // Verify user preferences were preserved
    #expect(updatedStation.isFavorite == true)
    #expect(updatedStation.isSelected == true)
}

@Test("refreshStations adds new stations")
func testRefreshStationsAddsNew() async throws {
    // Create in-memory model container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CaltrainStation.self, configurations: config)
    let context = ModelContext(container)

    // Start with one station
    let existingStation = CaltrainStation(
        stationId: "sf",
        name: "San Francisco",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943,
        zoneNumber: 1
    )
    context.insert(existingStation)
    try context.save()

    // Create mock API response with existing + new station
    let mockAPIClient = MockCaltrainAPIClient()
    mockAPIClient.mockStationData = StationData(
        stations: [
            StationJSON(
                id: "sf",
                name: "San Francisco",
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.776439,
                longitude: -122.394434,
                zone: 1,
                address: "700 4th Street",
                addressNumber: "700",
                addressStreet: "4th Street",
                addressCity: "San Francisco",
                addressPostalCode: "12345",
                addressState: "CA",
                addressCountry: "USA",
                hasParking: false,
                hasBikeParking: true,
                parkingSpaces: nil,
                bikeRacks: nil,
                hasBikeLockers: false,
                hasRestrooms: true,
                ticketMachines: 10,
                hasElevator: false
            ),
            StationJSON(
                id: "22nd",
                name: "22nd Street",  // New station
                shortCode: "22ND",
                gtfsStopIdSouth: "70022",
                gtfsStopIdNorth: "70021",
                latitude: 37.757583,
                longitude: -122.392733,
                zone: 1,
                address: "1450 Pennsylvania Avenue",
                addressNumber: "1450",
                addressStreet: "Pennsylvania Avenue",
                addressCity: "San Francisco",
                addressPostalCode: "12345",
                addressState: "CA",
                addressCountry: "USA",
                hasParking: false,
                hasBikeParking: true,
                parkingSpaces: nil,
                bikeRacks: 27,
                hasBikeLockers: true,
                hasRestrooms: false,
                ticketMachines: 2,
                hasElevator: false
            )
        ],
        version: "1.0",
        lastUpdated: "2026-02-08"
    )

    // Execute refresh
    let service = StationService(apiClient: mockAPIClient)
    try await service.refreshStations(modelContext: context)

    // Verify both stations exist
    let descriptor = FetchDescriptor<CaltrainStation>()
    let allStations = try context.fetch(descriptor).sorted { $0.stationId < $1.stationId }

    #expect(allStations.count == 2)
    #expect(allStations[0].stationId == "22nd")
    #expect(allStations[0].name == "22nd Street")
    #expect(allStations[0].bikeRacks == 27)
    #expect(allStations[1].stationId == "sf")
}

@Test("refreshStations removes deleted stations")
func testRefreshStationsRemovesDeleted() async throws {
    // Create in-memory model container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CaltrainStation.self, configurations: config)
    let context = ModelContext(container)

    // Start with two stations
    let sfStation = CaltrainStation(
        stationId: "sf",
        name: "San Francisco",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943,
        zoneNumber: 1,
    )
    let oldStation = CaltrainStation(
        stationId: "old",
        name: "Old Station",
        shortCode: "OLD",
        gtfsStopIdSouth: "99999",
        gtfsStopIdNorth: "99998",
        latitude: 37.5,
        longitude: -122.5,
        zoneNumber: 1,
    )
    context.insert(sfStation)
    context.insert(oldStation)
    try context.save()

    // Create mock API response with only SF station (old station removed)
    let mockAPIClient = MockCaltrainAPIClient()
    mockAPIClient.mockStationData = StationData(
        stations: [
            StationJSON(
                id: "sf",
                name: "San Francisco",
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.776439,
                longitude: -122.394434,
                zone: 1,
                address: "700 4th Street",
                addressNumber: "700",
                addressStreet: "4th Street",
                addressCity: "San Francisco",
                addressPostalCode: "12345",
                addressState: "CA",
                addressCountry: "USA",
                hasParking: false,
                hasBikeParking: true,
                parkingSpaces: nil,
                bikeRacks: nil,
                hasBikeLockers: false,
                hasRestrooms: true,
                ticketMachines: 10,
                hasElevator: false
            )
        ],
        version: "1.0",
        lastUpdated: "2026-02-08"
    )

    // Execute refresh
    let service = StationService(apiClient: mockAPIClient)
    try await service.refreshStations(modelContext: context)

    // Verify only SF station remains
    let descriptor = FetchDescriptor<CaltrainStation>()
    let allStations = try context.fetch(descriptor)

    #expect(allStations.count == 1)
    #expect(allStations[0].stationId == "sf")

    // Verify old station was deleted
    let oldStations = allStations.filter { $0.stationId == "old" }
    #expect(oldStations.isEmpty)
}

@Test("refreshStations handles combined operations")
func testRefreshStationsCombinedOperations() async throws {
    // Create in-memory model container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CaltrainStation.self, configurations: config)
    let context = ModelContext(container)

    // Start with two stations
    let sfStation = CaltrainStation(
        stationId: "sf",
        name: "Old SF Name",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943,
        zoneNumber: 1,
        isFavorite: true
    )
    let oldStation = CaltrainStation(
        stationId: "deleted",
        name: "Deleted Station",
        shortCode: "DEL",
        gtfsStopIdSouth: "88888",
        gtfsStopIdNorth: "88887",
        latitude: 37.4,
        longitude: -122.4,
        zoneNumber: 1,
    )
    context.insert(sfStation)
    context.insert(oldStation)
    try context.save()

    // API returns: updated SF + new station, old station removed
    let mockAPIClient = MockCaltrainAPIClient()
    mockAPIClient.mockStationData = StationData(
        stations: [
            StationJSON(
                id: "sf",
                name: "San Francisco",  // Updated
                shortCode: "SF",
                gtfsStopIdSouth: "70011",
                gtfsStopIdNorth: "70012",
                latitude: 37.776439,
                longitude: -122.394434,
                zone: 1,
                address: "700 4th Street",
                addressNumber: "700",
                addressStreet: "4th Street",
                addressCity: "San Francisco",
                addressPostalCode: "12345",
                addressState: "CA",
                addressCountry: "USA",
                hasParking: false,
                hasBikeParking: true,
                parkingSpaces: nil,
                bikeRacks: nil,
                hasBikeLockers: false,
                hasRestrooms: true,
                ticketMachines: 10,
                hasElevator: false
            ),
            StationJSON(
                id: "millbrae",  // New
                name: "Millbrae",
                shortCode: "MB",
                gtfsStopIdSouth: "70062",
                gtfsStopIdNorth: "70061",
                latitude: 37.599787,
                longitude: -122.38666,
                zone: 3,
                address: "200 North Rollins Road",
                addressNumber: "700",
                addressStreet: "4th Street",
                addressCity: "San Francisco",
                addressPostalCode: "12345",
                addressState: "CA",
                addressCountry: "USA",
                hasParking: true,
                hasBikeParking: true,
                parkingSpaces: 2400,
                bikeRacks: 48,
                hasBikeLockers: true,
                hasRestrooms: true,
                ticketMachines: 3,
                hasElevator: true
            )
        ],
        version: "1.0",
        lastUpdated: "2026-02-08"
    )

    // Execute refresh
    let service = StationService(apiClient: mockAPIClient)
    try await service.refreshStations(modelContext: context)

    // Verify results
    let descriptor = FetchDescriptor<CaltrainStation>()
    let allStations = try context.fetch(descriptor)

    // Should have 2 stations (deleted removed, millbrae added)
    #expect(allStations.count == 2)

    // Check millbrae was added
    let millbrae = allStations.first { $0.stationId == "millbrae" }
    #expect(millbrae != nil)
    #expect(millbrae?.name == "Millbrae")
    #expect(millbrae?.parkingSpaces == 2400)

    // Check SF was updated and favorite preserved
    let sf = allStations.first { $0.stationId == "sf" }
    #expect(sf != nil)
    #expect(sf?.name == "San Francisco")
    #expect(sf?.isFavorite == true)

    // Check deleted station is gone
    let deleted = allStations.first { $0.stationId == "deleted" }
    #expect(deleted == nil)
}

@Test("refreshStations handles API errors")
func testRefreshStationsAPIError() async throws {
    // Create in-memory model container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CaltrainStation.self, configurations: config)
    let context = ModelContext(container)

    // Add a station
    let station = CaltrainStation(
        stationId: "sf",
        name: "San Francisco",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943,
        zoneNumber: 1,
    )
    context.insert(station)
    try context.save()

    // Create mock API client that throws error
    let mockAPIClient = MockCaltrainAPIClient()
    mockAPIClient.shouldThrowError = true

    // Execute refresh and expect error
    let service = StationService(apiClient: mockAPIClient)

    var didThrow = false
    do {
        try await service.refreshStations(modelContext: context)
    } catch {
        didThrow = true
    }

    #expect(didThrow == true)

    // Verify original station is still there (no changes on error)
    let descriptor = FetchDescriptor<CaltrainStation>()
    let allStations = try context.fetch(descriptor)
    #expect(allStations.count == 1)
    #expect(allStations[0].name == "San Francisco")
}

@Test("refreshStations handles empty API response")
func testRefreshStationsEmptyResponse() async throws {
    // Create in-memory model container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CaltrainStation.self, configurations: config)
    let context = ModelContext(container)

    // Add stations
    let station1 = CaltrainStation(
        stationId: "sf",
        name: "San Francisco",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943,
        zoneNumber: 1,
    )
    let station2 = CaltrainStation(
        stationId: "sj",
        name: "San Jose",
        shortCode: "SJ",
        gtfsStopIdSouth: "70261",
        gtfsStopIdNorth: "70262",
        latitude: 37.3297,
        longitude: -121.9027,
        zoneNumber: 1,
    )
    context.insert(station1)
    context.insert(station2)
    try context.save()

    // API returns empty list
    let mockAPIClient = MockCaltrainAPIClient()
    mockAPIClient.mockStationData = StationData(
        stations: [],
        version: "1.0",
        lastUpdated: "2026-02-08"
    )

    // Execute refresh
    let service = StationService(apiClient: mockAPIClient)
    try await service.refreshStations(modelContext: context)

    // All stations should be removed
    let descriptor = FetchDescriptor<CaltrainStation>()
    let allStations = try context.fetch(descriptor)
    #expect(allStations.isEmpty)
}
