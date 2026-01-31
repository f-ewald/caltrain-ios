//
//  DeparturesByDirectionView.swift
//  realtime-caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI

struct DeparturesByDirectionView: View {
    let departures: [TrainDeparture]
    let isLoading: Bool

    private var northboundDepartures: [TrainDeparture] {
        departures
            .filter { $0.direction == .northbound }
            .sorted { $0.displayTime < $1.displayTime }
    }

    private var southboundDepartures: [TrainDeparture] {
        departures
            .filter { $0.direction == .southbound }
            .sorted { $0.displayTime < $1.displayTime }
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
                        ForEach(northboundDepartures, id: \.departureId) { departure in
                            DepartureRow(departure: departure)
                        }
                    } header: {
                        Label(Direction.northbound.displayName, systemImage: Direction.northbound.iconName)
                    }
                }

                // Southbound Section
                if !southboundDepartures.isEmpty {
                    Section {
                        ForEach(southboundDepartures, id: \.departureId) { departure in
                            DepartureRow(departure: departure)
                        }
                    } header: {
                        Label(Direction.southbound.displayName, systemImage: Direction.southbound.iconName)
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
            departureId: "1",
            stationId: "station1",
            direction: .northbound,
            destinationName: "San Francisco",
            scheduledTime: now,
            trainNumber: "151",
            trainType: .local,
            status: .onTime,
            platformNumber: "2"
        ),
        TrainDeparture(
            departureId: "2",
            stationId: "station1",
            direction: .northbound,
            destinationName: "San Francisco",
            scheduledTime: now.addingTimeInterval(900),
            estimatedTime: now.addingTimeInterval(1080),
            trainNumber: "152",
            trainType: .limited,
            status: .delayed,
            platformNumber: "2"
        ),
        TrainDeparture(
            departureId: "3",
            stationId: "station1",
            direction: .southbound,
            destinationName: "San Jose",
            scheduledTime: now.addingTimeInterval(420),
            trainNumber: "221",
            trainType: .babyBullet,
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
