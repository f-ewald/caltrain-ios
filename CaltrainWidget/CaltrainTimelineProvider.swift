//
//  CaltrainTimelineProvider.swift
//  CaltrainWidget
//
//  Provides timeline entries for widget updates
//

import WidgetKit
import SwiftData
import CoreLocation

struct CaltrainTimelineProvider: TimelineProvider {
    typealias Entry = CaltrainWidgetEntry

    func placeholder(in context: Context) -> CaltrainWidgetEntry {
        CaltrainWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CaltrainWidgetEntry) -> Void) {
        if context.isPreview {
            completion(CaltrainWidgetEntry.sample)
        } else {
            Task {
                let entry = await fetchAndCreateEntry()
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaltrainWidgetEntry>) -> Void) {
        Task {
            let entry = await fetchAndCreateEntry()

            // Update every 2 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 2, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func fetchAndCreateEntry() async -> CaltrainWidgetEntry {
        // Get shared model container
        guard let container = try? SharedModelContainer.create() else {
            return CaltrainWidgetEntry(
                date: Date(),
                station: nil,
                northboundDepartures: [],
                southboundDepartures: [],
                error: .apiError
            )
        }

        let modelContext = ModelContext(container)

        // Get cached nearest station ID
        guard let cachedStationId = LocationCacheService.cachedNearestStationId() else {
            return CaltrainWidgetEntry(
                date: Date(),
                station: nil,
                northboundDepartures: [],
                southboundDepartures: [],
                error: .noLocation
            )
        }

        // Note: We no longer check if cache is stale - we'll attempt to fetch fresh data
        // and fall back to cached data if the fetch fails

        // Fetch ALL stations from SwiftData
        let allStationsDescriptor = FetchDescriptor<CaltrainStation>()
        guard let allStations = try? modelContext.fetch(allStationsDescriptor),
              !allStations.isEmpty else {
            return CaltrainWidgetEntry(
                date: Date(),
                station: nil,
                northboundDepartures: [],
                southboundDepartures: [],
                error: .noStation
            )
        }

        // Find the cached station for display
        let station = allStations.first { $0.stationId == cachedStationId }
        guard station != nil else {
            return CaltrainWidgetEntry(
                date: Date(),
                station: nil,
                northboundDepartures: [],
                southboundDepartures: [],
                error: .noStation
            )
        }

        // Try to refresh departures from API for ALL stations (respects global throttling)
        do {
            try await DepartureService.refreshAllDepartures(
                allStations: allStations,
                modelContext: modelContext
            )
        } catch {
            // If refresh fails, we'll use cached data
            #if DEBUG
            print("Widget: API refresh failed, using cached data: \(error)")
            #endif
        }

        // Fetch departures from SwiftData
        let departureDescriptor = FetchDescriptor<TrainDeparture>(
            predicate: #Predicate {
                $0.stationId == cachedStationId
            },
            sortBy: [SortDescriptor(\TrainDeparture.scheduledTime)]
        )

        guard let departures = try? modelContext.fetch(departureDescriptor) else {
            return CaltrainWidgetEntry(
                date: Date(),
                station: station,
                northboundDepartures: [],
                southboundDepartures: [],
                error: .noData
            )
        }

        // Filter to upcoming departures only (next 2 hours)
        let now = Date()
        let twoHoursFromNow = now.addingTimeInterval(7200)
        let upcomingDepartures = departures.filter { departure in
            let departureTime = departure.estimatedTime ?? departure.scheduledTime
            return departureTime > now && departureTime <= twoHoursFromNow
        }

        // Split by direction and take first 3 of each
        let northbound = upcomingDepartures
            .filter { $0.direction == .northbound }
            .prefix(3)
            .map { $0 }

        let southbound = upcomingDepartures
            .filter { $0.direction == .southbound }
            .prefix(3)
            .map { $0 }

        return CaltrainWidgetEntry(
            date: now,
            station: station,
            northboundDepartures: Array(northbound),
            southboundDepartures: Array(southbound),
            error: nil
        )
    }
}
