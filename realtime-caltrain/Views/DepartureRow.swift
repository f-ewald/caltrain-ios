//
//  DepartureRow.swift
//  realtime-caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI

struct DepartureRow: View {
    let departure: TrainDeparture

    var body: some View {
        HStack(spacing: 12) {
            // Left: Time display
            VStack(alignment: .leading, spacing: 2) {
                Text(departure.displayTime, format: .dateTime.hour().minute())
                    .font(.title3)
                    .fontWeight(.semibold)
                    

                if departure.isDelayed {
                    // Status badge with icon
                    HStack(spacing: 4) {
                        Image(systemName: departure.status.iconName)
                            .font(.caption2)
                        Text("+\(departure.delayMinutes) min")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(departure.status.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(departure.status.color.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    // Status badge with icon
                    HStack(spacing: 4) {
                        Image(systemName: departure.status.iconName)
                            .font(.caption2)
                        Text(departure.status.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(departure.status.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(departure.status.color.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .frame(width: 110, alignment: .leading)

            // Middle: Train info
            VStack(alignment: .leading, spacing: 4) {
                Text(departure.destinationName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text("#\(departure.trainNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(departure.trainType.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(departure.trainType.color.opacity(0.2))
                        .foregroundStyle(departure.trainType.color)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Right: Platform and status
            VStack(alignment: .trailing, spacing: 4) {
                if let platform = departure.platformNumber {
                    HStack(spacing: 4) {
                        Text("Platform")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(platform)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        // On Time
        DepartureRow(departure: TrainDeparture(
            departureId: "1",
            stationId: "station1",
            direction: .northbound,
            destinationName: "San Francisco",
            scheduledTime: Date().addingTimeInterval(300),
            trainNumber: "151",
            trainType: .local,
            status: .onTime,
            platformNumber: "2"
        ))

        // Delayed
        DepartureRow(departure: TrainDeparture(
            departureId: "2",
            stationId: "station1",
            direction: .northbound,
            destinationName: "San Francisco",
            scheduledTime: Date().addingTimeInterval(600),
            estimatedTime: Date().addingTimeInterval(780), // 3 min delay
            trainNumber: "152",
            trainType: .limited,
            status: .delayed,
            platformNumber: "2"
        ))

        // On Time (Baby Bullet)
        DepartureRow(departure: TrainDeparture(
            departureId: "3",
            stationId: "station1",
            direction: .southbound,
            destinationName: "San Jose",
            scheduledTime: Date().addingTimeInterval(900),
            trainNumber: "221",
            trainType: .express,
            status: .onTime,
            platformNumber: "1"
        ))

        // Cancelled
        DepartureRow(departure: TrainDeparture(
            departureId: "4",
            stationId: "station1",
            direction: .southbound,
            destinationName: "Tamien",
            scheduledTime: Date().addingTimeInterval(1200),
            trainNumber: "227",
            trainType: .local,
            status: .cancelled,
            platformNumber: "1"
        ))
    }
}
