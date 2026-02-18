//
//  TrainDeparture.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import Foundation
import SwiftData
import SwiftUI

extension AppSchemaV1 {
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
        
        var isLive: Bool {
            estimatedTime != nil
        }
        
        var delayMinutes: Int {
            guard let estimated = estimatedTime else { return 0 }
            return Int(estimated.timeIntervalSince(scheduledTime) / 60)
        }
        
        static var exampleDeparture1: TrainDeparture {
            TrainDeparture(
                stationId: "station1",
                direction: .northbound,
                destinationName: "San Francisco",
                shortDestinationName: "SF",
                scheduledTime: Date(),
                trainNumber: "151",
                trainType: .local,
                status: .onTime,
                platformNumber: "2"
            )
        }
        
        static var exampleDeparture2: TrainDeparture {
            TrainDeparture(
                stationId: "station1",
                direction: .southbound,
                destinationName: "San Jose",
                shortDestinationName: "SJ",
                scheduledTime: Date().addingTimeInterval(420),
                trainNumber: "221",
                trainType: .express,
                status: .onTime,
                platformNumber: "1"
            )
        }
    }
    
    // MARK: - Direction Enum
    
    enum Direction: String, Codable {
        case northbound = "N "
        case southbound = "S "
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
        case unknown

        var displayName: String {
            switch self {
            case .local: return "Local"
            case .limited: return "Limited"
            case .express: return "Express"
            case .unknown: return "Unkown"
            }
        }

        var color: Color {
            switch self {
            case .local: return .gray
            case .limited: return Color(red:153/255, green: 215/255, blue: 220/255)
            case .express: return .red
            case .unknown: return .gray
            }
        }

        /// Parse a train type string from the API (e.g. "Local", "Express", "Local Weekday")
        static func from(apiString: String) -> TrainType {
            let normalized = apiString.lowercased().trimmingCharacters(in: .whitespaces)
            switch normalized {
            case "local", "local weekday", "local weekend", "south county":
                return .local
            case "limited":
                return .limited
            case "express":
                return .express
            default:
                return .unknown
            }
        }
    }
    
    // MARK: - DepartureStatus Enum
    
    enum DepartureStatus: String, Codable {
        case onTime
        case delayed
        case cancelled
        case live
        
        var displayName: String {
            switch self {
            case .onTime: return "On Time"
            case .delayed: return "Delayed"
            case .cancelled: return "Cancelled"
            case .live: return "Live"
            }
        }
        
        var color: Color {
            switch self {
            case .onTime: return .green
            case .delayed: return .yellow
            case .cancelled: return .red
            case .live: return .blue
            }
        }
        
        var iconName: String {
            switch self {
            case .onTime: return "checkmark.circle.fill"
            case .delayed: return "clock.fill"
            case .cancelled: return "xmark.circle.fill"
            case .live: return "antenna.radiowaves.left.and.right.circle.fill"
            }
        }
    }
}
