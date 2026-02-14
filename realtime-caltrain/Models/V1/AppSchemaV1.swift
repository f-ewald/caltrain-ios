//
//  AppSchema.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/13/26.
//

import SwiftData

public enum AppSchemaV1: VersionedSchema {
    static public var versionIdentifier = Schema.Version(1, 0, 0)
    static public var models: [any PersistentModel.Type] {
        []
    }
}

typealias CurrentSchema = AppSchemaV1
typealias CaltrainStation = CurrentSchema.CaltrainStation
typealias PlannedDeparture = CurrentSchema.PlannedDeparture
typealias TrainDeparture = CurrentSchema.TrainDeparture
typealias Direction = CurrentSchema.Direction
typealias TrainType = CurrentSchema.TrainType
typealias DepartureStatus = CurrentSchema.DepartureStatus
