//
//  DeparturesByDirectionView.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI

struct DeparturesByDirectionView: View {
    let departures: [TrainDeparture]
    let isLoading: Bool

    private var northboundDepartures: [TrainDeparture] {
        Array(departures
            .filter { $0.direction == .northbound }
            .sorted { $0.displayTime < $1.displayTime }
            .prefix(10))
    }

    private var southboundDepartures: [TrainDeparture] {
        Array(departures
            .filter { $0.direction == .southbound }
            .sorted { $0.displayTime < $1.displayTime }
            .prefix(10))
    }

    var body: some View {
        Group {
            // Show loading indicator when loading and no departures yet
            if isLoading && departures.isEmpty {
                Section {
                    PulsingTrainLoadingView()
                }
            }
            // Show departures when available (even if still loading - for refresh case)
            else if !northboundDepartures.isEmpty || !southboundDepartures.isEmpty {
                // Northbound Section
                if !northboundDepartures.isEmpty {
                    Section {
                        ForEach(northboundDepartures, id: \.trainNumber) { departure in
                            DepartureRow(departure: departure)
                        }
                    } header: {
                        Label(Direction.northbound.displayName, systemImage: Direction.northbound.iconName)
                    } footer: {
                        Text("To \(Direction.northbound.terminus)")
                    }
                }

                // Southbound Section
                if !southboundDepartures.isEmpty {
                    Section {
                        ForEach(southboundDepartures, id: \.trainNumber) { departure in
                            DepartureRow(departure: departure)
                        }
                    } header: {
                        let displayName = Direction.southbound.displayName
                        Label(displayName, systemImage: Direction.southbound.iconName)
                    } footer: {
                        Text("To \(Direction.southbound.terminus)")
                    }
                }
            }
            // Show empty state when not loading and no departures
            else if !isLoading {
                Section {
                    Text("No upcoming departures")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
    }
}

#Preview {
    let now = Date()
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
            direction: .northbound,
            destinationName: "San Francisco",
            shortDestinationName: "SF",
            scheduledTime: now.addingTimeInterval(900),
            estimatedTime: now.addingTimeInterval(1080),
            trainNumber: "152",
            trainType: .limited,
            status: .delayed,
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
        // Preview with data
        Section {
            DeparturesByDirectionView(
                departures: mockDepartures,
                isLoading: false
            )
        }

        // Preview loading state
        Section {
            DeparturesByDirectionView(
                departures: [],
                isLoading: true
            )
        }

        // Preview empty state
        Section {
            DeparturesByDirectionView(
                departures: [],
                isLoading: false
            )
        }
        
        TrainLogo(size: 60, color: .red)
    }
}
