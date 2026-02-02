//
//  NearestStationService.swift
//  caltrain
//
//  Created by Claude Code on 1/27/26.
//

import Foundation
import CoreLocation

struct NearestStationService {
    /// Find the nearest station to a given location
    /// - Parameters:
    ///   - userLocation: Current user location
    ///   - stations: Array of all Caltrain stations
    /// - Returns: Tuple of nearest station and distance in meters, or nil if no stations
    static func findNearestStation(
        to userLocation: CLLocation,
        from stations: [CaltrainStation]
    ) -> (station: CaltrainStation, distance: CLLocationDistance)? {

        guard !stations.isEmpty else { return nil }

        // Find station with minimum distance using CLLocation's geodesic distance
        let nearest = stations.min { station1, station2 in
            userLocation.distance(from: station1.location) <
            userLocation.distance(from: station2.location)
        }

        guard let nearestStation = nearest else { return nil }
        let distance = userLocation.distance(from: nearestStation.location)

        return (nearestStation, distance)
    }

    /// Format distance for display
    /// - Parameter meters: Distance in meters
    /// - Returns: Formatted string (e.g., "0.3 mi", "5 mi", "Nearby")
    static func formatDistance(_ meters: CLLocationDistance) -> String {
        let miles = meters / 1609.34

        if miles < 0.1 {
            return "Nearby"
        } else if miles < 1 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }
}
