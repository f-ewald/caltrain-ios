//
//  LocationCacheServiceTests.swift
//  realtime-caltrainTests
//
//  Tests for LocationCacheService
//

import Testing
import CoreLocation
@testable import realtime_caltrain

struct LocationCacheServiceTests {

    @Test("Save and retrieve location")
    func testSaveAndRetrieveLocation() async throws {
        // Given
        let testLocation = CLLocation(latitude: 37.4438, longitude: -122.1643)
        let testStationId = "70262"

        // When
        LocationCacheService.saveLocation(testLocation, nearestStationId: testStationId)

        // Then
        let cachedLocation = LocationCacheService.cachedLocation()
        let cachedStationId = LocationCacheService.cachedNearestStationId()

        #expect(cachedLocation != nil)
        #expect(cachedLocation?.coordinate.latitude == testLocation.coordinate.latitude)
        #expect(cachedLocation?.coordinate.longitude == testLocation.coordinate.longitude)
        #expect(cachedStationId == testStationId)
    }

    @Test("Cache freshness - immediately fresh")
    func testCacheFreshnessImmediate() async throws {
        // Given
        let testLocation = CLLocation(latitude: 37.4438, longitude: -122.1643)
        let testStationId = "70262"

        // When
        LocationCacheService.saveLocation(testLocation, nearestStationId: testStationId)

        // Then
        #expect(LocationCacheService.isCacheFresh() == true)
    }

    @Test("Cache returns nil when no data saved")
    func testCacheReturnsNilWhenEmpty() async throws {
        // Given - clear any existing cache by setting to zero
        let defaults = UserDefaults(suiteName: "group.net.fewald.realtime-caltrain")
        defaults?.set(0.0, forKey: "lastLatitude")
        defaults?.set(0.0, forKey: "lastLongitude")
        defaults?.removeObject(forKey: "nearestStationId")
        defaults?.removeObject(forKey: "lastUpdated")

        // When/Then
        #expect(LocationCacheService.cachedLocation() == nil)
        #expect(LocationCacheService.cachedNearestStationId() == nil)
        #expect(LocationCacheService.isCacheFresh() == false)
    }

    @Test("Station ID retrieved correctly")
    func testStationIdRetrieval() async throws {
        // Given
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let testStationId = "70012" // San Francisco

        // When
        LocationCacheService.saveLocation(testLocation, nearestStationId: testStationId)

        // Then
        let retrievedStationId = LocationCacheService.cachedNearestStationId()
        #expect(retrievedStationId == testStationId)
    }
}
