//
//  NearestStationServiceTests.swift
//  realtime-caltrainTests
//
//  Created by Claude Code on 1/27/26.
//

import Testing
import CoreLocation
@testable import realtime_caltrain

@Test("Find nearest station from single option")
func testSingleStation() async throws {
    let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
    let sfStation = CaltrainStation(
        stationId: "sf",
        name: "San Francisco",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943
    )

    let result = NearestStationService.findNearestStation(
        to: userLocation,
        from: [sfStation]
    )

    #expect(result?.station.name == "San Francisco")
    #expect(result!.distance < 5000) // Within 5km
}

@Test("Find nearest from multiple stations")
func testMultipleStations() async throws {
    let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // Near SF
    let sfStation = CaltrainStation(
        stationId: "sf",
        name: "San Francisco",
        shortCode: "SF",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943
    )
    let sjStation = CaltrainStation(
        stationId: "sj",
        name: "San Jose",
        shortCode: "SJ",
        gtfsStopIdSouth: "70261",
        gtfsStopIdNorth: "70262",
        latitude: 37.3297,
        longitude: -121.9027
    )

    let result = NearestStationService.findNearestStation(
        to: userLocation,
        from: [sfStation, sjStation]
    )

    #expect(result?.station.name == "San Francisco")
}

@Test("Handle empty stations array")
func testEmptyStations() async throws {
    let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
    let result = NearestStationService.findNearestStation(to: userLocation, from: [])
    #expect(result == nil)
}

@Test("Format distance correctly - nearby")
func testFormatDistanceNearby() async throws {
    let meters: CLLocationDistance = 100 // 0.062 miles
    let formatted = NearestStationService.formatDistance(meters)
    #expect(formatted == "Nearby")
}

@Test("Format distance correctly - under 1 mile")
func testFormatDistanceUnderMile() async throws {
    let meters: CLLocationDistance = 500 // 0.31 miles
    let formatted = NearestStationService.formatDistance(meters)
    #expect(formatted == "0.3 mi")
}

@Test("Format distance correctly - over 1 mile")
func testFormatDistanceOverMile() async throws {
    let meters: CLLocationDistance = 8000 // ~5 miles
    let formatted = NearestStationService.formatDistance(meters)
    #expect(formatted == "5 mi")
}
