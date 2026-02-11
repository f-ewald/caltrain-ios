//
//  SyncRegistry.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/10/26.
//

import Foundation

enum EntityType: String, CaseIterable {
    case stations
    case timetables
    case departures
    
    var cacheDuration: TimeInterval {
        switch self {
        case .stations:   return 7 * 24 * 60 * 60 // 1 week
        case .timetables: return 24 * 60 * 60     // 1 day
        case .departures: return 30               // 30 seconds
        }
    }
}

protocol Syncable {
    func needsUpdate() -> Bool
}

/// Store last updated and needs update state for different types of entity
class SyncRegistry {
    static let shared = SyncRegistry()
    private let defaults = UserDefaults.standard
    
    private func key(for type: EntityType) -> String {
        return "last_sync_\(type.rawValue)"
    }
    
    func markUpdated(_ type: EntityType) {
        defaults.set(Date(), forKey: key(for: type))
    }
    
    func needsUpdate(_ type: EntityType) -> Bool {
        guard let lastUpdate = defaults.object(forKey: key(for: type)) as? Date else {
            return true // Never updated before
        }
        return Date().timeIntervalSince(lastUpdate) > type.cacheDuration
    }
}
