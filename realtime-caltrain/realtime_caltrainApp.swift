//
//  realtime_caltrainApp.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI
import SwiftData

@main
struct realtime_caltrainApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.create()
        } catch {
            // If creation fails, provide helpful error message
            print("❌ ModelContainer creation failed: \(error)")
            print("💡 Solution: Delete the app from simulator or run: xcrun simctl erase all")
            print("   Common causes: App Group not configured or schema migration issue")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .onAppear {
                    #if DEBUG
                    print("🚀 App started")
                    #endif

                    // Request location permission on first launch
                    #if DEBUG
                    print("📍 Requesting location permission...")
                    #endif
                    locationManager.requestPermission()

                    // Load stations on first launch
                    #if DEBUG
                    print("🗺️ Loading station data...")
                    #endif
                    
                    Task {
                        do {
                            try await CaltrainAPIClient().fetchTimetable()
                        } catch {
                            print(error)
                        }
                    }
                    
                    // TODO: Load station data from API instead of shipping with the app
//                    Task {
//                        do {
//                            try await StationService(apiClient: CaltrainAPIClient()).refreshStations(modelContext: sharedModelContainer.mainContext)
//                        } catch APIError.invalidResponse {
//
//                        } catch {
//                            #if DEBUG
//                            print(String(format: "Failed to load station data: %@", error as CVarArg))
//                            #endif
//                        }
//                    }
                    
                    StationDataLoader.loadStationsIfNeeded(
                        modelContext: sharedModelContainer.mainContext
                    )
                    #if DEBUG
                    print("✅ Station loading complete")
                    #endif
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Resume location updates when app becomes active
                if locationManager.isAuthorized {
                    #if DEBUG
                    print("📍 App active - resuming location updates")
                    #endif
                    locationManager.startUpdating()
                }
            case .background:
                // Stop location updates to save battery when app enters background
                #if DEBUG
                print("📍 App background - stopping location updates")
                #endif
                locationManager.stopUpdating()
            case .inactive:
                // Don't stop updates during temporary inactive state (e.g., during app switching)
                break
            @unknown default:
                break
            }
        }
    }
}
