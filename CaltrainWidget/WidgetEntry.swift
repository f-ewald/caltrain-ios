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
    let configuration: CaltrainConfigurationIntent
    let station: CaltrainStation?
    let northboundDepartures: [TrainDeparture]
    let southboundDepartures: [TrainDeparture]
    let error: WidgetError?
    let debugMessage: String?

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
            configuration: CaltrainConfigurationIntent(),
            station: nil,
            northboundDepartures: [],
            southboundDepartures: [],
            error: nil,
            debugMessage: nil,
        )
    }

    // Sample entry for preview
    static var sample: CaltrainWidgetEntry {
        let now = Date()
        let northbound = [
            TrainDeparture(
                stationId: "70262",
                direction: .northbound,
                destinationName: "San Francisco",
                shortDestinationName: "SF",
                scheduledTime: now.addingTimeInterval(300),
                estimatedTime: now.addingTimeInterval(300),
                trainNumber: "123",
                trainType: .limited,
                status: .onTime
            ),
            TrainDeparture(
                stationId: "70262",
                direction: .northbound,
                destinationName: "San Francisco",
                shortDestinationName: "SF",
                scheduledTime: now.addingTimeInterval(900),
                estimatedTime: now.addingTimeInterval(900),
                trainNumber: "125",
                trainType: .local,
                status: .onTime
            ),
            TrainDeparture(
                stationId: "70262",
                direction: .northbound,
                destinationName: "San Francisco",
                shortDestinationName: "SF",
                scheduledTime: now.addingTimeInterval(1800),
                estimatedTime: now.addingTimeInterval(1920),
                trainNumber: "127",
                trainType: .express,
                status: .delayed
            )
        ]

        let southbound = [
            TrainDeparture(
                stationId: "70262",
                direction: .southbound,
                destinationName: "San Jose Diridon",
                shortDestinationName: "SJ",
                scheduledTime: now.addingTimeInterval(420),
                estimatedTime: now.addingTimeInterval(420),
                trainNumber: "124",
                trainType: .local,
                status: .onTime
            ),
            TrainDeparture(
                stationId: "70262",
                direction: .southbound,
                destinationName: "Tamien",
                shortDestinationName: "TAM",
                scheduledTime: now.addingTimeInterval(1020),
                estimatedTime: now.addingTimeInterval(1020),
                trainNumber: "126",
                trainType: .limited,
                status: .onTime
            ),
            TrainDeparture(
                stationId: "70262",
                direction: .southbound,
                destinationName: "Gilroy",
                shortDestinationName: "GILR",
                scheduledTime: now.addingTimeInterval(1920),
                estimatedTime: now.addingTimeInterval(1920),
                trainNumber: "128",
                trainType: .express,
                status: .onTime
            )
        ]

        return CaltrainWidgetEntry(
            date: now,
            configuration: CaltrainConfigurationIntent(),
            station: CaltrainStation.exampleStation,
            northboundDepartures: northbound,
            southboundDepartures: southbound,
            error: nil,
            debugMessage: nil,
        )
    }
    
    static var sampleNorthbound: CaltrainWidgetEntry {
        let x = sample
        x.configuration.direction = .north
        let specificStation = StationEntity(
            id: "70262",
            name: "Palo Alto",
            shortCode: "PA"
        )
        x.configuration.station = specificStation
        return x
    }

    // Sample with minimal departures
    static var sampleMinimal: CaltrainWidgetEntry {
        let now = Date()
        let southbound = [
            TrainDeparture(
                stationId: "70011",
                direction: .southbound,
                destinationName: "San Jose Diridon",
                shortDestinationName: "SJ",
                scheduledTime: now.addingTimeInterval(180),
                estimatedTime: now.addingTimeInterval(180),
                trainNumber: "101",
                trainType: .express,
                status: .onTime
            )
        ]

        return CaltrainWidgetEntry(
            date: now,
            configuration: CaltrainConfigurationIntent(),
            station: CaltrainStation.exampleStation,
            northboundDepartures: [],
            southboundDepartures: southbound,
            error: nil,
            debugMessage: nil,
        )
    }

    // Sample with delays
    static var sampleWithDelays: CaltrainWidgetEntry {
        let now = Date()
        let northbound = [
            TrainDeparture(
                stationId: "70081",
                direction: .northbound,
                destinationName: "San Francisco",
                shortDestinationName: "SF",
                scheduledTime: now.addingTimeInterval(420),
                estimatedTime: now.addingTimeInterval(720),
                trainNumber: "202",
                trainType: .local,
                status: .delayed
            ),
            TrainDeparture(
                stationId: "70081",
                direction: .northbound,
                destinationName: "San Francisco",
                shortDestinationName: "SF",
                scheduledTime: now.addingTimeInterval(1200),
                estimatedTime: now.addingTimeInterval(1620),
                trainNumber: "204",
                trainType: .limited,
                status: .delayed
            )
        ]

        let southbound = [
            TrainDeparture(
                stationId: "70081",
                direction: .southbound,
                destinationName: "San Jose Diridon",
                shortDestinationName: "SJ",
                scheduledTime: now.addingTimeInterval(600),
                estimatedTime: now.addingTimeInterval(600),
                trainNumber: "203",
                trainType: .local,
                status: .onTime
            )
        ]

        return CaltrainWidgetEntry(
            date: now,
            configuration: CaltrainConfigurationIntent(),
            station: CaltrainStation.exampleStation,
            northboundDepartures: northbound,
            southboundDepartures: southbound,
            error: nil,
            debugMessage: nil,
        )
    }
}

// MARK: - Previews

#Preview("Medium - Sample Data", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Large - Sample Data", as: .systemLarge) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Medium - Minimal Departures", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sampleMinimal
}

#Preview("Large - With Delays", as: .systemLarge) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sampleWithDelays
}

#Preview("Medium - No Location Error", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .noLocation,
        debugMessage: nil,
    )
}

#Preview("Medium - No Data Error", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: CaltrainStation.exampleStation,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .noData,
        debugMessage: nil,
    )
}

#Preview("Large - API Error", as: .systemLarge) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .apiError,
        debugMessage: nil,
    )
}

#Preview("Medium - Placeholder", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.placeholder
}
