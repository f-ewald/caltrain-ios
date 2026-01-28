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
