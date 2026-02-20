//
//  CaltrainWidgetView.swift
//  CaltrainWidget
//
//  Main widget view with size-specific layouts
//

import SwiftUI
import WidgetKit

struct CaltrainWidgetView: View {
    let entry: CaltrainWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if let error = entry.error {
            ErrorView(error: error)
        } else {
            switch widgetFamily {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: Live hint

/// Prompt the user to tap the widget
struct LiveHintView: View {
    var body: some View {
        Text("Tap on the widget to view live departure times")
            .foregroundStyle(.tertiary)
            .font(.system(size: 8))
            .padding(.bottom, 4)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: CaltrainWidgetEntry
    let numDepartures: Int = 3

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetHeaderView(entry: entry)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()
            
            
            let nbDepartures = DirectionSection(
                direction: .northbound,
                departures: entry.northboundDepartures,
                isCompact: true,
                shortStationCode: true,
                numDepartures: numDepartures,
            )
            let sbDepartures = DirectionSection(
                direction: .southbound,
                departures: entry.southboundDepartures,
                isCompact: true,
                shortStationCode: true,
                numDepartures: numDepartures,
            )

            // Departures in two columns
            HStack(spacing: 0) {
                if entry.configuration.direction == .both {
                    // Northbound
                    nbDepartures
                    Divider()
                    sbDepartures
                    // Southbound
                    
                } else if entry.configuration.direction == .north {
                    // Only northbound connections
                    nbDepartures
                } else if entry.configuration.direction == .south {
                    // Only southbound connections
                    sbDepartures
                }
            }
            .padding(.vertical, 8)
            
            LiveHintView()
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: CaltrainWidgetEntry
    
    // Dynamically change number of departures, depending on direction view.
    var numDepartures: Int {
        entry.configuration.direction == .both ? 4 : 8
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetHeaderView(entry: entry)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()
            
            // Northbound section
            let nbDirectionSection = DirectionSection(
                direction: .northbound,
                departures: entry.northboundDepartures,
                isCompact: false,
                shortStationCode: false,
                numDepartures: numDepartures,
            )
                .padding(.top, 6)
            
            // Southbound section
            let sbDirectionSection = DirectionSection(
                direction: .southbound,
                departures: entry.southboundDepartures,
                isCompact: false,
                shortStationCode: false,
                numDepartures: numDepartures,
            )
                .padding(.top, 6)
            
            
            if entry.configuration.direction == .both {
                nbDirectionSection
                Divider()
                sbDirectionSection
            } else if entry.configuration.direction == .north {
                nbDirectionSection
            } else {
                sbDirectionSection
            }
            
            LiveHintView()
        }
    }
}

// MARK: - Widget Header

struct WidgetHeaderView: View {
    let entry: CaltrainWidgetEntry?

    var body: some View {
        HStack {
            // Caltrain logo/text
            let header: String = "CALTRAIN DEPARTURES"

            Text(header)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.9, green: 0.1, blue: 0.1), Color(red: 0.8, green: 0.0, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineLimit(1)
                .truncationMode(.tail)
            
            #if DEBUG
            // Show the last update date if debug is enabled
            Text(entry!.date, style: .time)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            #endif
            
            Spacer()

            // Station name
            if let station = entry?.station {
                // Show location icon only when using "My Location" option
                let isUsingMyLocation = entry?.configuration.station?.id == "_my_location_"
                    || entry?.configuration.station == nil  // Backward compatibility
                let systemImage = isUsingMyLocation ? "location.fill" : ""
                Label(station.name, systemImage: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}

// MARK: - Direction Section

struct DirectionSection: View {
    let direction: Direction
    let departures: [TrainDeparture]
    let isCompact: Bool
    let shortStationCode: Bool
    let numDepartures: Int
    
    /// Filter maximum number of departures depending on display size
    var displayedDepartures: [TrainDeparture] {
        // Large widgets have one more space
        Array(departures.prefix(numDepartures))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Direction header
            HStack {
                Image(systemName: direction == .northbound ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(direction == .northbound ? "Northbound" : "Southbound")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.bottom, 2)

            // Departures list
            if departures.isEmpty {
                Text("No departures")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, isCompact ? 12 : 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            } else {
                VStack(spacing: isCompact ? 4 : 6) {
                    ForEach(displayedDepartures, id: \.trainNumber) { departure in
                        if isCompact {
                            CompactDepartureRow(departure: departure, shortStationCode: shortStationCode)
                        } else {
                            ExtendedDepartureRow(departure: departure)
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Compact Departure Row (for Medium widget)

struct CompactDepartureRow: View {
    let departure: TrainDeparture
    let shortStationCode: Bool

    private var departureTime: Date {
        departure.estimatedTime ?? departure.scheduledTime
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: departureTime)
    }

    private var minutesUntilDeparture: Int {
        Int(departureTime.timeIntervalSince(Date()) / 60)
    }

    var body: some View {
        HStack(spacing: 6) {
            // Time
            VStack(alignment: .leading, spacing: 0) {
                Text(timeString)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: 60, alignment: .leading)

            // Destination (truncated)
            Text(shortStationCode ? departure.shortDestinationName : departure.destinationName)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(departure.trainType.color)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text("#\(departure.trainNumber)")
                .foregroundStyle(.secondary)
                .font(.system(size: 10))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}

// MARK: - Extended Departure Row (for Large widget)

struct ExtendedDepartureRow: View {
    let departure: TrainDeparture

    private var departureTime: Date {
        departure.estimatedTime ?? departure.scheduledTime
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: departureTime)
    }

    private var minutesUntilDeparture: Int {
        Int(departureTime.timeIntervalSince(Date()) / 60)
    }

    private var statusText: String {
        switch departure.status {
        case .onTime:
            return "On time"
        case .delayed:
            if let estimated = departure.estimatedTime {
                let delayMinutes = Int(estimated.timeIntervalSince(departure.scheduledTime) / 60)
                return "\(delayMinutes)m late"
            }
            return "Delayed"
        case .cancelled:
            return "Cancelled"
        case .live:
            return "Live"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time and countdown
            VStack(alignment: .leading, spacing: 2) {
                Text(timeString)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: 60, alignment: .leading)

            // Train details
            HStack(spacing: 2) {
                Text("Train #\(departure.trainNumber)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(departure.destinationName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(departure.trainType.color)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Train Type Indicator

struct TrainTypeIndicator: View {
    let trainType: TrainType

    var body: some View {
        Circle()
            .fill(trainType.color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: CaltrainWidgetEntry.WidgetError

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: errorIcon)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(error.rawValue)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if error == .noLocation || error == .cacheStale || error == .noData {
                Text("Open the app to update")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }

    private var errorIcon: String {
        switch error {
        case .noLocation, .cacheStale:
            return "location.slash"
        case .noStation:
            return "mappin.slash"
        case .noData:
            return "tram.slash"
        case .apiError:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Previews

#Preview("Medium - Both", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Medium - Northbound", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sampleNorthbound
}

#Preview("Large - Sample", as: .systemLarge) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Medium - No departures", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: nil,
        debugMessage: nil,
    )
}

#Preview("Medium - No Location", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .noLocation,
        debugMessage: nil,
    )
}

#Preview("Medium - No Data", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .noData,
        debugMessage: nil,
    )
}
