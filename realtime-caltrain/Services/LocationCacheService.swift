//
//  LocationCacheService.swift
//  caltrain
//
//  Shares location data between app and widget using App Group UserDefaults
//

import Foundation
import CoreLocation

struct LocationCacheService {
    private static let defaults = UserDefaults(suiteName: "group.net.fewald.caltrain")

    private enum Keys {
        static let lastLatitude = "lastLatitude"
        static let lastLongitude = "lastLongitude"
        static let nearestStationId = "nearestStationId"
        static let lastUpdated = "lastUpdated"
    }

    static func saveLocation(_ location: CLLocation, nearestStationId: String) {
        defaults?.set(location.coordinate.latitude, forKey: Keys.lastLatitude)
        defaults?.set(location.coordinate.longitude, forKey: Keys.lastLongitude)
        defaults?.set(nearestStationId, forKey: Keys.nearestStationId)
        defaults?.set(Date(), forKey: Keys.lastUpdated)
    }

    static func cachedNearestStationId() -> String? {
        defaults?.string(forKey: Keys.nearestStationId)
    }

    static func cachedLocation() -> CLLocation? {
        guard let lat = defaults?.double(forKey: Keys.lastLatitude),
              let lon = defaults?.double(forKey: Keys.lastLongitude),
              lat != 0, lon != 0 else {
            return nil
        }
        return CLLocation(latitude: lat, longitude: lon)
    }

    static func isCacheFresh() -> Bool {
        guard let lastUpdated = defaults?.object(forKey: Keys.lastUpdated) as? Date else {
            return false
        }
        return Date().timeIntervalSince(lastUpdated) < 1800 // 30 minutes
    }
}
