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

@Test("Refresh interval constant is 60 seconds")
func testRefreshIntervalIs60() {
    #expect(ContentView.refreshIntervalSeconds == 60)
}

@Test("refreshAllDepartures does not affect PlannedDeparture data")
func testRealtimeRefreshPreservesPlannedDepartures() async throws {
    let container = try makeTestContainer()
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
    try context.save()

    // Verify planned departures exist before refresh
    let beforeDescriptor = FetchDescriptor<PlannedDeparture>()
    let beforeCount = try context.fetchCount(beforeDescriptor)
    #expect(beforeCount == 2, "Should have 2 planned departures before refresh")

    // Call refreshAllDepartures (this may fail due to network, but that's OK -
    // we're testing that planned departures survive regardless)
    do {
        try await DepartureService.refreshAllDepartures(
            modelContext: context,
            forceRefresh: true
        )
    } catch {
        // Network errors are expected in test environment
    }

    // Verify planned departures are still intact after real-time refresh
    let afterDescriptor = FetchDescriptor<PlannedDeparture>()
    let afterCount = try context.fetchCount(afterDescriptor)
    #expect(afterCount == 2, "Planned departures should be unchanged after real-time refresh")
}
