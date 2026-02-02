//
//  StationRow.swift
//  caltrain
//
//  Created by Claude Code on 1/27/26.
//

import SwiftUI

struct StationRow: View {
    @Bindable var station: CaltrainStation

    var body: some View {
        HStack(spacing: 12) {
            // Station info
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(station.name)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(station.shortCode)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(3)
                }

                HStack(spacing: 8) {
                    if let zone = station.zoneNumber {
                        Text("Zone \(zone)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let parkingSpaces = station.parkingSpaces, parkingSpaces > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "parkingsign.circle.fill")
                            Text("\(parkingSpaces)")
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }

                    if let bikeRacks = station.bikeRacks, bikeRacks > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bicycle.circle.fill")
                            Text("\(bikeRacks)")
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                    }

                    if station.hasRestrooms {
                        Image(systemName: "toilet.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }

                    if station.hasElevator {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Selection indicator (checkmark)
            if station.isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }

            // Favorite toggle button
            Button {
                withAnimation {
                    station.isFavorite.toggle()
                }
            } label: {
                Image(systemName: station.isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(station.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let previewStation = CaltrainStation(
        stationId: "palo_alto",
        name: "Palo Alto",
        shortCode: "PA",
        gtfsStopIdSouth: "70171",
        gtfsStopIdNorth: "70172",
        latitude: 37.4432,
        longitude: -122.1649,
        zoneNumber: 3,
        hasParking: true,
        hasBikeParking: true,
        parkingSpaces: 389,
        bikeRacks: 178,
        hasBikeLockers: true,
        hasRestrooms: true,
        ticketMachines: 6,
        hasElevator: false,
        isFavorite: false
    )

    List {
        StationRow(station: previewStation)
    }
}
