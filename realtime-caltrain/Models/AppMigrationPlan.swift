//
//  AppMigrationPlan.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/13/26.
//

import SwiftData

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        // Add new AppSchemas here
        [AppSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
    
    // Define migration here later on
//    static let migrateV1toV2 = MigrationStage.lightweight(
//        fromVersion: AppSchemaV1.self,
//        toVersion: AppSchemaV2.self
//    )
}
