//
//  StationEntity.swift
//  caltrain
//
//  AppEntity wrapper for CaltrainStation
//

import Foundation
import AppIntents

/// Lightweight AppEntity wrapper for CaltrainStation
/// Required because @Model classes cannot directly conform to AppEntity due to actor isolation
@preconcurrency
struct StationEntity: Identifiable, Hashable, Sendable {
    let id: String  // stationId
    let name: String
    let shortCode: String

    init(id: String, name: String, shortCode: String) {
        self.id = id
        self.name = name
        self.shortCode = shortCode
    }

    /// Create from CaltrainStation model
    init(from station: CaltrainStation) {
        self.id = station.stationId
        self.name = station.name
        self.shortCode = station.shortCode
    }

    /// Special sentinel entity representing "My Location" (nearest station)
    static var myLocation: StationEntity {
        StationEntity(
            id: "_my_location_",
            name: "My Location",
            shortCode: "📍"
        )
    }
}

extension StationEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Caltrain Station"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(shortCode)",
            image: .init(systemName: "tram.fill")
        )
    }

    static var defaultQuery = StationEntityQuery()
}
