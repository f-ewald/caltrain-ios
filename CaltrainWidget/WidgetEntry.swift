//
//  WidgetEntry.swift
//  CaltrainWidget
//
//  Timeline entry model for widget updates
//

import WidgetKit
import SwiftUI

struct CaltrainWidgetEntry: TimelineEntry {
    let date: Date
    let station: CaltrainStation?
    let northboundDepartures: [TrainDeparture]
    let southboundDepartures: [TrainDeparture]
    let error: WidgetError?

    enum WidgetError: String {
        case noLocation = "Location not available"
        case noStation = "No station found"
        case noData = "No departure data"
        case apiError = "Unable to fetch data"
        case cacheStale = "Location data is stale"
    }

    // Placeholder entry for preview
    static var placeholder: CaltrainWidgetEntry {
        CaltrainWidgetEntry(
            date: Date(),
            station: nil,
            northboundDepartures: [],
            southboundDepartures: [],
            error: nil
        )
    }

    // Sample entry for preview
    static var sample: CaltrainWidgetEntry {
        let station = CaltrainStation(
            stationId: "70262",
            name: "Palo Alto",
            shortCode: "PA",
            gtfsStopIdSouth: "70262",
            gtfsStopIdNorth: "70261",
            latitude: 37.4438,
            longitude: -122.1643
        )

        let now = Date()
        let northbound = [
            TrainDeparture(
                departureId: "NB123",
                stationId: "70262",
                direction: .northbound,
                destinationName: "San Francisco",
                scheduledTime: now.addingTimeInterval(300),
                estimatedTime: now.addingTimeInterval(300),
                trainNumber: "123",
                trainType: .limited,
                status: .onTime
            ),
            TrainDeparture(
                departureId: "NB125",
                stationId: "70262",
                direction: .northbound,
                destinationName: "San Francisco",
                scheduledTime: now.addingTimeInterval(900),
                estimatedTime: now.addingTimeInterval(900),
                trainNumber: "125",
                trainType: .local,
                status: .onTime
            ),
            TrainDeparture(
                departureId: "NB127",
                stationId: "70262",
                direction: .northbound,
                destinationName: "San Francisco",
                scheduledTime: now.addingTimeInterval(1800),
                estimatedTime: now.addingTimeInterval(1920),
                trainNumber: "127",
                trainType: .babyBullet,
                status: .delayed
            )
        ]

        let southbound = [
            TrainDeparture(
                departureId: "SB124",
                stationId: "70262",
                direction: .southbound,
                destinationName: "San Jose Diridon",
                scheduledTime: now.addingTimeInterval(420),
                estimatedTime: now.addingTimeInterval(420),
                trainNumber: "124",
                trainType: .local,
                status: .onTime
            ),
            TrainDeparture(
                departureId: "SB126",
                stationId: "70262",
                direction: .southbound,
                destinationName: "Tamien",
                scheduledTime: now.addingTimeInterval(1020),
                estimatedTime: now.addingTimeInterval(1020),
                trainNumber: "126",
                trainType: .limited,
                status: .onTime
            ),
            TrainDeparture(
                departureId: "SB128",
                stationId: "70262",
                direction: .southbound,
                destinationName: "Gilroy",
                scheduledTime: now.addingTimeInterval(1920),
                estimatedTime: now.addingTimeInterval(1920),
                trainNumber: "128",
                trainType: .babyBullet,
                status: .onTime
            )
        ]

        return CaltrainWidgetEntry(
            date: now,
            station: station,
            northboundDepartures: northbound,
            southboundDepartures: southbound,
            error: nil
        )
    }
}
