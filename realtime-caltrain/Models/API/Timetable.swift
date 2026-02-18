//
//  Timetable.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/10/26.
//

import Foundation

struct Departure: Decodable {
    let trainNumber: String
    let trainType: TrainType
    let direction: Direction
    let arrivalTime: String
    let departureTime: String
    let destination: String
    let daysOffset: String
    let onWeekdays: Bool
    let onWeekends: Bool

    enum CodingKeys: String, CodingKey {
        case trainNumber = "trainId"
        case trainType = "line"
        case direction = "direction"
        case arrivalTime = "arrivalTime"
        case departureTime = "departureTime"
        case destination = "destination"
        case daysOffset = "daysOffset"
        case onWeekdays = "onWeekdays"
        case onWeekends = "onWeekends"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trainNumber = try container.decode(String.self, forKey: .trainNumber)
        let trainTypeString = try container.decode(String.self, forKey: .trainType)
        trainType = TrainType.from(apiString: trainTypeString)
        direction = try container.decode(Direction.self, forKey: .direction)
        arrivalTime = try container.decode(String.self, forKey: .arrivalTime)
        departureTime = try container.decode(String.self, forKey: .departureTime)
        destination = try container.decode(String.self, forKey: .destination)
        daysOffset = try container.decode(String.self, forKey: .daysOffset)
        onWeekdays = try container.decode(Bool.self, forKey: .onWeekdays)
        onWeekends = try container.decode(Bool.self, forKey: .onWeekends)
    }
}

typealias TimetableResponse = [String: [Departure]]

