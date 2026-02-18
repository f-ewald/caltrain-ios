//
//  ContentView.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI
import SwiftData
import WidgetKit
internal import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Query private var stations: [CaltrainStation]
    
    private var favoriteStations: [CaltrainStation] { stations.filter { $0.isFavorite} }
    private var isWeekend: Bool {
        let currentDay = Calendar.current.component(.weekday, from: Date())
        return currentDay == 1 || currentDay == 7
    }

    @State private var refreshError: Error?
    @State private var showErrorAlert = false
    @State private var isLoadingDepartures = false
    @State private var activeStationId: String?
    
    // Auto-refresh timer
    static let refreshIntervalSeconds = 60
    @State private var secondsUntilRefresh = ContentView.refreshIntervalSeconds
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

    // Fetch planned and real-time departures for the active station
    private var departures: [TrainDeparture] {
        // Load station and return empty list if this fails
        guard let station = activeStation else { return [] }
        
        return DepartureService.upcomingDepartures(modelContext: modelContext, for: station, at: Date())
    }

    var body: some View {
        NavigationSplitView {
            List {
                // Caltrain Header
                Section {
                    VStack(spacing: 8) {
                        Text("Baby Bullet")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.9, green: 0.1, blue: 0.1), Color(red: 0.8, green: 0.0, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Real-time Caltrain Departures")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)
                    .listRowBackground(Color.clear)
                }

                if !favoriteStations.isEmpty {
                    Section {
                        FavoriteScrollView()
                    }
                    header: { Text("Favorite Stations") }
                }
                
                // Active Station Section (selected or nearest)
                ActiveStationSection(
                    userLocation: locationManager.location,
                    stations: stations
                )

                // Departures Section
                DeparturesSection(
                    activeStation: activeStation,
                    departures: departures,
                    isLoading: isLoadingDepartures
                )

                #if DEBUG
                // Debug info section (only in debug builds)
                Section("Debug Info") {
                    HStack {
                        Text("Schedules")
                        Spacer()
                        Text("\(isWeekend ? "Weekend" : "Weekday")")
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Text("Stations loaded")
                        Spacer()
                        Text("\(stations.count)")
                            .foregroundStyle(.gray)
                    }
                    
                    HStack {
                        Text("Location")
                        Spacer()
                        Text("\(locationManager.location != nil ? "Available" : "Waiting...")")
                            .foregroundStyle(.gray)
                    }
                    
                    HStack {
                        Text("Active station")
                        Spacer()
                        Text("\(activeStation?.name ?? "None")")
                            .foregroundStyle(.gray)
                    }
                    
                    HStack {
                        Text("Departures")
                        Spacer()
                        Text("\(departures.count)")
                            .foregroundStyle(.gray)
                    }
                    
                    if let lastRefresh = DepartureRefreshState.lastRefresh {
                        HStack {
                            Text("Last loaded")
                            Spacer()
                            Text("\(lastRefresh.formatted(date: .omitted, time: .standard))")
                                .foregroundStyle(.gray)
                        }
                    } else {
                        HStack {
                            Text("Last loaded")
                            Spacer()
                            Text("Never")
                                .foregroundStyle(.gray)
                        }
                        
                    }
                    HStack {
                        Text("Next refresh")
                        Spacer()
                        Text("\(secondsUntilRefresh)s")
                            .monospacedDigit()
                            .foregroundStyle(.gray)
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
                            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
                            Spacer()
                            Text("v\(version) build \(build)").font(.footnote).foregroundStyle(.gray)
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
            .onReceive(timer) { _ in
                secondsUntilRefresh -= 1
                if secondsUntilRefresh <= 0 {
                    secondsUntilRefresh = Self.refreshIntervalSeconds
                    Task {
                        await refreshRealtimeOnly()
                    }
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
                modelContext: modelContext
            )

            try await DepartureService.refreshPlannedDepartures(modelContext: modelContext)
            // Success - SwiftData @Query will auto-update UI

            // Reset auto-refresh countdown
            secondsUntilRefresh = Self.refreshIntervalSeconds

            // Trigger widget reload
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // Show error but keep old data visible
            refreshError = error
            showErrorAlert = true
        }
    }

    private func refreshRealtimeOnly() async {
        guard !stations.isEmpty, !isLoadingDepartures else { return }

        do {
            try await DepartureService.refreshAllDepartures(
                modelContext: modelContext,
                forceRefresh: true
            )
            withAnimation(.easeInOut(duration: 0.3)) {
                // Trigger SwiftData @Query update with animation
                // The departures computed property will re-evaluate automatically
            }
            // Trigger widget reload
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            #if DEBUG
            print("⏱️ Auto-refresh failed: \(error.localizedDescription)")
            #endif
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
                modelContext: modelContext,
                forceRefresh: true
            )
            // Reset auto-refresh countdown
            secondsUntilRefresh = Self.refreshIntervalSeconds
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
