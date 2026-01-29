//
//  AllStationsListView.swift
//  realtime-caltrain
//
//  Created by Claude Code on 1/27/26.
//

import SwiftUI
import SwiftData

struct AllStationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CaltrainStation.name) private var stations: [CaltrainStation]

    var body: some View {
        List {
            // Favorite stations section
            if !favoriteStations.isEmpty {
                Section {
                    ForEach(favoriteStations) { station in
                        StationRow(station: station)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleStationSelection(station)
                            }
                    }
                } header: {
                    Text("Favorites")
                }
            }

            // All stations section (alphabetically)
            Section {
                ForEach(stations) { station in
                    StationRow(station: station)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleStationSelection(station)
                        }
                }
            } header: {
                Text("All Stations")
            }

            // Legend section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Amenities Legend")
                        .font(.headline)
                        .padding(.bottom, 4)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "parkingsign.circle.fill")
                                .foregroundStyle(.blue)
                            Text("123")
                                .font(.caption)
                        }
                        Text("Parking spaces")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "bicycle.circle.fill")
                                .foregroundStyle(.green)
                            Text("45")
                                .font(.caption)
                        }
                        Text("Bike racks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "toilet.circle.fill")
                            .foregroundStyle(.purple)
                        Text("Restrooms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Elevator")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Stations")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var favoriteStations: [CaltrainStation] {
        stations.filter { $0.isFavorite }
    }

    private func handleStationSelection(_ station: CaltrainStation) {
        withAnimation {
            StationSelectionService.selectStation(station, from: stations)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AllStationsListView()
            .modelContainer(for: CaltrainStation.self, inMemory: true)
    }
}
