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

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: CaltrainWidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetHeaderView(station: entry.station)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // Departures in two columns
            HStack(spacing: 0) {
                // Northbound
                DirectionSection(
                    direction: .northbound,
                    departures: entry.northboundDepartures,
                    isCompact: true
                )

                Divider()

                // Southbound
                DirectionSection(
                    direction: .southbound,
                    departures: entry.southboundDepartures,
                    isCompact: true
                )
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: CaltrainWidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetHeaderView(station: entry.station)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // Northbound section
            DirectionSection(
                direction: .northbound,
                departures: entry.northboundDepartures,
                isCompact: false
            )
            .padding(.vertical, 8)

            Divider()

            // Southbound section
            DirectionSection(
                direction: .southbound,
                departures: entry.southboundDepartures,
                isCompact: false
            )
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Widget Header

struct WidgetHeaderView: View {
    let station: CaltrainStation?

    var body: some View {
        HStack {
            // Caltrain logo/text
            Text("CALTRAIN DEPARTURES")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.9, green: 0.1, blue: 0.1), Color(red: 0.8, green: 0.0, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            // Station name
            if let station = station {
                Text(station.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Direction Section

struct DirectionSection: View {
    let direction: Direction
    let departures: [TrainDeparture]
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Direction header
            HStack {
                Image(systemName: direction == .northbound ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(direction == .northbound ? "North (San Francisco)" : "South (San Jose)")
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
                    ForEach(departures, id: \.departureId) { departure in
                        if isCompact {
                            CompactDepartureRow(departure: departure)
                        } else {
                            ExtendedDepartureRow(departure: departure)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Compact Departure Row (for Medium widget)

struct CompactDepartureRow: View {
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

    var body: some View {
        HStack(spacing: 6) {
            // Time
            VStack(alignment: .leading, spacing: 0) {
                Text(timeString)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                if minutesUntilDeparture <= 10 {
                    Text("\(minutesUntilDeparture)m")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(minutesUntilDeparture <= 5 ? .red : .orange)
                }
            }
            .frame(width: 60, alignment: .leading)

            // Train type indicator
            TrainTypeIndicator(trainType: departure.trainType)

            // Destination (truncated)
            Text(departure.destinationName)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            // Status indicator
            if departure.status == .delayed {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
            }
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
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time and countdown
            VStack(alignment: .leading, spacing: 2) {
                Text(timeString)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                if minutesUntilDeparture <= 10 {
                    Text("\(minutesUntilDeparture) min")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(minutesUntilDeparture <= 5 ? .red : .orange)
                }
            }
            .frame(width: 55, alignment: .leading)

            // Train type indicator
            TrainTypeIndicator(trainType: departure.trainType)

            // Train details
            VStack(alignment: .leading, spacing: 2) {
                Text(departure.destinationName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("Train \(departure.trainNumber)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)

                    Text(statusText)
                        .font(.system(size: 9))
                        .foregroundStyle(departure.status == .delayed ? .red : .secondary)
                }
            }

            Spacer(minLength: 0)

            // Status icon
            if departure.status == .delayed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            } else if departure.status == .onTime {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
            }
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

            if error == .noLocation || error == .cacheStale {
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

#Preview("Medium - Sample", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Large - Sample", as: .systemLarge) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Medium - No Location", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .noLocation
    )
}
