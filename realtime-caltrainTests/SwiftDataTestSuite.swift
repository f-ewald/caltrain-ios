//
//  SwiftDataTestSuite.swift
//  caltrainTests
//
//  Parent suite that serializes all SwiftData-dependent tests to avoid
//  concurrent in-memory store crashes during parallel test execution.
//

import Foundation
import Testing
import SwiftData
@testable import caltrain

/// All tests that create a SwiftData ModelContainer must live inside this
/// serialized suite (or a nested suite within it) so they never run in parallel.
@Suite(.serialized)
struct SwiftDataTestSuite {

    /// Creates an in-memory ModelContainer for testing with a unique name
    static func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([
            TrainDeparture.self,
            CaltrainStation.self,
            PlannedDeparture.self,
        ])
        let config = ModelConfiguration(UUID().uuidString, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Creates an in-memory ModelContainer with only the CaltrainStation model
    static func makeStationOnlyContainer() throws -> ModelContainer {
        let config = ModelConfiguration(UUID().uuidString, isStoredInMemoryOnly: true)
        return try ModelContainer(for: CaltrainStation.self, configurations: config)
    }
}
