//
//  ContentView.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Query private var stations: [CaltrainStation]

    @State private var refreshError: Error?
    @State private var showErrorAlert = false
    @State private var isLoadingDepartures = false
    @State private var activeStationId: String?

    private var nearestStation: CaltrainStation? {
        guard let userLocation = locationManager.location else { return nil }
        guard let result = NearestStationService.findNearestStation(
            to: userLocation,
            from: stations
        ) else { return nil }

        // Cache location and nearest station for widget
        LocationCacheService.saveLocation(userLocation, nearestStationId: result.station.stationId)

        return result.station
    }

    private var activeStation: CaltrainStation? {
        // Check if a station is manually selected
        if let selected = StationSelectionService.selectedStation(from: stations) {
            return selected
        }
        return nearestStation
    }

    private var hasSelectedStation: Bool {
        StationSelectionService.selectedStation(from: stations) != nil
    }

    // Fetch departures only for the active station to avoid accessing deleted objects
    private var departures: [TrainDeparture] {
        guard let stationId = activeStationId else { return [] }

        let descriptor = FetchDescriptor<TrainDeparture>(
            predicate: #Predicate { $0.stationId == stationId },
            sortBy: [SortDescriptor(\TrainDeparture.scheduledTime)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
            print("Error fetching departures: \(error)")
            #endif
            return []
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                // Caltrain Header
                Section {
                    VStack(spacing: 8) {
                        Text("CALTRAIN")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.9, green: 0.1, blue: 0.1), Color(red: 0.8, green: 0.0, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Real-time Departures")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)
                    .listRowBackground(Color.clear)
                }

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

                #if DEBUG
                // Debug info section (only in debug builds)
                Section("Debug Info") {
                    Text("Stations loaded: \(stations.count)")
                    Text("Location: \(locationManager.location != nil ? "Available" : "Waiting...")")
                    Text("Active station: \(activeStation?.name ?? "None")")
                    Text("Departures: \(departures.count)")
                    if let lastRefresh = DepartureRefreshState.lastRefresh {
                        Text("Last loaded: \(lastRefresh.formatted(date: .omitted, time: .standard))")
                    } else {
                        Text("Last loaded: Never")
                    }
                }
                #endif

                // Train Logo at the bottom
                Section {
                    VStack {
                        HStack {
                            Spacer()
                            TrainLogo(size: 40, color: Color(red: 0.9, green: 0.1, blue: 0.1))
                            Spacer()
                        }

                        HStack {
                            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                            Spacer()
                            Text("v\(version)").font(.footnote)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
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
                // Set initial active station ID
                activeStationId = activeStation?.stationId
                Task {
                    await loadInitialDepartures()
                }
            }
            .onChange(of: activeStation) { _, newStation in
                // Update active station ID first (this updates the departures query)
                activeStationId = newStation?.stationId
                Task {
                    await loadInitialDepartures()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Location button - jump to nearest station
                        Button {
                            withAnimation {
                                StationSelectionService.clearSelection(from: stations)
                            }
                        } label: {
                            Image(systemName: "location.fill")
                        }
                        .disabled(!hasSelectedStation)
                        .opacity(hasSelectedStation ? 1.0 : 0.3)

                        // Refresh button
                        Button {
                            Task {
                                await refreshDepartures()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .frame(width: 20, height: 20)
                                .rotationEffect(.degrees(isLoadingDepartures ? 360 : 0))
                                .animation(isLoadingDepartures ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingDepartures)
                        }
                        .disabled(isLoadingDepartures)
                    }
                }
            }
        } detail: {
            Text("Real-time Caltrain Departures")
        }
    }

    private func refreshDepartures() async {
        guard !stations.isEmpty else { return }

        isLoadingDepartures = true
        defer { isLoadingDepartures = false }

        do {
            try await DepartureService.refreshAllDepartures(
                allStations: stations,
                modelContext: modelContext
            )
            // Success - SwiftData @Query will auto-update UI

            // Trigger widget reload
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // Show error but keep old data visible
            refreshError = error
            showErrorAlert = true
        }
    }

    private func loadInitialDepartures() async {
        guard !stations.isEmpty else {
            #if DEBUG
            print("⚠️ No stations loaded yet - waiting for station data")
            #endif
            return
        }

        #if DEBUG
        if let station = activeStation {
            print("🚂 Loading departures (active station: \(station.name))")
        } else {
            print("🚂 Loading departures for all stations")
        }
        #endif

        isLoadingDepartures = true
        defer { isLoadingDepartures = false }

        do {
            #if DEBUG
            print("🌐 Fetching from API...")
            #endif
            try await DepartureService.refreshAllDepartures(
                allStations: stations,
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
            // No fallback - just show empty state
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TrainDeparture.self, inMemory: true)
        .environment(LocationManager())
}
