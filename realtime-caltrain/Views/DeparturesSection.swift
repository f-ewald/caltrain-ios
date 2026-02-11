//
//  DeparturesSection.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI

struct DeparturesSection: View {
    let activeStation: CaltrainStation?
    let departures: [TrainDeparture]
    let isLoading: Bool

    var body: some View {
        Group {
            if activeStation != nil {
                DeparturesByDirectionView(
                    departures: departures,
                    isLoading: isLoading
                )
                #if DEBUG
                // Show GTFS station ids in debug mode
                Text("North: \(activeStation!.gtfsStopIdNorth)")
                Text("South: \(activeStation!.gtfsStopIdSouth)")
                #endif
            } else {
                Section {
                    EmptyDeparturesView()
                }
            }
        }
    }
}

#Preview {
    let now = Date()
    let mockDepartures = [
        TrainDeparture.exampleDeparture1,
        TrainDeparture.exampleDeparture2
    ]

    List {
        DeparturesSection(
            activeStation: CaltrainStation.exampleStation,
            departures: mockDepartures,
            isLoading: false
        )

        // Loading state preview
        DeparturesSection(
            activeStation: CaltrainStation.exampleStation,
            departures: [],
            isLoading: true
        )
    }
}
