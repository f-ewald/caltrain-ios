//
//  ActiveStationSection.swift
//  realtime-caltrain
//
//  Created by Claude Code on 1/27/26.
//

import SwiftUI
import CoreLocation

struct ActiveStationSection: View {
    let userLocation: CLLocation?
    let stations: [CaltrainStation]

    @State private var nearestStation: (station: CaltrainStation, distance: CLLocationDistance)?

    // Computed property for selected station
    private var selectedStation: CaltrainStation? {
        StationSelectionService.selectedStation(from: stations)
    }

    // Display mode enum to represent different states
    private enum DisplayMode {
        case selected(CaltrainStation)
        case nearest(CaltrainStation, CLLocationDistance)
        case loading
        case error(String)
    }

    // Determine what to display based on priority
    private var displayMode: DisplayMode {
        // Priority: Selected station > Nearest station
        if let selected = selectedStation {
            return .selected(selected)
        } else if let nearest = nearestStation {
            return .nearest(nearest.station, nearest.distance)
        } else if userLocation == nil {
            return .loading
        } else if stations.isEmpty {
            return .error("Station data unavailable")
        } else {
            return .error("Unable to determine nearest station")
        }
    }

    var body: some View {
        Section {
            switch displayMode {
            case .selected(let station):
                // Selected station - tappable to clear selection
                Button {
                    withAnimation {
                        StationSelectionService.clearSelection(from: stations)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(station.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        HStack {
                            Image(systemName: "pin.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Tap to use nearest instead")
                                .foregroundStyle(.secondary)
                        }

                        if let zone = station.zoneNumber {
                            Text("Zone \(zone)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

            case .nearest(let station, let distance):
                // Nearest station - navigation link to all stations
                NavigationLink {
                    AllStationsListView()
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(station.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.blue)
                            Text(NearestStationService.formatDistance(distance))
                                .foregroundStyle(.secondary)
                        }

                        if let zone = station.zoneNumber {
                            Text("Zone \(zone)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 8)
                }

            case .loading:
                // No location yet
                HStack {
                    ProgressView()
                    Text("Finding your location...")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

            case .error(let message):
                // Error state
                Text(message)
                    .foregroundStyle(.red)
                    .padding(.vertical, 8)
            }
        } header: {
            // Dynamic header based on display mode
            Text(selectedStation != nil ? "Selected Station" : "Nearest Station")
        }
        .onChange(of: userLocation) { _, newLocation in
            updateNearestStation(newLocation)
        }
        .onAppear {
            updateNearestStation(userLocation)
        }
    }

    private func updateNearestStation(_ location: CLLocation?) {
        // Return early if a station is selected (don't recalculate nearest)
        if selectedStation != nil {
            return
        }

        guard let location = location, !stations.isEmpty else {
            nearestStation = nil
            return
        }

        nearestStation = NearestStationService.findNearestStation(
            to: location,
            from: stations
        )
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
        zoneNumber: 1
    )

    NavigationStack {
        List {
            ActiveStationSection(
                userLocation: CLLocation(latitude: 37.7749, longitude: -122.4194),
                stations: [previewStation]
            )
        }
    }
}
