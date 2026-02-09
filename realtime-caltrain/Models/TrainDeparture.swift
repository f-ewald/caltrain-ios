//
//  TrainDeparture.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TrainDeparture {
    var stationId: String
    var direction: Direction
    var destinationName: String
    var shortDestinationName: String
    var scheduledTime: Date
    var estimatedTime: Date?
    var trainNumber: String
    var trainType: TrainType
    var status: DepartureStatus
    var platformNumber: String?

    init(
        stationId: String,
        direction: Direction,
        destinationName: String,
        shortDestinationName: String,
        scheduledTime: Date,
        estimatedTime: Date? = nil,
        trainNumber: String,
        trainType: TrainType,
        status: DepartureStatus,
        platformNumber: String? = nil
    ) {
        self.stationId = stationId
        self.direction = direction
        self.destinationName = destinationName
        self.shortDestinationName = shortDestinationName
        self.scheduledTime = scheduledTime
        self.estimatedTime = estimatedTime
        self.trainNumber = trainNumber
        self.trainType = trainType
        self.status = status
        self.platformNumber = platformNumber
    }

    // MARK: - Computed Properties
    
    /// The actual departure time of the train. Either the estimated time or the scheduled time, if the estimated time is unavailable.
    var departureTime: Date {
        estimatedTime ?? scheduledTime
    }

    var displayTime: Date {
        estimatedTime ?? scheduledTime
    }

    var isDelayed: Bool {
        guard let estimated = estimatedTime else { return false }
        return estimated > scheduledTime
    }

    var delayMinutes: Int {
        guard let estimated = estimatedTime else { return 0 }
        return Int(estimated.timeIntervalSince(scheduledTime) / 60)
    }
}

// MARK: - Direction Enum

enum Direction: String, Codable {
    case northbound
    case southbound
    case combined

    var displayName: String {
        switch self {
        case .northbound: 
            return "Northbound"
        case .southbound: 
            return "Southbound"
        case .combined:
            return "Combined"
        }
    }

    var iconName: String {
        switch self {
        case .northbound: "arrow.up.circle.fill"
        case .southbound: "arrow.down.circle.fill"
        case .combined: "arrow.right.circle.fill"
        }
    }
    
    var terminus: String {
        switch self {
        case .northbound: "San Francisco"
        case .southbound: "San Jose/Gilroy"
        case .combined: "SF/SJ"
        }
    }
}

// MARK: - TrainType Enum

enum TrainType: String, Codable {
    case local
    case limited
    case express

    var displayName: String {
        switch self {
        case .local: return "Local"
        case .limited: return "Limited"
        case .express: return "Express"
        }
    }

    var color: Color {
        switch self {
        case .local: return .gray
        case .limited: return Color(red:153/255, green: 215/255, blue: 220/255)
        case .express: return .red
        }
    }
}

// MARK: - DepartureStatus Enum

enum DepartureStatus: String, Codable {
    case onTime
    case delayed
    case cancelled

    var displayName: String {
        switch self {
        case .onTime: return "On Time"
        case .delayed: return "Delayed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .onTime: return .green
        case .delayed: return .orange
        case .cancelled: return .red
        }
    }

    var iconName: String {
        switch self {
        case .onTime: return "checkmark.circle.fill"
        case .delayed: return "clock.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}
