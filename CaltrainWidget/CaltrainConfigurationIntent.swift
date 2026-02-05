//
//  WidgetIntent.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/3/26.
//

import AppIntents

enum ShowDirection: String, AppEnum {
    case north, south, both
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Direction"
    static var caseDisplayRepresentations: [ShowDirection : DisplayRepresentation] = [
        .north: "Northbound",
        .south: "Southbound",
        .both: "North & Southbound"
    ]
}

/// WidgetConfigurationIntent to allow configuration of any specific widget instance
struct CaltrainConfigurationIntent : WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Station Configuration"
    static var description: IntentDescription = IntentDescription("Configure which station and direction to display")

    @Parameter(title: "Station")
    var station: StationEntity?
    
    @Parameter(title: "Direction", default: .both)
    var direction: ShowDirection


    init(direction: ShowDirection, station: StationEntity?) {
        self.direction = direction
        self.station = station
    }

    init() {
        self.direction = .both
        self.station = .myLocation
    }
}
