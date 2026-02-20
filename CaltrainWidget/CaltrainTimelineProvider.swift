//
//  CaltrainTimelineProvider.swift
//  CaltrainWidget
//
//  Provides timeline entries for widget updates
//

import WidgetKit
import SwiftData
import CoreLocation

struct CaltrainTimelineProvider: AppIntentTimelineProvider {
    func snapshot(for configuration: CaltrainConfigurationIntent, in context: Context) async -> CaltrainWidgetEntry {
        CaltrainWidgetEntry.sample
    }
    
    func timeline(for configuration: CaltrainConfigurationIntent, in context: Context) async -> Timeline<CaltrainWidgetEntry> {
        let now: Date = Date()
        var entries: [CaltrainWidgetEntry] = []
        
        guard let container = try? SharedModelContainer.create() else {
            return self.retryTimeline(for: configuration)
        }
        let modelContext = ModelContext(container)
        guard let station = loadCurrentStation(context: modelContext, configuration: configuration) else {
            return self.retryTimeline(for: configuration)
        }
        
        let departures = DepartureService.upcomingDepartures(modelContext: modelContext, for: station, at: now)
        let northboundDepartures = departures.filter({ $0.direction == .northbound })
        let southboundDepartures = departures.filter({ $0.direction == .southbound })
        
        // The next time when the widget needs to fetch fresh data.
        // This time is calculated dynamically whenever one of the departures (nortbound or southbound)
        // has less than 3 departures left.
        var nextUpdateTime = Date()
        
        for departure in departures {
            // Define the time when the widget should be updated
            let future = departure.departureTime
            
            let northboundFiltered: [TrainDeparture] = northboundDepartures.filter { departure in
                return departure.departureTime > future
            }
            
            let southboundFiltered: [TrainDeparture] = southboundDepartures.filter { departure in
                return departure.departureTime > future
            }
            
            if northboundFiltered.count < 3 || southboundFiltered.count < 3 {
                // At this point there are too few future entries remaining and we need to
                // call the widget again.
                break
            }
            // Update the next update time only if there are enough entries available
            nextUpdateTime = future
            
            #if DEBUG
            print(String(format: "WIDGET: Departure at %@, northbound: %d, southbound: %d",
                         future.formatted(date: .omitted, time: .complete),
                         northboundFiltered.count,
                         southboundFiltered.count,
                        ))
            #endif

            entries.append(CaltrainWidgetEntry(
                date: future,
                configuration: configuration,
                station: station,
                northboundDepartures: northboundFiltered,
                southboundDepartures: southboundFiltered,
                error: .none,
                debugMessage: nil)
            )
        }
        
        let timeline = Timeline(
            entries: entries,
            policy: .after(nextUpdateTime))
        return timeline
    }
    
    typealias Intent = CaltrainConfigurationIntent
    
    typealias Entry = CaltrainWidgetEntry

    func placeholder(in context: Context) -> CaltrainWidgetEntry {
        CaltrainWidgetEntry.placeholder
    }
    
    /// An empty timeline that retries after 5 minutes from now.
    private func retryTimeline(for configuration: CaltrainConfigurationIntent) -> Timeline<CaltrainWidgetEntry> {
        let now: Date = Date()
        return Timeline(
            entries: [CaltrainWidgetEntry(
                date: now,
                configuration: configuration,
                station: nil,
                northboundDepartures: [],
                southboundDepartures: [],
                error: .noData,
                debugMessage: nil,
            )],
            policy: .after(now.addingTimeInterval(300))
        )
    }
    
    /// Load all available Caltrain stations
    private func loadAllStations(context: ModelContext) -> [CaltrainStation] {
        let allStationsDescriptor = FetchDescriptor<CaltrainStation>()
        guard let allStations = try? context.fetch(allStationsDescriptor),
              !allStations.isEmpty else { return [] }
        return allStations
    }
    
    /// Load current station based on widget configuration.
    /// If the user selected a specific station, use that; otherwise fall back to nearest station.
    private func loadCurrentStation(context: ModelContext, configuration: CaltrainConfigurationIntent) -> CaltrainStation? {
        let allStations = loadAllStations(context: context)

        // If user selected a specific station (not "Nearest Station"), use it
        if let selectedStation = configuration.station,
           selectedStation.id != "_my_location_" {
            return allStations.first { $0.stationId == selectedStation.id }
        }

        // Fall back to cached nearest station
        let stationId = LocationCacheService.cachedNearestStationId()
        return allStations.first { $0.stationId == stationId }
    }
    
    /// Load Northbound and southbound departures for a given station at a given date.
    private func loadDepartures(context: ModelContext, at date: Date) async -> [Direction: [TrainDeparture]] {
        let stationId = LocationCacheService.cachedNearestStationId() ?? ""
        
        // Try to refresh departures from API for ALL stations (respects global throttling)
        do {
            try await DepartureService.refreshAllDepartures(
                modelContext: context
            )
        } catch {
            // If refresh fails, we'll use cached data
            #if DEBUG
            print("Widget: API refresh failed, using cached data: \(error)")
            #endif
            return [:]
        }
        
        // Fetch departures from SwiftData
        let departureDescriptor = FetchDescriptor<TrainDeparture>(
            predicate: #Predicate {
                $0.stationId == stationId
            },
            sortBy: [SortDescriptor(\TrainDeparture.scheduledTime)]
        )

        guard let departures = try? context.fetch(departureDescriptor) else { return [:] }
        // Filter to upcoming departures only (next 2 hours)
//        let twoHoursFromNow = date.addingTimeInterval(7200)
//        let upcomingDepartures = departures.filter { departure in
//            let departureTime = departure.estimatedTime ?? departure.scheduledTime
//            return departureTime > date && departureTime <= twoHoursFromNow
//        }
        let upcomingDepartures = departures

        // Split by direction and take first 3 of each
        let northbound = upcomingDepartures
            .filter { $0.direction == .northbound }
            //.prefix(3)
            .map { $0 }

        let southbound = upcomingDepartures
            .filter { $0.direction == .southbound }
            //.prefix(3)
            .map { $0 }
        
        return [
            .northbound: northbound,
            .southbound: southbound,
            .combined: upcomingDepartures,
        ]
    }
}
