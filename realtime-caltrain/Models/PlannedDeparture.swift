//
//  PlannedDeparture.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/10/26.
//

import Foundation
import SwiftData

/// A planned departure, following a schedule
@Model
final class PlannedDeparture {
    var stationId: String
    var trainType: TrainType
    var trainNumber: String
    var scheduledTime: String
    var destination: String

    init(stationId: String, trainType: TrainType, trainNumber: String, scheduledTime: String, destination: String) {
        self.stationId = stationId
        self.trainType = trainType
        self.trainNumber = trainNumber
        self.scheduledTime = scheduledTime
        self.destination = destination
    }

    /// This converts the string to a real Date for "today"
    var departureTime: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        // 1. Get the time components from the string
        guard let timeDate = formatter.date(from: scheduledTime) else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: timeDate)

        // 2. Map those components onto today's date
        return Calendar.current.date(bySettingHour: components.hour ?? 0,
                                     minute: components.minute ?? 0,
                                     second: components.second ?? 0,
                                     of: Date())
    }

    /// Converts this PlannedDeparture into a TrainDeparture
    /// - Returns: A TrainDeparture instance, or nil if the scheduled time cannot be parsed
    func toTrainDeparture() -> TrainDeparture? {
        guard let scheduledDate = departureTime else { return nil }

        let direction = inferDirection(from: destination)
        let shortName = shortDestinationName(for: destination)

        return TrainDeparture(
            stationId: stationId,
            direction: direction,
            destinationName: destination,
            shortDestinationName: shortName,
            scheduledTime: scheduledDate,
            estimatedTime: nil,
            trainNumber: trainNumber,
            trainType: trainType,
            status: .onTime,
            platformNumber: nil
        )
    }

    /// Infers the direction based on the destination name
    private func inferDirection(from destination: String) -> Direction {
        let lowercased = destination.lowercased()
        if lowercased.contains("san francisco") || lowercased.contains("sf") {
            return .northbound
        } else if lowercased.contains("san jose") || lowercased.contains("gilroy") || lowercased.contains("tamien") {
            return .southbound
        }
        // Default to southbound if we can't determine
        return .southbound
    }

    /// Creates a short destination name from the full destination
    private func shortDestinationName(for destination: String) -> String {
        let lowercased = destination.lowercased()
        if lowercased.contains("san francisco") {
            return "SF"
        } else if lowercased.contains("san jose") {
            return "SJ"
        } else if lowercased.contains("gilroy") {
            return "Gilroy"
        } else if lowercased.contains("tamien") {
            return "Tamien"
        }
        // Return first word or truncate if needed
        let words = destination.split(separator: " ")
        if let first = words.first {
            return String(first.prefix(8))
        }
        return destination.prefix(8).description
    }
}
