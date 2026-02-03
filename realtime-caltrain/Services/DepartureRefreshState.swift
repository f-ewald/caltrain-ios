//
//  DepartureRefreshState.swift
//  caltrain
//
//  Manages global departure refresh state across the app
//  Uses App Group UserDefaults to enable sharing with widgets
//

import Foundation

/// Manages global departure refresh state across the app
/// Uses UserDefaults to enable sharing with widgets
struct DepartureRefreshState {
    private static let defaults = UserDefaults(suiteName: "group.net.fewald.caltrain")

    private enum Keys {
        static let lastDepartureRefresh = "lastDepartureRefresh"
    }

    /// Get the timestamp of the last global departure refresh
    static var lastRefresh: Date? {
        defaults?.object(forKey: Keys.lastDepartureRefresh) as? Date
    }

    /// Update the global refresh timestamp
    static func markRefreshed() {
        defaults?.set(Date(), forKey: Keys.lastDepartureRefresh)
    }

    /// Check if a refresh is allowed (>20s since last refresh)
    static func shouldRefresh(forceRefresh: Bool = false) -> Bool {
        guard !forceRefresh else { return true }

        guard let lastRefresh = lastRefresh else {
            return true  // Never refreshed
        }

        return Date().timeIntervalSince(lastRefresh) >= 20
    }

    /// Clear the refresh state (useful for testing)
    static func clear() {
        defaults?.removeObject(forKey: Keys.lastDepartureRefresh)
    }
}
