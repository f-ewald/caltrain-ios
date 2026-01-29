//
//  SharedModelContainer.swift
//  realtime-caltrain
//
//  Shared SwiftData container for app and widget extension
//

import SwiftData
import Foundation

struct SharedModelContainer {
    static let appGroupIdentifier = "group.net.fewald.realtime-caltrain"

    static func create() throws -> ModelContainer {
        let schema = Schema([
            TrainDeparture.self,
            CaltrainStation.self,
        ])

        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw SharedContainerError.appGroupNotFound
        }

        let storeURL = appGroupURL.appendingPathComponent("CaltrainData.sqlite")
        let config = ModelConfiguration(url: storeURL)

        return try ModelContainer(for: schema, configurations: [config])
    }
}

enum SharedContainerError: Error {
    case appGroupNotFound
}
