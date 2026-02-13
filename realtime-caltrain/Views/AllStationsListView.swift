//
//  AllStationsListView.swift
//  caltrain
//
//  Created by Claude Code on 1/27/26.
//

import SwiftUI
import SwiftData

struct AllStationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CaltrainStation.name) private var stations: [CaltrainStation]
    
    // Group stations by zone number
    var groupedStations: [Int: [CaltrainStation]] {
        Dictionary(grouping: stations, by: { $0.zoneNumber })
    }
    var sortedZones: [Int] {
        groupedStations.keys.sorted()
    }

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
            ForEach(sortedZones, id: \.self) { zone in
                Section {
                    ForEach(groupedStations[zone] ?? []) { station in
                        StationRow(station: station)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleStationSelection(station)
                            }
                    }
                }
                header: { Text("Zone \(zone)")}
            }

            // Legend section
            Section {
                VStack(alignment: .leading, spacing: 12) {
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
            header: { Text("Legend") }
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

@MainActor
struct SampleData {
    static let container: ModelContainer = {
        let schema = Schema([CaltrainStation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        
        let sampleStations = [
            CaltrainStation.exampleStation,
            CaltrainStation.exampleStation2,
        ]
        
        sampleStations.forEach { container.mainContext.insert($0) }
        return container
    }()
}

#Preview {
    NavigationStack {
        AllStationsListView()
            .modelContainer(SampleData.container)
    }
}
