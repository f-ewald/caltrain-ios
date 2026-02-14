//
//  StationRow.swift
//  caltrain
//
//  Created by Claude Code on 1/27/26.
//

import SwiftUI

struct StationRow: View {
    @Bindable var station: CaltrainStation
    @State private var stationDetailShowing = false

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
                
                ZoneTextView(zone: station.zoneNumber)
                
                Amenities(parkingSpaces: station.parkingSpaces ??  0, bikeRacks: station.bikeRacks ?? 0, hasRestrooms: station.hasRestrooms, hasElevator: station.hasElevator)
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
            .accessibilityIdentifier("station.favorite.\(station.shortCode)")
            
            Button(action: {
                stationDetailShowing.toggle()
            }) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $stationDetailShowing) {
                StationDetail(station: station)
            }
            .accessibilityIdentifier("station.info.\(station.shortCode)")
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
