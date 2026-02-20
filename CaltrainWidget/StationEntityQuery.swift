//
//  StationEntityQuery.swift
//  CaltrainWidget
//
//  EntityQuery implementation for widget station selection
//

import AppIntents
import SwiftData

struct StationEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [StationEntity] {
        // Fetch specific stations by ID
        guard let container = try? SharedModelContainer.create() else {
            return []
        }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<CaltrainStation>(
            predicate: #Predicate { station in
                identifiers.contains(station.stationId)
            },
            sortBy: [SortDescriptor(\CaltrainStation.gtfsStopIdNorth)],
        )
        let stations = (try? context.fetch(descriptor)) ?? []
        return stations.map { StationEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [StationEntity] {
        // Return all stations sorted by line order, with "My Location" first
        guard let container = try? SharedModelContainer.create() else {
            return [StationEntity.myLocation]
        }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<CaltrainStation>(
            sortBy: [SortDescriptor(\.gtfsStopIdNorth)]
        )

        let realStations = (try? context.fetch(descriptor)) ?? []

        // Prepend "My Location" sentinel and convert to entities
        return [StationEntity.myLocation] + realStations.map { StationEntity(from: $0) }
    }
}
