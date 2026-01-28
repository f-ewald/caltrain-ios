//
//  ContentView.swift
//  realtime-caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Query private var departures: [TrainDeparture]
    @Query private var stations: [CaltrainStation]

    @State private var refreshError: Error?
    @State private var showErrorAlert = false
    @State private var isLoadingDepartures = false

    private var nearestStation: CaltrainStation? {
        guard let userLocation = locationManager.location else { return nil }
        return NearestStationService.findNearestStation(
            to: userLocation,
            from: stations
        )?.station
    }

    private var activeStation: CaltrainStation? {
        // TODO: Add support for selected station when manual selection is implemented
        return nearestStation
    }

    var body: some View {
        NavigationSplitView {
            List {
                #if DEBUG
                // Debug info section (only in debug builds)
                Section("Debug Info") {
                    Text("Stations loaded: \(stations.count)")
                    Text("Location: \(locationManager.location != nil ? "Available" : "Waiting...")")
                    Text("Active station: \(activeStation?.name ?? "None")")
                    Text("Departures: \(departures.count)")
                }
                #endif

                // Active Station Section (selected or nearest)
                ActiveStationSection(
                    userLocation: locationManager.location,
                    stations: stations
                )

                // Departures Section (replaces Items)
                DeparturesSection(
                    activeStation: activeStation,
                    departures: departures,
                    isLoading: isLoadingDepartures
                )
            }
            .refreshable {
                await refreshDepartures()
            }
            .alert("Unable to Refresh", isPresented: $showErrorAlert, presenting: refreshError) { _ in
                Button("OK") {
                    refreshError = nil
                    showErrorAlert = false
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onAppear {
                Task {
                    await loadInitialDepartures()
                }
            }
            .onChange(of: activeStation) { _, newStation in
                Task {
                    await loadInitialDepartures()
                }
            }
        } detail: {
            Text("Real-time Caltrain Departures")
        }
    }

    private func refreshDepartures() async {
        guard let station = activeStation else { return }

        isLoadingDepartures = true
        defer { isLoadingDepartures = false }

        do {
            try await DepartureService.refreshDepartures(
                for: station,
                modelContext: modelContext
            )
            // Success - SwiftData @Query will auto-update UI
        } catch {
            // Show error but keep old data visible
            refreshError = error
            showErrorAlert = true
        }
    }

    private func loadInitialDepartures() async {
        guard let station = activeStation else {
            #if DEBUG
            print("⚠️ No active station - waiting for location or station selection")
            #endif

            // If no location yet, load mock data for first available station as fallback
            if let firstStation = stations.first {
                #if DEBUG
                print("📍 Loading mock data for fallback station: \(firstStation.name)")
                #endif
                DepartureService.loadMockDeparturesIfNeeded(
                    for: firstStation,
                    modelContext: modelContext
                )
            }
            return
        }

        #if DEBUG
        print("🚂 Loading departures for: \(station.name)")
        #endif

        isLoadingDepartures = true
        defer { isLoadingDepartures = false }

        // Try API first
        do {
            #if DEBUG
            print("🌐 Fetching from API...")
            #endif
            try await DepartureService.refreshDepartures(
                for: station,
                modelContext: modelContext,
                forceRefresh: true
            )
            #if DEBUG
            print("✅ API fetch successful")
            #endif
        } catch {
            #if DEBUG
            print("❌ API fetch failed: \(error.localizedDescription)")
            #endif
            // Fallback to mock data on error
            DepartureService.loadMockDeparturesIfNeeded(
                for: station,
                modelContext: modelContext
            )
            #if DEBUG
            print("📝 Loaded mock data as fallback")
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TrainDeparture.self, inMemory: true)
        .environment(LocationManager())
}
