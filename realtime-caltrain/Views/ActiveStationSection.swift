//
//  ActiveStationSection.swift
//  caltrain
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
                NavigationLink {
                    AllStationsListView()
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(station.name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        ZoneTextView(zone: station.zoneNumber)
                    }
                    .padding(.vertical, 8)
                }
                Amenities(parkingSpaces: station.parkingSpaces ?? 0, bikeRacks: station.bikeRacks ?? 0, hasRestrooms: station.hasElevator, hasElevator: station.hasElevator)
                
            case .nearest(let station, let distance):
                // Nearest station - navigation link to all stations
                NavigationLink {
                    AllStationsListView()
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(station.name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        // Zone should be on new line because some station names are long.
                        ZoneTextView(zone: station.zoneNumber)
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                
                            Text(NearestStationService.formatDistance(distance))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                // For UI Test
                .accessibilityIdentifier("station.nearest")
                
                Amenities(parkingSpaces: station.parkingSpaces ?? 0, bikeRacks: station.bikeRacks ?? 0, hasRestrooms: station.hasElevator, hasElevator: station.hasElevator)
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

#Preview("Nearest Station") {
    NavigationStack {
        List {
            ActiveStationSection(
                userLocation: CLLocation(latitude: 37.7749, longitude: -122.4194),
                stations: [CaltrainStation.exampleStation]
            )
            
        }
    }
}

#Preview("Selected Station") {
    NavigationStack {
        List {
            ActiveStationSection(
                userLocation: CLLocation(latitude: 37.7749, longitude: -122.4194),
                stations: [CaltrainStation.exampleStation]
            )
        }
    }
}
