//
//  Timetable.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/10/26.
//

import Foundation

struct Departure: Codable {
    let trainNumber: String
    let trainType: TrainType
    let direction: Direction
    let arrivalTime: String
    let departureTime: String
    let destination: String
    let daysOffset: String
    
    enum CodingKeys: String, CodingKey {
        case trainNumber = "trainId"
        case trainType = "line"
        case direction = "direction"
        case arrivalTime = "arrivalTime"
        case departureTime = "departureTime"
        case destination = "destination"
        case daysOffset = "daysOffset"
    }
}

typealias TimetableResponse = [String: [Departure]]

