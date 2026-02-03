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
    let mockStation = CaltrainStation(
        stationId: "palo_alto",
        name: "Palo Alto",
        shortCode: "PA",
        gtfsStopIdSouth: "70171",
        gtfsStopIdNorth: "70172",
        latitude: 37.4439,
        longitude: -122.1641,
        address: "95 University Ave"
    )
    let mockDepartures = [
        TrainDeparture(
            stationId: "station1",
            direction: .northbound,
            destinationName: "San Francisco",
            shortDestinationName: "SF",
            scheduledTime: now,
            trainNumber: "151",
            trainType: .local,
            status: .onTime,
            platformNumber: "2"
        ),
        TrainDeparture(
            stationId: "station1",
            direction: .southbound,
            destinationName: "San Jose",
            shortDestinationName: "SJ",
            scheduledTime: now.addingTimeInterval(420),
            trainNumber: "221",
            trainType: .express,
            status: .onTime,
            platformNumber: "1"
        )
    ]

    return List {
        DeparturesSection(
            activeStation: mockStation,
            departures: mockDepartures,
            isLoading: false
        )

        // Loading state preview
        DeparturesSection(
            activeStation: mockStation,
            departures: [],
            isLoading: true
        )
    }
}
