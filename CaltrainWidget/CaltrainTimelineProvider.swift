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
        guard let station = loadCurrentStation(context: modelContext) else {
            return self.retryTimeline(for: configuration)
        }
        
        let departures = DepartureService.upcomingDepartures(modelContext: modelContext, for: station, at: now)
        let northboundDepartures = departures.filter({ $0.direction == .northbound })
        let southboundDepartures = departures.filter({ $0.direction == .southbound })
        
        
        for departure in departures {
            // Define the time when the widget should be updated
            let future = departure.departureTime
            
            let northboundFiltered: [TrainDeparture] = northboundDepartures.filter { departure in
                return departure.departureTime > future
            }
            
            let southboundFiltered: [TrainDeparture] = southboundDepartures.filter { departure in
                return departure.departureTime > future
            }
            
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
        
        
//        for i in 0...24 {
//            let future = Calendar.current.date(byAdding: .hour, value: i, to: now) ?? now
//            entries.append(CaltrainWidgetEntry(
//                date: future,
//                configuration: configuration,
//                station: station,
//                northboundDepartures: departures[.northbound] ?? [],
//                southboundDepartures: departures[.southbound] ?? [],
//                error: .none,
//                debugMessage: String(format: "%d", i))
//            )
//            #if DEBUG
//            print(String(format: "WIDGET: Added entry %d with date: %@", i, future.formatted(date: .omitted, time: .complete)))
//            #endif
//        }
//        
        
//        let nextUpdateNorthbound = departures[.northbound]?.first!.departureTime ?? Calendar.current.date(byAdding: .minute, value: 15, to: now)!
//        let nextUpdateSouthbound = departures[.southbound]?.first?.departureTime ?? Calendar.current.date(byAdding: .minute, value: 15, to: now)!
//        let nextUpdate = min(nextUpdateNorthbound, nextUpdateSouthbound)
        
        #if DEBUG
//        print(String(format: "WIDGET: %d northbound departures, %d southbound departures",
//                     departures[.northbound]?.count ?? 0,
//                     departures[.southbound]?.count ?? 0,
//                    ))
//        print(String(format: "WIDGET: It is now %@, running next update at %@",
//                     now.formatted(date: .omitted, time: .complete),
//                     nextUpdate.formatted(date: .omitted, time: .complete)
//                     )
//        )
        #endif

        // Update every minute
//        let nextUpdate: Date = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
        let timeline = Timeline(
            entries: entries,
            policy: .never)
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
    
    /// Load current station if set
    private func loadCurrentStation(context: ModelContext) -> CaltrainStation? {
        let stationId = LocationCacheService.cachedNearestStationId()
        let allStations = loadAllStations(context: context)
        let station = allStations.first { $0.stationId == stationId }
        return station
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
