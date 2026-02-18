//
//  LocationCacheServiceTests.swift
//  caltrainTests
//
//  Tests for LocationCacheService
//

import Testing
import CoreLocation
@testable import caltrain

@Suite(.serialized)
struct LocationCacheServiceTests {

    /// Use a dedicated UserDefaults suite for test isolation
    private static let testSuiteName = "net.fewald.caltrain.tests.locationcache"

    private func setUpTestDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: Self.testSuiteName)!
        defaults.removePersistentDomain(forName: Self.testSuiteName)
        LocationCacheService.defaults = defaults
        return defaults
    }

    @Test("Save and retrieve location")
    func testSaveAndRetrieveLocation() {
        _ = setUpTestDefaults()

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
    func testCacheFreshnessImmediate() {
        _ = setUpTestDefaults()

        // Given
        let testLocation = CLLocation(latitude: 37.4438, longitude: -122.1643)
        let testStationId = "70262"

        // When
        LocationCacheService.saveLocation(testLocation, nearestStationId: testStationId)

        // Then
        #expect(LocationCacheService.isCacheFresh() == true)
    }

    @Test("Cache returns nil when no data saved")
    func testCacheReturnsNilWhenEmpty() {
        _ = setUpTestDefaults()

        // When/Then - fresh defaults with no data saved
        #expect(LocationCacheService.cachedLocation() == nil)
        #expect(LocationCacheService.cachedNearestStationId() == nil)
        #expect(LocationCacheService.isCacheFresh() == false)
    }

    @Test("Station ID retrieved correctly")
    func testStationIdRetrieval() {
        _ = setUpTestDefaults()

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
