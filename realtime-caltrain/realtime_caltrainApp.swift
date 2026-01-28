//
//  realtime_caltrainApp.swift
//  realtime-caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI
import SwiftData

@main
struct realtime_caltrainApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrainDeparture.self,
            CaltrainStation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, provide helpful error message
            print("❌ ModelContainer creation failed: \(error)")
            print("💡 Solution: Delete the app from simulator or run: xcrun simctl erase all")
            print("   (Schema changed - added lastRefreshed to CaltrainStation)")
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
                    StationDataLoader.loadStationsIfNeeded(
                        modelContext: sharedModelContainer.mainContext
                    )
                    #if DEBUG
                    print("✅ Station loading complete")
                    #endif
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
