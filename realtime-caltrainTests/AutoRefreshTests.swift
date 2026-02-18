//
//  AutoRefreshTests.swift
//  caltrainTests
//
//  Created by Claude Code on 2/17/26.
//

import Foundation
import Testing
import SwiftData
@testable import caltrain

@Test("Refresh interval constant is 60 seconds")
func testRefreshIntervalIs60() {
    #expect(ContentView.refreshIntervalSeconds == 60)
}

extension SwiftDataTestSuite {

    @Test("Replacing TrainDeparture records does not affect PlannedDeparture data")
    func testRealtimeRefreshPreservesPlannedDepartures() throws {
        let container = try Self.makeTestContainer()
        let context = ModelContext(container)

        let weekday = Calendar.current.component(.weekday, from: Date())
        let isWeekend = weekday == 1 || weekday == 7

        // Insert planned departures
        context.insert(PlannedDeparture(
            stationId: "north1",
            trainType: .local,
            trainNumber: "501",
            scheduledTime: "23:59:00",
            destination: "San Francisco",
            onWeekdays: !isWeekend,
            onWeekends: isWeekend
        ))
        context.insert(PlannedDeparture(
            stationId: "south1",
            trainType: .express,
            trainNumber: "502",
            scheduledTime: "23:58:00",
            destination: "San Jose",
            onWeekdays: !isWeekend,
            onWeekends: isWeekend
        ))

        // Insert a real-time departure
        context.insert(TrainDeparture(
            stationId: "test",
            direction: .northbound,
            destinationName: "San Francisco",
            shortDestinationName: "SF",
            scheduledTime: Date(),
            trainNumber: "101",
            trainType: .local,
            status: .onTime
        ))
        try context.save()

        // Verify planned departures exist before replacement
        let beforeDescriptor = FetchDescriptor<PlannedDeparture>()
        let beforeCount = try context.fetchCount(beforeDescriptor)
        #expect(beforeCount == 2, "Should have 2 planned departures before refresh")

        // Simulate what refreshAllDepartures does: delete all TrainDepartures, insert new ones
        try context.delete(model: TrainDeparture.self)
        context.insert(TrainDeparture(
            stationId: "test",
            direction: .southbound,
            destinationName: "San Jose",
            shortDestinationName: "SJ",
            scheduledTime: Date().addingTimeInterval(3600),
            trainNumber: "202",
            trainType: .express,
            status: .onTime
        ))
        try context.save()

        // Verify planned departures are still intact after TrainDeparture replacement
        let afterDescriptor = FetchDescriptor<PlannedDeparture>()
        let afterCount = try context.fetchCount(afterDescriptor)
        #expect(afterCount == 2, "Planned departures should be unchanged after real-time refresh")

        // Verify the new TrainDeparture was inserted
        let trainDescriptor = FetchDescriptor<TrainDeparture>()
        let trainCount = try context.fetchCount(trainDescriptor)
        #expect(trainCount == 1, "Should have exactly 1 TrainDeparture after replacement")
    }
}
