//
//  StationSelectionService.swift
//  realtime-caltrain
//
//  Created by Claude Code on 1/27/26.
//

import Foundation
import SwiftData

struct StationSelectionService {
    /// Select a station, automatically deselecting all others
    static func selectStation(_ station: CaltrainStation, from allStations: [CaltrainStation]) {
        // Deselect all stations first
        for existingStation in allStations {
            existingStation.isSelected = false
        }
        // Select the chosen station
        station.isSelected = true
    }

    /// Clear all selections
    static func clearSelection(from allStations: [CaltrainStation]) {
        for station in allStations {
            station.isSelected = false
        }
    }

    /// Find the currently selected station, if any
    static func selectedStation(from allStations: [CaltrainStation]) -> CaltrainStation? {
        allStations.first { $0.isSelected }
    }
}
