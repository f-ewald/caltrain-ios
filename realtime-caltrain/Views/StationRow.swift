//
//  StationRow.swift
//  realtime-caltrain
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
                Text(station.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let zone = station.zoneNumber {
                        Text("Zone \(zone)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if station.hasParking {
                        Image(systemName: "parkingsign.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    if station.hasBikeParking {
                        Image(systemName: "bicycle.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
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
        stationId: "sf",
        name: "San Francisco",
        gtfsStopIdSouth: "70011",
        gtfsStopIdNorth: "70012",
        latitude: 37.7764,
        longitude: -122.3943,
        zoneNumber: 1,
        hasParking: false,
        hasBikeParking: true,
        isFavorite: false
    )

    List {
        StationRow(station: previewStation)
    }
}
