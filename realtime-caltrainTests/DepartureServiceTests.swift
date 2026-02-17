//
//  DepartureServiceTests.swift
//  caltrainTests
//
//  Created by Claude Code on 2/17/26.
//

import Foundation
import Testing
import SwiftData
@testable import caltrain

/// Creates an in-memory ModelContainer for testing
private func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        TrainDeparture.self,
        CaltrainStation.self,
        PlannedDeparture.self,
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

@Test("upcomingDepartures returns no duplicate train numbers within the same direction")
func testNoDuplicateTrainNumbersInSameDirection() throws {
    let container = try makeTestContainer()
    let context = ModelContext(container)

    // Insert a station whose GTFS stop IDs match the planned departures
    let station = CaltrainStation(
        stationId: "test",
        name: "Test Station",
        shortCode: "TS",
        gtfsStopIdSouth: "south1",
        gtfsStopIdNorth: "north1",
        latitude: 37.5,
        longitude: -122.2,
        zoneNumber: 1
    )
    context.insert(station)

    // Insert duplicate planned departures for the same train (same stationId + trainNumber)
    let weekday = Calendar.current.component(.weekday, from: Date())
    let isWeekend = weekday == 1 || weekday == 7

    for _ in 0..<3 {
        context.insert(PlannedDeparture(
            stationId: "north1",
            trainType: .local,
            trainNumber: "519",
            scheduledTime: "23:59:00",
            destination: "San Francisco",
            onWeekdays: !isWeekend,
            onWeekends: isWeekend
        ))
    }

    for _ in 0..<2 {
        context.insert(PlannedDeparture(
            stationId: "south1",
            trainType: .express,
            trainNumber: "520",
            scheduledTime: "23:59:00",
            destination: "San Jose",
            onWeekdays: !isWeekend,
            onWeekends: isWeekend
        ))
    }

    try context.save()

    // Use a date far in the past so all departures are "upcoming"
    let pastDate = Calendar.current.startOfDay(for: Date())
    let departures = DepartureService.upcomingDepartures(
        modelContext: context, for: station, at: pastDate
    )

    // Collect train numbers per direction
    var northboundTrainNumbers: [String] = []
    var southboundTrainNumbers: [String] = []
    for d in departures {
        if d.direction == .northbound {
            northboundTrainNumbers.append(d.trainNumber)
        } else if d.direction == .southbound {
            southboundTrainNumbers.append(d.trainNumber)
        }
    }

    #expect(Set(northboundTrainNumbers).count == northboundTrainNumbers.count,
            "Northbound departures should have no duplicate train numbers")
    #expect(Set(southboundTrainNumbers).count == southboundTrainNumbers.count,
            "Southbound departures should have no duplicate train numbers")
}

@Test("upcomingDepartures prefers real-time over planned for same train number")
func testRealtimeOverridesPlanned() throws {
    let container = try makeTestContainer()
    let context = ModelContext(container)

    let station = CaltrainStation(
        stationId: "test",
        name: "Test Station",
        shortCode: "TS",
        gtfsStopIdSouth: "south1",
        gtfsStopIdNorth: "north1",
        latitude: 37.5,
        longitude: -122.2,
        zoneNumber: 1
    )
    context.insert(station)

    let weekday = Calendar.current.component(.weekday, from: Date())
    let isWeekend = weekday == 1 || weekday == 7

    // Insert a planned departure for train 101
    context.insert(PlannedDeparture(
        stationId: "north1",
        trainType: .local,
        trainNumber: "101",
        scheduledTime: "23:59:00",
        destination: "San Francisco",
        onWeekdays: !isWeekend,
        onWeekends: isWeekend
    ))

    // Insert a real-time departure for the same train 101
    let futureDate = Date().addingTimeInterval(3600)
    context.insert(TrainDeparture(
        stationId: "test",
        direction: .northbound,
        destinationName: "San Francisco",
        shortDestinationName: "SF",
        scheduledTime: futureDate,
        estimatedTime: futureDate.addingTimeInterval(300),
        trainNumber: "101",
        trainType: .local,
        status: .delayed
    ))

    try context.save()

    let pastDate = Calendar.current.startOfDay(for: Date())
    let departures = DepartureService.upcomingDepartures(
        modelContext: context, for: station, at: pastDate
    )

    let train101 = departures.filter { $0.trainNumber == "101" }
    #expect(train101.count == 1, "Train 101 should appear exactly once")
    #expect(train101.first?.isLive == true, "Real-time departure should be preferred over planned")
}
